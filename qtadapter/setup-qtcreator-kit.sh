#!/usr/bin/env bash
# Sets up the Qt Creator CM5 cross-debug kit on any developer machine.
#
# Run once per machine (Qt Creator must be closed):
#   ./setup-qtcreator-kit.sh --pi-host 192.168.1.100
#   ./setup-qtcreator-kit.sh --pi-host 192.168.1.100 --pi-user pi
#
# What it does:
#   1. Patches toolchains.xml  – adds aarch64 gcc/g++ with correct ABI
#   2. Patches qtversion.xml   – adds aarch64 Qt5 qmake (ID=2)
#   3. Patches debuggers.xml   – adds gdb-multiarch
#   4. Patches profiles.xml    – adds CM5 kit (references all of the above)
#   5. Patches devices.xml     – adds the Pi SSH device
#
# Fixed UUIDs match the project's CMakeLists.txt.user so it works
# without re-assigning the kit after cloning on a new machine.

set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  [OK]${NC}  $*"; }
info() { echo -e "${YELLOW}  [--]${NC}  $*"; }
fail() { echo -e "${RED}  [!!]${NC}  $*"; exit 1; }

# ── Arguments ─────────────────────────────────────────────────────────────────
PI_HOST=""
PI_USER="pi"
PI_PORT="22"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --pi-host) PI_HOST="$2"; shift 2 ;;
        --pi-user) PI_USER="$2"; shift 2 ;;
        --pi-port) PI_PORT="$2"; shift 2 ;;
        *) fail "Unknown argument: $1" ;;
    esac
done

if [[ -z "$PI_HOST" ]]; then
    fail "Usage: $0 --pi-host <IP> [--pi-user pi] [--pi-port 22]"
fi

# ── Fixed UUIDs (must match CMakeLists.txt.user) ──────────────────────────────
UUID_TC_CXX="{c99a723b-6280-4c9b-a65e-ef28162c5d5c}"
UUID_TC_C="{5c786072-e6df-45cd-af6f-20fd773e978b}"
UUID_DEBUGGER="{ce64d212-b899-4a54-b2d0-99a29ea48b3a}"
UUID_KIT="{708bca98-db18-4b2e-a73f-db7fb45d939d}"
UUID_DEVICE="{341d75fc-6738-4b40-94d6-2bfce570260c}"
QTVERSION_ID=2

QTCDIR="$HOME/.config/QtProject/qtcreator"

echo "=================================================="
echo " Qt Creator CM5 Kit Setup"
echo " Pi device : ${PI_USER}@${PI_HOST}:${PI_PORT}"
echo " Config dir: $QTCDIR"
echo "=================================================="
echo ""

# ── Preflight ─────────────────────────────────────────────────────────────────
[[ -d "$QTCDIR" ]] || fail "Qt Creator config dir not found: $QTCDIR  (has Qt Creator run at least once?)"
command -v python3 &>/dev/null || fail "python3 required"

for bin in /usr/bin/gdb-multiarch \
           /bin/aarch64-linux-gnu-gcc \
           /bin/aarch64-linux-gnu-g++ \
           /usr/lib/aarch64-linux-gnu/qt5/bin/qmake \
           /opt/pi-sysroot; do
    if [[ -e "$bin" ]]; then
        ok "Found $bin"
    else
        info "Missing $bin — run setup-pi-sysroot.sh first, or install ARM64 packages"
    fi
done
echo ""

# ── Backup ────────────────────────────────────────────────────────────────────
BACKUP="$QTCDIR/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
for f in toolchains.xml qtversion.xml debuggers.xml profiles.xml devices.xml; do
    [[ -f "$QTCDIR/$f" ]] && cp "$QTCDIR/$f" "$BACKUP/$f"
done
ok "Backed up existing config to $BACKUP"
echo ""

# ── Python patcher ────────────────────────────────────────────────────────────
# Reads each XML file, removes any stale CM5 entries (by our fixed UUIDs),
# then appends the correct entries.  Auto-detected entries are preserved.
python3 - \
    "$QTCDIR" \
    "$UUID_TC_CXX" "$UUID_TC_C" \
    "$UUID_DEBUGGER" \
    "$UUID_KIT" \
    "$UUID_DEVICE" \
    "$QTVERSION_ID" \
    "$PI_HOST" "$PI_USER" "$PI_PORT" \
<<'PYEOF'
import sys, re
from pathlib import Path
from xml.etree import ElementTree as ET

(qtcdir, UUID_CXX, UUID_C, UUID_DBG, UUID_KIT,
 UUID_DEV, QTVER_ID, PI_HOST, PI_USER, PI_PORT) = sys.argv[1:]
QTVER_ID = int(QTVER_ID)

# ── helpers ───────────────────────────────────────────────────────────────────
def read_xml(path):
    return Path(path).read_text(encoding="utf-8") if Path(path).exists() else None

def write_xml(path, content):
    Path(path).write_text(content, encoding="utf-8")

def count_entries(xml_str, tag):
    """Count how many Variable.N entries exist (e.g. ToolChain.0, ToolChain.1…)."""
    return len(re.findall(rf'<variable>{tag}\.\d+</variable>', xml_str))

def remove_entry_by_id(xml_str, id_value):
    """Remove a <data> block that contains the given ID string anywhere inside it."""
    pattern = re.compile(
        r'(\s*<data>(?:(?!</data>).)*?' + re.escape(id_value) + r'.*?</data>)',
        re.DOTALL)
    return pattern.sub('', xml_str)

def insert_before_count(xml_str, count_tag, new_entry, count_value):
    """Insert new_entry before the Count element and update the count."""
    old_count_block = f'<variable>{count_tag}</variable>\n  <value type="int">'
    new_count_str = (
        f'</data>\n <data>\n  <variable>{count_tag}</variable>\n'
        f'  <value type="int">{count_value}</value>\n </data>'
    )
    # Replace last </data> + count block
    xml_str = re.sub(
        rf'(\s*</data>\s*<data>\s*<variable>{count_tag}</variable>\s*<value[^>]*>\d+</value>\s*</data>)',
        new_entry + f'\n <data>\n  <variable>{count_tag}</variable>\n'
                  + f'  <value type="int">{count_value}</value>\n </data>',
        xml_str
    )
    return xml_str

# ── 1. toolchains.xml ─────────────────────────────────────────────────────────
tc_file = f"{qtcdir}/toolchains.xml"
tc_xml = read_xml(tc_file) or """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE QtCreatorToolChains>
<qtcreator>
 <data>
  <variable>ToolChain.Count</variable>
  <value type="int">0</value>
 </data>
 <data>
  <variable>Version</variable>
  <value type="int">1</value>
 </data>
</qtcreator>"""

tc_xml = remove_entry_by_id(tc_xml, UUID_CXX)
tc_xml = remove_entry_by_id(tc_xml, UUID_C)

n = count_entries(tc_xml, "ToolChain")

tc_new = f"""
 <data>
  <variable>ToolChain.{n}</variable>
  <valuemap type="QVariantMap">
   <value type="QString" key="ExplicitCodeModelTargetTriple">aarch64-linux-gnu</value>
   <value type="QString" key="ProjectExplorer.GccToolChain.OriginalTargetTriple">aarch64-linux-gnu</value>
   <value type="QString" key="ProjectExplorer.GccToolChain.Path">/bin/aarch64-linux-gnu-g++</value>
   <valuelist type="QVariantList" key="ProjectExplorer.GccToolChain.PlatformCodeGenFlags"/>
   <valuelist type="QVariantList" key="ProjectExplorer.GccToolChain.PlatformLinkerFlags"/>
   <valuelist type="QVariantList" key="ProjectExplorer.GccToolChain.SupportedAbis">
    <value type="QString">aarch64-linux-generic-elf-64bit</value>
   </valuelist>
   <value type="QString" key="ProjectExplorer.GccToolChain.TargetAbi">aarch64-linux-generic-elf-64bit</value>
   <value type="bool" key="ProjectExplorer.ToolChain.Autodetect">false</value>
   <value type="QString" key="ProjectExplorer.ToolChain.DisplayName">GCC aarch64 C++ (CM5)</value>
   <value type="QString" key="ProjectExplorer.ToolChain.Id">ProjectExplorer.ToolChain.Gcc:{UUID_CXX[1:-1]}</value>
   <value type="int" key="ProjectExplorer.ToolChain.Language">2</value>
   <value type="QString" key="ProjectExplorer.ToolChain.LanguageV2">Cxx</value>
  </valuemap>
 </data>
 <data>
  <variable>ToolChain.{n+1}</variable>
  <valuemap type="QVariantMap">
   <value type="QString" key="ExplicitCodeModelTargetTriple">aarch64-linux-gnu</value>
   <value type="QString" key="ProjectExplorer.GccToolChain.OriginalTargetTriple">aarch64-linux-gnu</value>
   <value type="QString" key="ProjectExplorer.GccToolChain.Path">/bin/aarch64-linux-gnu-gcc</value>
   <valuelist type="QVariantList" key="ProjectExplorer.GccToolChain.PlatformCodeGenFlags"/>
   <valuelist type="QVariantList" key="ProjectExplorer.GccToolChain.PlatformLinkerFlags"/>
   <valuelist type="QVariantList" key="ProjectExplorer.GccToolChain.SupportedAbis">
    <value type="QString">aarch64-linux-generic-elf-64bit</value>
   </valuelist>
   <value type="QString" key="ProjectExplorer.GccToolChain.TargetAbi">aarch64-linux-generic-elf-64bit</value>
   <value type="bool" key="ProjectExplorer.ToolChain.Autodetect">false</value>
   <value type="QString" key="ProjectExplorer.ToolChain.DisplayName">GCC aarch64 C (CM5)</value>
   <value type="QString" key="ProjectExplorer.ToolChain.Id">ProjectExplorer.ToolChain.Gcc:{UUID_C[1:-1]}</value>
   <value type="int" key="ProjectExplorer.ToolChain.Language">1</value>
   <value type="QString" key="ProjectExplorer.ToolChain.LanguageV2">C</value>
  </valuemap>
 </data>"""

tc_xml = re.sub(
    r'(\s*<data>\s*<variable>ToolChain\.Count</variable>.*?</data>)',
    tc_new + f'\n <data>\n  <variable>ToolChain.Count</variable>\n  <value type="int">{n+2}</value>\n </data>',
    tc_xml, flags=re.DOTALL)

write_xml(tc_file, tc_xml)
print(f"  [OK]  toolchains.xml  (ABI: aarch64-linux-generic-elf-64bit)")

# ── 2. qtversion.xml ──────────────────────────────────────────────────────────
qv_file = f"{qtcdir}/qtversion.xml"
qv_xml = read_xml(qv_file) or """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE QtCreatorQtVersions>
<qtcreator>
 <data>
  <variable>Version</variable>
  <value type="int">1</value>
 </data>
</qtcreator>"""

# Remove stale aarch64 entry (matched by qmake path, not UUID)
qv_xml = re.sub(
    r'\s*<data>(?:(?!</data>).)*?aarch64-linux-gnu/qt5/bin/qmake.*?</data>',
    '', qv_xml, flags=re.DOTALL)

n_qv = count_entries(qv_xml, "QtVersion")
qv_new = f"""
 <data>
  <variable>QtVersion.{n_qv}</variable>
  <valuemap type="QVariantMap">
   <value type="int" key="Id">{QTVER_ID}</value>
   <value type="QString" key="QMakePath">/usr/lib/aarch64-linux-gnu/qt5/bin/qmake</value>
   <value type="QString" key="QtVersion.Type">Qt4ProjectManager.QtVersion.Desktop</value>
   <value type="QString" key="autodetectionSource"></value>
   <value type="bool" key="isAutodetected">false</value>
  </valuemap>
 </data>"""

qv_xml = re.sub(
    r'(\s*<data>\s*<variable>Version</variable>)',
    qv_new + r'\n \1'[2:],
    qv_xml)

write_xml(qv_file, qv_xml)
print(f"  [OK]  qtversion.xml   (ID={QTVER_ID}, aarch64 qmake)")

# ── 3. debuggers.xml ──────────────────────────────────────────────────────────
dbg_file = f"{qtcdir}/debuggers.xml"
dbg_xml = read_xml(dbg_file) or """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE QtCreatorDebuggers>
<qtcreator>
 <data>
  <variable>DebuggerItem.Count</variable>
  <value type="int">0</value>
 </data>
 <data>
  <variable>Version</variable>
  <value type="int">1</value>
 </data>
</qtcreator>"""

dbg_xml = remove_entry_by_id(dbg_xml, UUID_DBG)
n_dbg = count_entries(dbg_xml, "DebuggerItem")

dbg_new = f"""
 <data>
  <variable>DebuggerItem.{n_dbg}</variable>
  <valuemap type="QVariantMap">
   <valuelist type="QVariantList" key="Abis">
    <value type="QString">aarch64-linux-generic-elf-64bit</value>
   </valuelist>
   <value type="bool" key="AutoDetected">false</value>
   <value type="QString" key="Binary">/usr/bin/gdb-multiarch</value>
   <value type="QString" key="DisplayName">gdb-multiarch (CM5)</value>
   <value type="int" key="EngineType">1</value>
   <value type="QString" key="Id">{UUID_DBG}</value>
   <value type="QString" key="WorkingDirectory"></value>
  </valuemap>
 </data>"""

dbg_xml = re.sub(
    r'(\s*<data>\s*<variable>DebuggerItem\.Count</variable>.*?</data>)',
    dbg_new + f'\n <data>\n  <variable>DebuggerItem.Count</variable>\n  <value type="int">{n_dbg+1}</value>\n </data>',
    dbg_xml, flags=re.DOTALL)

write_xml(dbg_file, dbg_xml)
print(f"  [OK]  debuggers.xml   ({UUID_DBG} → gdb-multiarch)")

# ── 4. profiles.xml (kit) ─────────────────────────────────────────────────────
prof_file = f"{qtcdir}/profiles.xml"
prof_xml = read_xml(prof_file) or """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE QtCreatorProfiles>
<qtcreator>
 <data>
  <variable>Profile.Count</variable>
  <value type="int">0</value>
 </data>
 <data>
  <variable>Version</variable>
  <value type="int">1</value>
 </data>
</qtcreator>"""

prof_xml = remove_entry_by_id(prof_xml, UUID_KIT)
n_prof = count_entries(prof_xml, "Profile")

prof_new = f"""
 <data>
  <variable>Profile.{n_prof}</variable>
  <valuemap type="QVariantMap">
   <value type="bool" key="PE.Profile.AutoDetected">false</value>
   <value type="QString" key="PE.Profile.AutoDetectionSource"></value>
   <valuemap type="QVariantMap" key="PE.Profile.Data">
    <valuelist type="QVariantList" key="CMake.ConfigurationKitInformation">
     <value type="QString">QT_QMAKE_EXECUTABLE:FILEPATH=%{{Qt:qmakeExecutable}}</value>
     <value type="QString">CMAKE_PREFIX_PATH:PATH=%{{Qt:QT_INSTALL_PREFIX}}</value>
     <value type="QString">CMAKE_C_COMPILER:FILEPATH=%{{Compiler:Executable:C}}</value>
     <value type="QString">CMAKE_CXX_COMPILER:FILEPATH=%{{Compiler:Executable:Cxx}}</value>
     <value type="QString">CMAKE_TOOLCHAIN_FILE:FILEPATH=/home/pi/Project/qtdemo/qtadapter/pi_toolchain.cmake</value>
    </valuelist>
    <valuemap type="QVariantMap" key="CMake.GeneratorKitInformation">
     <value type="QString" key="Generator">Ninja</value>
    </valuemap>
    <value type="QString" key="Debugger.Information">{UUID_DBG}</value>
    <value type="QByteArray" key="PE.Profile.BuildDeviceType">Desktop</value>
    <value type="QString" key="PE.Profile.DeviceType">GenericLinuxOsType</value>
    <value type="QString" key="PE.Profile.Device">{UUID_DEV}</value>
    <value type="QString" key="PE.Profile.SysRoot">/opt/pi-sysroot</value>
    <valuemap type="QVariantMap" key="PE.Profile.ToolChainsV3">
     <value type="QByteArray" key="C">{UUID_C}</value>
     <value type="QByteArray" key="Cxx">{UUID_CXX}</value>
    </valuemap>
    <value type="int" key="QtSupport.QtInformation">{QTVER_ID}</value>
   </valuemap>
   <value type="QString" key="PE.Profile.Id">{UUID_KIT}</value>
   <value type="QString" key="PE.Profile.Name">CM5</value>
   <value type="bool" key="PE.Profile.SDK">false</value>
  </valuemap>
 </data>"""

prof_xml = re.sub(
    r'(\s*<data>\s*<variable>Profile\.Count</variable>.*?</data>)',
    prof_new + f'\n <data>\n  <variable>Profile.Count</variable>\n  <value type="int">{n_prof+1}</value>\n </data>',
    prof_xml, flags=re.DOTALL)

write_xml(prof_file, prof_xml)
print(f"  [OK]  profiles.xml    ({UUID_KIT} → CM5 kit)")

# ── 5. devices.xml ────────────────────────────────────────────────────────────
dev_file = f"{qtcdir}/devices.xml"
dev_xml = read_xml(dev_file)

PI_DEVICE_ENTRY = f"""    <valuemap type="QVariantMap">
     <value type="int" key="Authentication">0</value>
     <value type="QString" key="ClientOsType">Linux</value>
     <valuemap type="QVariantMap" key="ExtraData">
      <value type="bool" key="RemoteLinux.SupportsRSync">true</value>
      <value type="bool" key="RemoteLinux.SupportsSftp">true</value>
     </valuemap>
     <value type="QString" key="FreePortsSpec">10000-10100</value>
     <value type="QString" key="Host">{PI_HOST}</value>
     <value type="int" key="HostKeyChecking">2</value>
     <value type="QString" key="InternalId">{UUID_DEV}</value>
     <value type="QString" key="KeyFile"></value>
     <value type="QString" key="Name">cm5</value>
     <value type="int" key="Origin">0</value>
     <value type="QString" key="OsType">GenericLinuxOsType</value>
     <value type="int" key="SshPort">{PI_PORT}</value>
     <value type="int" key="Timeout">10</value>
     <value type="int" key="Type">0</value>
     <value type="QString" key="Uname">{PI_USER}</value>
     <value type="int" key="Version">0</value>
    </valuemap>"""

if dev_xml and UUID_DEV in dev_xml:
    # Replace the existing device entry
    dev_xml = re.sub(
        r'\s*<valuemap type="QVariantMap">(?:(?!</valuemap>).)*?' + re.escape(UUID_DEV) + r'.*?</valuemap>',
        '\n    ' + PI_DEVICE_ENTRY.strip(),
        dev_xml, flags=re.DOTALL)
    write_xml(dev_file, dev_xml)
    print(f"  [OK]  devices.xml     (updated {PI_HOST})")
elif dev_xml:
    # Append to DeviceList
    dev_xml = dev_xml.replace('</valuelist>', PI_DEVICE_ENTRY + '\n   </valuelist>', 1)
    # Also set default GenericLinux device
    if 'GenericLinuxOsType' not in dev_xml:
        dev_xml = dev_xml.replace(
            '<valuemap type="QVariantMap" key="DefaultDevices">',
            f'<valuemap type="QVariantMap" key="DefaultDevices">\n    <value type="QString" key="GenericLinuxOsType">{UUID_DEV}</value>')
    write_xml(dev_file, dev_xml)
    print(f"  [OK]  devices.xml     (added {PI_HOST})")
else:
    write_xml(dev_file, f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE QtCreatorDevices>
<qtcreator>
 <data>
  <variable>DeviceManager</variable>
  <valuemap type="QVariantMap">
   <valuemap type="QVariantMap" key="DefaultDevices">
    <value type="QString" key="Desktop">Desktop Device</value>
    <value type="QString" key="GenericLinuxOsType">{UUID_DEV}</value>
   </valuemap>
   <valuelist type="QVariantList" key="DeviceList">
    <valuemap type="QVariantMap">
     <value type="QString" key="InternalId">Desktop Device</value>
     <value type="QString" key="OsType">Desktop</value>
    </valuemap>
{PI_DEVICE_ENTRY}
   </valuelist>
  </valuemap>
 </data>
</qtcreator>""")
    print(f"  [OK]  devices.xml     (created with {PI_HOST})")

print()
print("  Done. Start Qt Creator — the CM5 kit will be available immediately.")
PYEOF

echo ""
echo "=================================================="
echo " Setup complete"
echo "=================================================="
echo ""
echo " Next steps:"
echo "  1. Start Qt Creator (closed during this script)"
echo "  2. Edit → Preferences → Kits — verify CM5 kit is green"
echo "     If yellow: Preferences → Qt Versions → verify"
echo "     '/usr/lib/aarch64-linux-gnu/qt5/bin/qmake' is listed"
echo "  3. Open the project, press Ctrl+5"
echo "     confirm CM5 is active under Build & Run"
echo ""
echo " To debug:"
echo "  ./deploy-and-debug.sh ${PI_HOST}"
echo "  Qt Creator → Debug → Start Debugging → Attach to Running Debug Server"
echo "    Kit:              CM5"
echo "    Local executable: build_pi/Qt5DecoupledDemo"
echo "    Server:           ${PI_HOST}:2345"
echo ""
