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

## Prerequisites (WSL Ubuntu)

Run the provided build script — it will install everything automatically:

```bash
chmod +x build.sh
./build.sh
```

Or install manually:

```bash
sudo apt-get update
sudo apt-get install -y cmake make g++ qtbase5-dev qtbase5-dev-tools
```

## Build

```bash
./build.sh
```

Or manually:

```bash
mkdir -p build
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build --parallel
```

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
