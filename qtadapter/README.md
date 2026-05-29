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
    gdb-multiarch
```

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

## Remote Debugging on CM5 with Qt Creator

Cross-debug workflow: GDB runs on the host, `gdbserver` runs on the CM5, Qt Creator connects the two.

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

### 3. Configure Qt Creator — Debugger

`Tools → Kits → Debuggers → Add`

| Field | Value |
|-------|-------|
| Name | `aarch64-gdb` |
| Path | `/usr/bin/aarch64-linux-gnu-gdb` |

### 4. Configure Qt Creator — Device

`Tools → Devices → Add → Generic Linux Device`

| Field | Value |
|-------|-------|
| Host | `<CM5_IP>` |
| SSH port | `22` |
| Username | `pi` |

### 5. Configure Qt Creator — Kit

`Tools → Kits → Add`

| Field | Value |
|-------|-------|
| Name | `Pi CM5 (ARM64)` |
| Device type | Generic Linux Device |
| Device | the device added above |
| Sysroot | `/usr/lib/aarch64-linux-gnu` |
| Compiler C | `aarch64-linux-gnu-gcc` |
| Compiler C++ | `aarch64-linux-gnu-g++` |
| Debugger | `aarch64-gdb` |
| CMake generator | Ninja |

### 6. Attach Qt Creator to gdbserver

`Debug → Start Debugging → Attach to Running Debug Server`

| Field | Value |
|-------|-------|
| Kit | `Pi CM5 (ARM64)` |
| Local executable | `build_pi/Qt5DecoupledDemo` |
| Server | `<CM5_IP>:2345` |

Qt Creator connects GDB on the host to gdbserver on the CM5. Breakpoints, stepping, and variable inspection all work over the network. The local binary is used only for symbol resolution — execution happens entirely on the CM5.

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
