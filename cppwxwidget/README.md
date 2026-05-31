# wxWidgets Cross-Platform Desktop Application

A decoupled architecture demonstration using **wxWidgets** for cross-platform GUI development. Supports Linux, Windows, and Raspberry Pi builds.

## Architecture

```
┌─────────────────────────────────────────┐
│  wxWidgets UI Layer (MainWindow)        │  ← Native wxWidgets widgets
├─────────────────────────────────────────┤
│  wxWidgets Adapter Layer                │  ← Only wxWidgets-specific code
│  (WxEventBusAdapter, WxApp)             │  ← Bridges C++ bus ↔ UI
├─────────────────────────────────────────┤
│  Domain Layer (Business Logic)          │  ← Zero wxWidgets dependencies
│  (SensorWorker, DataProcessingService)  │  ← Pure C++, fully testable
├─────────────────────────────────────────┤
│  Infrastructure (Concrete Impl)         │  ← std::thread, std::mutex
│  (EventBus, WorkerThread)               │  ← Zero wxWidgets dependencies
└─────────────────────────────────────────┘
```

## Features

- **Sensor value display** with large bold font and progress bar (0-100)
- **Category indicator** (HIGH/NORMAL/LOW) with color-coded alarm status
- **Worker start/stop controls** with button state management
- **Event log** (last 50 entries, auto-scrolling)
- **Cross-platform GUI** using wxWidgets (Linux GTK3, Windows native, Mac Cocoa)
- **Thread-safe event bus** for domain-UI communication
- **Multi-target build support**: Linux x86_64, Windows (MinGW), Raspberry Pi ARM64

## Building

### Prerequisites (Linux)

```bash
# Install wxWidgets development files
sudo apt-get install libwxgtk3.2-dev wx-common

# Install build tools
sudo apt-get install build-essential cmake ninja-build

# For Windows cross-compilation
sudo apt-get install mingw-w64 mingw-w64-tools

# For Raspberry Pi cross-compilation
sudo apt-get install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
```

### Quick Start

```bash
cd cppwxwidget

# Build for current platform (Linux x86_64)
make native
./build_native/WxWidgetDemo

# Or use automated dependency installation
make install-deps
make native
```

### Build Targets

```bash
# Local compilation
make native                    # Linux x86_64
make windows                   # Windows (MinGW cross-compile)
make pi                        # Raspberry Pi ARM64 (cross-compile)

# Docker builds (no local dependencies needed)
make docker-image              # Build all Docker images
make docker-build-native       # Docker: Linux x86_64
make docker-build-windows      # Docker: Windows
make docker-build-pi           # Docker: Raspberry Pi

# Cleanup
make clean                     # Remove all build directories
```

## Platform-Specific Notes

### Linux (x86_64)
- Uses GTK3 backend via wxWidgets
- Native look and feel on GNOME/KDE/other desktop environments
- Full feature support

### Windows (MinGW)
- Cross-compiled from Linux using MinGW-w64 toolchain
- Native Win32 backend via wxWidgets
- Runs on Windows 7/10/11

### Raspberry Pi (ARM64)
- Cross-compiled using aarch64-linux-gnu toolchain
- Runs on Raspberry Pi CM5 or Pi 4/5 with 64-bit OS
- GTK3 backend for lightweight desktop display
- Optimized for ARM Cortex-A72 CPU

## File Structure

```
cppwxwidget/
├── CMakeLists.txt                          # CMake build configuration
├── Makefile                                # Build automation (cross-platform)
├── pi_toolchain.cmake                      # CMake toolchain for ARM64
├── README.md                               # This file
├── .docker/
│   ├── Dockerfile.native                   # Linux x86_64 build container
│   ├── Dockerfile.mingw                    # Windows MinGW build container
│   └── Dockerfile.pi                       # Raspberry Pi ARM64 build container
└── src/
    ├── domain/                             # Pure C++, no GUI dependencies
    │   ├── interfaces/
    │   │   ├── IEventBus.h                 # Event bus interface
    │   │   └── IWorker.h                   # Worker interface
    │   ├── models/
    │   │   └── SensorData.h                # Domain data structures
    │   ├── services/
    │   │   └── DataProcessingService.h     # Classification & alarms
    │   └── workers/
    │       └── SensorWorker.h              # Generates test data
    ├── infrastructure/                     # Pure C++, no GUI dependencies
    │   ├── EventBus.h                      # Thread-safe pub/sub
    │   └── WorkerThread.h                  # std::thread wrapper
    └── wx_adapter/                         # wxWidgets-specific code
        ├── WxApp.h/cpp                     # Application entry point
        ├── WxEventBusAdapter.h/cpp         # Event bus → UI bridge
        └── ui/
            └── MainWindow.h/cpp            # wxWidgets frame + controls
```

## Comparison: Qt vs wxWidgets

| Aspect | Qt | wxWidgets |
|--------|----|-----------| 
| Licensing | LGPL / Commercial | wxWindows License (permissive) |
| Platforms | Linux, Windows, macOS, iOS, Android | Linux, Windows, macOS |
| GUI Backend | Qt own | Platform native (GTK3, Win32, Cocoa) |
| Size | Larger | Lightweight |
| Learning Curve | Steeper (MOC, signals/slots) | Gentler (simpler event model) |
| Cross-Compile | Excellent | Good |
| Mobile Support | Excellent | Limited |

Both support the same decoupled architecture here — only the UI adapter layer differs.

## Future Enhancements

- Robot Framework test suite (similar to Qt version)
- Packaging (AppImage, NSIS installer, .app bundle)
- CI/CD pipelines (GitHub Actions)
- Remote debugging for Raspberry Pi
- Additional widgets (data plotting, configuration panels)
