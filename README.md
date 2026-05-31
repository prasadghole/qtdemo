# Multiplatform GUI Demo

A C++ sensor simulation demonstrating clean architecture with interchangeable GUI front-ends. The domain and infrastructure layers are shared; the GUI adapter (Qt5 or wxWidgets) is selected at build time.

```
qtdemos/
├── core/          # Shared domain + infrastructure (header-only, no GUI dependency)
├── adapters/qt/   # Qt5 adapter  → SensorDemoQt
├── adapters/wx/   # wxWidgets adapter → SensorDemoWx
├── cmake/         # Toolchain files (Pi ARM64, MinGW Windows)
└── .docker/       # Dockerfiles for each target
```

---

## Quick Start

```bash
make native-qt     # build Qt5 adapter for Linux
make native-wx     # build wxWidgets adapter for Linux
make help          # list all targets
```

CMake runs automatically on first build. Subsequent `make` calls skip cmake and go straight to ninja.

---

## Prerequisites by Target

### native-qt — Linux x86_64, Qt5

```bash
sudo apt install -y \
    build-essential cmake ninja-build \
    qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools
```

```bash
make native-qt
./build_native_qt/adapters/qt/SensorDemoQt
```

---

### native-wx — Linux x86_64, wxWidgets

```bash
sudo apt install -y \
    build-essential cmake ninja-build \
    libwxgtk3.2-dev wx-common
```

> On older Ubuntu/Debian that only ships wxWidgets 3.0:
> ```bash
> sudo apt install -y libwxgtk3.0-gtk3-dev wx-common
> ```

```bash
make native-wx
./build_native_wx/adapters/wx/SensorDemoWx
```

---

### pi-qt — Raspberry Pi ARM64, Qt5 (cross-compile from Linux x86_64)

#### Install cross-compiler and ARM64 Qt5 packages

```bash
# ARM64 cross-compiler
sudo apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
    cmake ninja-build

# Enable ARM64 architecture and install Qt5 for ARM64
sudo dpkg --add-architecture arm64

# Add ARM64 package sources (Ubuntu Noble / 24.04)
sudo tee /etc/apt/sources.list.d/arm64.sources > /dev/null <<'EOF'
Types: deb
URIs: http://ports.ubuntu.com/ubuntu-ports/
Suites: noble noble-updates noble-backports noble-security
Components: main universe restricted multiverse
Architectures: arm64
EOF

sudo apt update
sudo apt install -y qtbase5-dev:arm64
```

```bash
make pi-qt
file build_pi_qt/adapters/qt/SensorDemoQt
# → ELF 64-bit LSB executable, ARM aarch64
```

Deploy and run on the Pi:

```bash
scp build_pi_qt/adapters/qt/SensorDemoQt pi@192.168.1.100:~/
ssh pi@192.168.1.100 DISPLAY=:0 ./SensorDemoQt
```

---

### pi-wx — Raspberry Pi ARM64, wxWidgets (cross-compile from Linux x86_64)

wxWidgets must be cross-compiled for ARM64 — no pre-built package is available for the cross-compile host.

#### 1. Install cross-compiler and GTK3 ARM64 headers

```bash
sudo apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
    cmake ninja-build curl

# Enable ARM64 architecture (if not already done for pi-qt above)
sudo dpkg --add-architecture arm64
sudo apt update

# GTK3 and X11 ARM64 libraries for wxWidgets configure
sudo apt install -y \
    libgtk-3-dev:arm64 \
    libx11-dev:arm64 \
    libxinerama-dev:arm64 \
    libxrandr-dev:arm64 \
    libxcursor-dev:arm64
```

#### 2. Build wxWidgets 3.2 for ARM64

```bash
curl -L -o /tmp/wx.tar.bz2 \
    https://github.com/wxWidgets/wxWidgets/releases/download/v3.2.5/wxWidgets-3.2.5.tar.bz2
tar -xjf /tmp/wx.tar.bz2 -C /tmp
cd /tmp/wxWidgets-3.2.5
mkdir build-arm64 && cd build-arm64
../configure \
    --host=aarch64-linux-gnu \
    --prefix=/opt/wx-arm64 \
    --with-gtk=3 \
    --enable-unicode \
    --disable-shared
make -j$(nproc)
sudo make install
```

#### 3. Build

```bash
wxWidgets_ROOT_DIR=/opt/wx-arm64 make pi-wx
file build_pi_wx/adapters/wx/SensorDemoWx
# → ELF 64-bit LSB executable, ARM aarch64
```

Deploy:

```bash
# Copy the wx shared libs (or use --disable-shared above for a static build)
scp build_pi_wx/adapters/wx/SensorDemoWx pi@192.168.1.100:~/
ssh pi@192.168.1.100 DISPLAY=:0 ./SensorDemoWx
```

---

### windows-wx — Windows x86_64, wxWidgets (cross-compile via MinGW from Linux)

#### 1. Install MinGW cross-compiler

```bash
sudo apt install -y mingw-w64 mingw-w64-tools cmake ninja-build wget
```

#### 2. Build wxWidgets for Windows (MinGW, static)

```bash
wget -O /tmp/wx.tar.bz2 \
    https://github.com/wxWidgets/wxWidgets/releases/download/v3.2.5/wxWidgets-3.2.5.tar.bz2
tar -xjf /tmp/wx.tar.bz2 -C /tmp
cd /tmp/wxWidgets-3.2.5
mkdir build-mingw && cd build-mingw
../configure \
    --host=x86_64-w64-mingw32 \
    --prefix=/opt/wx-mingw \
    --with-msw \
    --disable-shared \
    --enable-monolithic
make -j$(nproc)
sudo make install
```

#### 3. Build

```bash
wxWidgets_ROOT_DIR=/opt/wx-mingw make windows-wx
file build_windows_wx/adapters/wx/SensorDemoWx.exe
# → PE32+ executable (GUI) x86-64, for MS Windows
```

The binary is fully static (no MinGW DLLs needed) and runs directly on Windows.

---

## Docker Builds

Docker images contain all toolchains and pre-built wxWidgets — no local setup needed.

```bash
make docker-native-qt    # Linux Qt5    (uses Dockerfile.native-qt)
make docker-native-wx    # Linux wx     (uses Dockerfile.native-wx)
make docker-pi-qt        # Pi ARM64 Qt5 (uses Dockerfile.pi-qt)
make docker-pi-wx        # Pi ARM64 wx  (uses Dockerfile.pi-wx)
make docker-windows-wx   # Windows wx   (uses Dockerfile.mingw-wx)
```

Build output lands in the corresponding `build_*/` directory on the host via a volume mount.

---

## All Make Targets

| Target | Adapter | Platform | Build type |
|---|---|---|---|
| `native-qt` | Qt5 | Linux x86_64 | Debug |
| `native-wx` | wxWidgets | Linux x86_64 | Release |
| `pi-qt` | Qt5 | Pi ARM64 (cross) | Debug |
| `pi-wx` | wxWidgets | Pi ARM64 (cross) | Debug |
| `windows-wx` | wxWidgets | Windows x64 (MinGW) | Release |
| `all` | both native | Linux x86_64 | — |
| `reconfigure-<target>` | — | — | force cmake re-run |
| `test-native-qt` | Qt5 | Linux | Robot Framework |
| `test-native-wx` | wxWidgets | Linux | Robot Framework |
| `docker-<target>` | — | — | build in container |
| `clean` | — | — | remove build dirs |

### Reconfigure without full clean

If you change the toolchain or switch `GUI_ADAPTER`:

```bash
make reconfigure-native-wx   # re-runs cmake, then rebuilds
```

---

## Architecture

```
core/include/
  domain/
    interfaces/   IEventBus.h, IWorker.h      ← pure virtual, no GUI deps
    models/       SensorData.h
    services/     DataProcessingService.h     ← subscribes/publishes via event bus
    workers/      SensorWorker.h              ← generates sine-wave sensor data
  infrastructure/
    EventBus.h                               ← thread-safe pub/sub
    WorkerThread.h                           ← std::thread wrapper template

adapters/qt/src/
  QtEventBusAdapter.h   ← bridges EventBus → Qt signals (QTimer::singleShot)
  QtWorkerAdapter.h     ← wraps IWorker as Qt slots/signals
  ui/MainWindow.h/.cpp  ← Qt5 UI

adapters/wx/src/
  WxEventBusAdapter.h/.cpp  ← bridges EventBus → UI (wxTheApp->CallAfter)
  WxApp.h/.cpp              ← wxApp composition root
  ui/MainWindow.h/.cpp      ← wxWidgets UI
```

The domain layer has zero Qt or wxWidgets headers — it can be unit-tested with a mock `IEventBus`.
