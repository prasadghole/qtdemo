#!/usr/bin/env bash
# Sets up a GDB sysroot for remote debugging a Raspberry Pi CM5 (aarch64)
# from a WSL/Ubuntu x86_64 host that has Qt5 ARM64 multiarch packages installed.
#
# Run once:  sudo ./setup-pi-sysroot.sh
# After running, set Kit Sysroot in Qt Creator to: /opt/pi-sysroot

set -euo pipefail

SYSROOT=/opt/pi-sysroot
MULTIARCH=/usr/lib/aarch64-linux-gnu

# ── Colour helpers ────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  [OK]${NC}  $*"; }
warn() { echo -e "${YELLOW}  [!!]${NC}  $*"; }
fail() { echo -e "${RED}  [FAIL]${NC}  $*"; }

echo "=================================================="
echo " Pi CM5 GDB Sysroot Setup"
echo " Sysroot : $SYSROOT"
echo " Source  : $MULTIARCH"
echo "=================================================="
echo

# ── 1. Check prerequisites ────────────────────────────────────────────────────
echo "--- Checking prerequisites ---"

MISSING_PKGS=()

check_pkg() {
    if dpkg -l "$1" &>/dev/null; then
        ok "Package $1 is installed"
    else
        warn "Package $1 is NOT installed"
        MISSING_PKGS+=("$1")
    fi
}

check_file() {
    if [ -e "$1" ]; then
        ok "Found $1"
    else
        fail "Missing $1"
        return 1
    fi
}

check_pkg "gcc-aarch64-linux-gnu"
check_pkg "g++-aarch64-linux-gnu"
check_pkg "gdb-multiarch"
check_pkg "qtbase5-dev:arm64"
check_pkg "libqt5widgets5t64:arm64"

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo
    warn "Missing packages detected. Install them with:"
    echo "  sudo apt-get install -y ${MISSING_PKGS[*]}"
    echo
    read -rp "Install missing packages now? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        sudo apt-get install -y "${MISSING_PKGS[@]}"
    else
        echo "Continuing — some verify checks may fail."
    fi
fi
echo

# ── 2. Create sysroot directory structure ─────────────────────────────────────
echo "--- Creating sysroot structure at $SYSROOT ---"

mkdir -p "$SYSROOT/lib"
mkdir -p "$SYSROOT/usr"

ok "Created $SYSROOT/lib"
ok "Created $SYSROOT/usr"
echo

# ── 3. Create symlinks ────────────────────────────────────────────────────────
echo "--- Creating symlinks ---"

make_link() {
    local target=$1 link=$2
    if [ -L "$link" ]; then
        rm "$link"
    fi
    if [ -e "$target" ]; then
        ln -sf "$target" "$link"
        ok "$link -> $target"
    else
        fail "Cannot link $link: source $target does not exist"
    fi
}

# Pi loads libs from /lib/aarch64-linux-gnu/ — map to our multiarch dir
make_link "$MULTIARCH"                              "$SYSROOT/lib/aarch64-linux-gnu"

# Pi dynamic linker lives at /lib/ld-linux-aarch64.so.1
make_link "$MULTIARCH/ld-linux-aarch64.so.1"       "$SYSROOT/lib/ld-linux-aarch64.so.1"

# Pi also has /usr/lib/aarch64-linux-gnu/ — map that too
make_link "$MULTIARCH"                              "$SYSROOT/usr/lib"
echo

# ── 4. Verify critical files are reachable ────────────────────────────────────
echo "--- Verifying critical files ---"

ERRORS=0

verify() {
    if [ -e "$1" ]; then
        ok "$1"
    else
        fail "$1  (NOT FOUND)"
        ERRORS=$((ERRORS + 1))
    fi
}

verify "$SYSROOT/lib/ld-linux-aarch64.so.1"
verify "$SYSROOT/lib/aarch64-linux-gnu/libQt5Core.so.5"
verify "$SYSROOT/lib/aarch64-linux-gnu/libQt5Widgets.so.5"
verify "$SYSROOT/lib/aarch64-linux-gnu/libQt5Gui.so.5"
verify "$SYSROOT/lib/aarch64-linux-gnu/libstdc++.so.6"
verify "$SYSROOT/lib/aarch64-linux-gnu/libpthread.so.0"
echo

# ── 5. Print sysroot tree ─────────────────────────────────────────────────────
echo "--- Sysroot layout ---"
find "$SYSROOT" -maxdepth 3 | sed 's|[^/]*/|  |g'
echo

# ── 6. Summary ────────────────────────────────────────────────────────────────
if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}=================================================="
    echo " Sysroot ready: $SYSROOT"
    echo -e "==================================================${NC}"
else
    echo -e "${RED}=================================================="
    echo " Completed with $ERRORS missing file(s)."
    echo " Install the ARM64 Qt5 multiarch packages and re-run."
    echo -e "==================================================${NC}"
fi

echo
echo "--- Qt Creator configuration ---"
echo
echo "  1. Edit → Preferences → Kits → [Pi CM5 kit]"
echo "     Sysroot:  $SYSROOT"
echo
echo "  2. Edit → Preferences → Debugger → GDB"
echo "     Additional Startup Commands:"
echo "       set solib-search-path $MULTIARCH"
echo
echo "  3. Debugger binary:"
echo "     $(which gdb-multiarch 2>/dev/null || echo '/usr/bin/gdb-multiarch  (install gdb-multiarch)')"
echo
