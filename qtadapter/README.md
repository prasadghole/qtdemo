# Qt5 Decoupled Architecture Demo

A working Qt5 demo that demonstrates the layered architecture where
domain logic is fully decoupled from Qt signals/slots and QObject.

## Architecture

```
Qt UI layer          MainWindow.h/.cpp
                         |  Qt signals/slots only cross here
Qt adapter layer     QtEventBusAdapter.h   (only QObject in the system)
                     QtWorkerAdapter.h
                         |  Pure C++ interfaces below this line
Domain layer         SensorWorker.h        (no Qt at all)
                     DataProcessingService.h
                     IEventBus.h / IWorker.h
                         |  Concrete implementations injected via DI
Infrastructure       EventBus.h            (std::mutex, std::thread)
                     WorkerThread.h
```

## Prerequisites

### Host (WSL Ubuntu)

```bash
sudo apt-get update
sudo apt-get install -y cmake ninja-build build-essential \
    gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
    qtbase5-dev qtbase5-dev-tools \
    qtbase5-dev:arm64 libqt5widgets5t64:arm64 \
    gdb-multiarch
```

The `:arm64` packages are the multiarch ARM64 Qt5 libraries — needed for GDB
symbol resolution during remote debugging (the host never runs them).

### Raspberry Pi CM5 (target)

```bash
sudo apt install gdbserver
```

## Build

All build targets are driven by `make`. Ninja is used as the CMake generator.

| Target | Description |
|--------|-------------|
| `make native` | Build for WSL x86_64 (output: `build_native/`) |
| `make pi` | Cross-compile for CM5 ARM64, Debug symbols included (output: `build_pi/`) |
| `make clean` | Remove all build directories |
| `make docker-image` | Build the Docker cross-compiler image |
| `make docker-build-native` | Native build inside Docker |
| `make docker-build-pi` | Pi cross-compile inside Docker |

### Native (WSL)

```bash
make native
```

### Cross-compile for Raspberry Pi CM5

```bash
make pi
```

The Pi build is always configured as `Debug` so DWARF symbols are present for remote debugging.

### Docker builds

```bash
make docker-image          # one-time image build
make docker-build-pi       # cross-compile inside container
make docker-build-native   # native build inside container
```

## Remote Debugging on CM5

Cross-debug workflow: GDB runs on the host, `gdbserver` runs on the CM5, your debugger connects the two.

### 1. Deploy the binary

After `make pi`, copy the binary to the CM5 (keep debug symbols — do not strip):

```bash
scp build_pi/Qt5DecoupledDemo pi@<CM5_IP>:/home/pi/
```

### 2. Start gdbserver on CM5

SSH into the CM5 and run:

```bash
gdbserver :2345 /home/pi/Qt5DecoupledDemo
```

The process waits for the debugger to connect before starting.

---

## Remote Debugging with Qt Creator

Qt Creator's remote debug pipeline for a Generic Linux Device works in three phases:

```
Build  →  cmake --build build_pi --target all
Deploy →  cmake --build build_pi --target install  (stages to /tmp, rsync to Pi)
Debug  →  gdb-multiarch on host  ←TCP 2345→  gdbserver on Pi
```

Everything below is a one-time setup. After it is done, pressing the debug button
handles all three phases automatically.

### Step 1 — Install ARM64 multiarch packages (host)

These provide the aarch64 Qt5 libraries GDB reads for symbol resolution:

```bash
sudo apt-get install -y \
    gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
    qtbase5-dev:arm64 libqt5widgets5t64:arm64 \
    gdb-multiarch
```

### Step 2 — Create the GDB sysroot (host, run once)

GDB prepends the sysroot to every library path reported by the Pi. The script
builds a directory at `/opt/pi-sysroot` that mirrors the Pi's filesystem layout
using symlinks into the multiarch packages installed above:

```bash
sudo ./setup-pi-sysroot.sh
```

Expected output confirms these paths are reachable through the sysroot:

```
/opt/pi-sysroot/lib/ld-linux-aarch64.so.1          ← dynamic linker (fixes timeout)
/opt/pi-sysroot/lib/aarch64-linux-gnu/libQt5Core.so.5
/opt/pi-sysroot/lib/aarch64-linux-gnu/libQt5Widgets.so.5
```

Without this step Qt Creator times out on connect with:
> *Unable to find dynamic linker breakpoint function*

### Step 3 — Register the aarch64 Qt version

Qt Creator ships on Qt6 internally but targets whatever Qt version you register.
You need a separate entry for the ARM64 Qt5 qmake — different from the default
x86_64 one.

`Edit → Preferences → Qt Versions → Add`

| Field | Value |
|-------|-------|
| qmake path | `/usr/lib/aarch64-linux-gnu/qt5/bin/qmake` |

Qt Creator detects it as **Qt 5.15.13 (aarch64)** automatically.

### Step 4 — Register the cross-compilers

`Edit → Preferences → Kits → Compilers → Add → GCC → C++`

| Field | Value |
|-------|-------|
| Name | `aarch64-g++` |
| Compiler path | `/usr/bin/aarch64-linux-gnu-g++` |
| ABI | `aarch64-linux-generic-elf-64bit` |

Repeat for C (`Add → GCC → C`), pointing to `/usr/bin/aarch64-linux-gnu-gcc`.

### Step 5 — Register the debugger

`Edit → Preferences → Kits → Debuggers → Add`

| Field | Value |
|-------|-------|
| Name | `gdb-multiarch` |
| Path | `/usr/bin/gdb-multiarch` |

> Use `gdb-multiarch`, not `aarch64-linux-gnu-gdb`. The multiarch build
> handles all architectures and is what Ubuntu ships.

### Step 6 — Register the Pi as a device

`Edit → Preferences → Devices → Add → Generic Linux Device`

| Field | Value |
|-------|-------|
| Name | `Pi CM5` |
| Host | `<CM5_IP>` |
| SSH port | `22` |
| Username | `pi` |
| Authentication | Password or SSH key |

Click **Test** to verify SSH connectivity before continuing.

### Step 7 — Create the Pi CM5 kit

`Edit → Preferences → Kits → Add`

| Field | Value |
|-------|-------|
| Name | `Pi CM5 (ARM64 Qt5)` |
| Device type | Generic Linux Device |
| Device | `Pi CM5` |
| Sysroot | `/opt/pi-sysroot` |
| Compiler C | `aarch64-gcc` |
| Compiler C++ | `aarch64-g++` |
| Debugger | `gdb-multiarch` |
| Qt version | `Qt 5.15.13 (aarch64)` |
| CMake generator | Ninja |
| CMake configuration — add | `CMAKE_TOOLCHAIN_FILE=/home/pg/qtdemos/qtadapter/pi_toolchain.cmake` |

The kit shows a yellow warning until all fields are filled. It turns green once
compiler ABI matches the Qt version ABI (both aarch64).

> **Common error:** *"compiler aarch64 cannot produce code for Qt 5.15.13"*
> This means the Qt version field is still pointing at the x86_64 qmake entry.
> Change it to the aarch64 entry registered in Step 3.

### Step 8 — Activate the kit for this project

Creating a kit globally does not automatically apply it to open projects.

1. Press `Ctrl+5` (Projects mode) or click the wrench icon in the left sidebar
2. Under **Build & Run**, click **Add Kit** and select `Pi CM5 (ARM64 Qt5)`
3. Wait for CMake configure to complete — check the Issues panel for errors

### Step 9 — Configure GDB startup commands

`Edit → Preferences → Debugger → GDB → Additional Startup Commands`

Add:
```
set solib-search-path /usr/lib/aarch64-linux-gnu
```

This is a fallback: if any library path does not resolve through the sysroot,
GDB searches this directory directly.

### Step 10 — Debug session workflow

Every debug session follows this sequence:

**On the Pi** (once per session):
```bash
gdbserver :2345 /home/pi/Qt5DecoupledDemo
# prints: Listening on port 2345
```

**In Qt Creator:**
```
Debug → Start Debugging → Attach to Running Debug Server
```

| Field | Value |
|-------|-------|
| Kit | `Pi CM5 (ARM64 Qt5)` |
| Local executable | `build_pi/Qt5DecoupledDemo` |
| Server | `<CM5_IP>:2345` |

Qt Creator connects `gdb-multiarch` on the host to `gdbserver` on the Pi.
The binary executes entirely on the Pi; the local copy is used only for
DWARF symbol resolution. Breakpoints, stepping, and variable inspection
all work over the network.

### Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Kit not shown in debug dialog | Kit not activated for project | `Ctrl+5` → Add Kit |
| Kit shows error (yellow/red) | ABI mismatch or missing debugger | Check Qt version is aarch64, debugger is set |
| Qt Creator times out on connect | GDB sysroot missing dynamic linker | Re-run `setup-pi-sysroot.sh`, set Kit Sysroot to `/opt/pi-sysroot` |
| "Could not load shared library symbols" | Wrong or missing sysroot | Verify `/opt/pi-sysroot/lib/aarch64-linux-gnu/` contains Qt5 libs |
| gdbserver exits immediately | Binary not deployed to Pi | `scp build_pi/Qt5DecoupledDemo pi@<IP>:/home/pi/` |

---

### Remote Debugging with VSCode

**Setup:**
1. Replace `<REMOTE_IP>` in `.vscode/launch.json` with your target device IP
2. On the remote device, start gdbserver (see step 2 above)
3. In VSCode, select the **"Debug Remote Pi (ARM64 via gdbserver)"** configuration
4. Press **F5** to start debugging

**How it works:**
- VSCode uses `aarch64-linux-gnu-gdb` (cross-debugger) on the host
- The `target remote` command in setupCommands connects to gdbserver on CM5
- Source maps help navigate between WSL and remote paths
- All breakpoints, stepping, and inspection work the same as local debugging

## Run

### Windows 11 (WSLg — recommended, zero config)
WSLg ships a built-in X server. Just run:
```bash
./build/Qt5DecoupledDemo
```

### Windows 10 with VcXsrv
1. Install VcXsrv from https://sourceforge.net/projects/vcxsrv/
2. Launch XLaunch: Multiple Windows → Start no client → check "Disable access control"
3. In WSL:
```bash
export DISPLAY=:0
./build/Qt5DecoupledDemo
```

### Windows 10 with X410 (Microsoft Store)
```bash
export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0
./build/Qt5DecoupledDemo
```

## What the demo shows

- Press **Start worker** → a `std::thread` starts running `SensorWorker::run()`
- The worker publishes `sensor.data` events onto the pure-C++ `EventBus` at 10 Hz
- `DataProcessingService` (also pure C++) subscribes, classifies the value, publishes `sensor.processed`
- `QtEventBusAdapter` picks up the processed event and safely re-dispatches to the Qt UI thread using `QTimer::singleShot(0, ...)` — the Qt5-compatible cross-thread lambda dispatch
- `MainWindow` updates the gauge, progress bar, alarm state, and log
- Values oscillate as a sine wave; values >80 or <20 trigger ALARM state

## Key files

| File | Layer | Purpose |
|------|-------|---------|
| `src/domain/interfaces/IEventBus.h` | Domain | Pure virtual event bus interface |
| `src/domain/interfaces/IWorker.h` | Domain | Pure virtual worker interface |
| `src/domain/workers/SensorWorker.h` | Domain | Produces sine-wave sensor data |
| `src/domain/services/DataProcessingService.h` | Domain | Classifies values, detects alarms |
| `src/infrastructure/EventBus.h` | Infrastructure | Thread-safe C++ event bus |
| `src/infrastructure/WorkerThread.h` | Infrastructure | `std::thread` wrapper for any worker |
| `src/qt_adapter/QtEventBusAdapter.h` | Qt adapter | **Only QObject** — bridges C++ bus to Qt signals |
| `src/qt_adapter/QtWorkerAdapter.h` | Qt adapter | Exposes worker lifecycle as Qt slots |
| `src/qt_adapter/ui/MainWindow.h/.cpp` | Qt UI | Connects to adapter signals only |
| `src/main.cpp` | Composition root | Wires all layers via dependency injection |
