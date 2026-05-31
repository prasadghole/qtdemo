# =============================================================================
# Multiplatform GUI Demo — top-level Makefile
#
# Adapters : qt (Qt5)  |  wx (wxWidgets)
# Platforms: native (Linux x86_64)  |  pi (ARM64 cross)  |  windows (MinGW)
#
# Usage:
#   make native-qt       # configure (once) + build Qt adapter for Linux
#   make native-wx       # configure (once) + build wxWidgets adapter for Linux
#   make pi-qt           # configure (once) + cross-compile Qt for Pi ARM64
#   make pi-wx           # configure (once) + cross-compile wxWidgets for Pi ARM64
#   make windows-wx      # configure (once) + cross-compile wxWidgets for Windows
#   make all             # native-qt + native-wx
#   make clean           # remove all build directories
#
# CMake runs only on the first build or when CMakeLists.txt changes (Ninja
# tracks this automatically via the generated build.ninja).  Re-run
# 'make reconfigure-<target>' to force a fresh cmake configure.
# =============================================================================

ROOT_DIR        := $(shell pwd)
CMAKE           := cmake
NINJA           := ninja

TOOLCHAIN_PI    := cmake/pi_toolchain.cmake
TOOLCHAIN_MINGW := cmake/mingw_toolchain.cmake

BUILD_NATIVE_QT := build_native_qt
BUILD_NATIVE_WX := build_native_wx
BUILD_PI_QT     := build_pi_qt
BUILD_PI_WX     := build_pi_wx
BUILD_WIN_WX    := build_windows_wx

PI_HOST   ?= 192.168.1.100
PI_USER   ?= pi
TESTS_DIR ?= tests
RF_OPTS   ?=

# ---------------------------------------------------------------------------
# Public targets
# ---------------------------------------------------------------------------
.PHONY: help all \
        native-qt native-wx \
        pi-qt pi-wx \
        windows-wx \
        reconfigure-native-qt reconfigure-native-wx \
        reconfigure-pi-qt reconfigure-pi-wx \
        reconfigure-windows-wx \
        test-native-qt test-native-wx \
        docker-native-qt docker-native-wx \
        docker-pi-qt docker-pi-wx \
        docker-windows-wx \
        clean

# ---------------------------------------------------------------------------
help:
	@echo ""
	@echo "  Build targets"
	@echo "  -------------"
	@echo "  native-qt        Qt5 adapter  — Linux x86_64  (Debug,   Ninja)"
	@echo "  native-wx        wxWidgets    — Linux x86_64  (Release, Ninja)"
	@echo "  pi-qt            Qt5 adapter  — Pi ARM64      (Debug,   Ninja cross)"
	@echo "  pi-wx            wxWidgets    — Pi ARM64      (Debug,   Ninja cross)"
	@echo "  windows-wx       wxWidgets    — Windows x64   (Release, MinGW Ninja)"
	@echo "  all              native-qt + native-wx"
	@echo ""
	@echo "  Reconfigure (force cmake re-run without full clean)"
	@echo "  reconfigure-native-qt / reconfigure-native-wx"
	@echo "  reconfigure-pi-qt     / reconfigure-pi-wx"
	@echo "  reconfigure-windows-wx"
	@echo ""
	@echo "  Test targets"
	@echo "  test-native-qt   Build + Robot Framework GUI tests (Qt)"
	@echo "  test-native-wx   Build + Robot Framework GUI tests (wx)"
	@echo ""
	@echo "  Docker targets   (build inside container, no local toolchain needed)"
	@echo "  docker-native-qt / docker-native-wx"
	@echo "  docker-pi-qt     / docker-pi-wx"
	@echo "  docker-windows-wx"
	@echo ""
	@echo "  clean            Remove all build directories"
	@echo ""
	@echo "  Overridable variables:"
	@echo "  wxWidgets_ROOT_DIR   wxWidgets install prefix (pi-wx, windows-wx)"
	@echo "  PI_HOST              Raspberry Pi address  (default: $(PI_HOST))"
	@echo "  PI_USER              Raspberry Pi SSH user (default: $(PI_USER))"
	@echo ""

all: native-qt native-wx

# ===========================================================================
# Configure rules — cmake runs only when build.ninja does not yet exist.
# Ninja re-invokes cmake automatically when any CMakeLists.txt changes.
# ===========================================================================

$(BUILD_NATIVE_QT)/build.ninja:
	@echo "==> [configure] native-qt (Qt5, x86_64, Debug)"
	@mkdir -p $(BUILD_NATIVE_QT)
	$(CMAKE) -G Ninja \
	    -DGUI_ADAPTER=qt \
	    -DCMAKE_BUILD_TYPE=Debug \
	    -S $(ROOT_DIR) -B $(BUILD_NATIVE_QT)

$(BUILD_NATIVE_WX)/build.ninja:
	@echo "==> [configure] native-wx (wxWidgets, x86_64, Release)"
	@mkdir -p $(BUILD_NATIVE_WX)
	$(CMAKE) -G Ninja \
	    -DGUI_ADAPTER=wx \
	    -DCMAKE_BUILD_TYPE=Release \
	    $(if $(wxWidgets_ROOT_DIR),-DwxWidgets_ROOT_DIR=$(wxWidgets_ROOT_DIR),) \
	    -S $(ROOT_DIR) -B $(BUILD_NATIVE_WX)

$(BUILD_PI_QT)/build.ninja:
	@echo "==> [configure] pi-qt (Qt5, ARM64, Debug)"
	@mkdir -p $(BUILD_PI_QT)
	$(CMAKE) -G Ninja \
	    -DGUI_ADAPTER=qt \
	    -DCMAKE_BUILD_TYPE=Debug \
	    -DCMAKE_TOOLCHAIN_FILE=$(ROOT_DIR)/$(TOOLCHAIN_PI) \
	    -S $(ROOT_DIR) -B $(BUILD_PI_QT)

$(BUILD_PI_WX)/build.ninja:
	@if [ -z "$(wxWidgets_ROOT_DIR)" ] && \
	    [ ! -f /usr/lib/aarch64-linux-gnu/wx/config/gtk3-unicode-3.2 ]; then \
	    echo ""; \
	    echo "ERROR: ARM64 wxWidgets not found. Choose one option:"; \
	    echo ""; \
	    echo "  Option A — install Debian multiarch package (fast):"; \
	    echo "    sudo apt-get install -y libwxgtk3.2-dev:arm64"; \
	    echo "    make pi-wx"; \
	    echo ""; \
	    echo "  Option B — build in Docker (no local install needed):"; \
	    echo "    make docker-pi-wx"; \
	    echo ""; \
	    echo "  Option C — point to a pre-built ARM64 wxWidgets:"; \
	    echo "    make pi-wx wxWidgets_ROOT_DIR=/path/to/wx-arm64"; \
	    echo ""; \
	    exit 1; \
	fi
	@echo "==> [configure] pi-wx (wxWidgets, ARM64, Debug)"
	@mkdir -p $(BUILD_PI_WX)
	$(CMAKE) -G Ninja \
	    -DGUI_ADAPTER=wx \
	    -DCMAKE_BUILD_TYPE=Debug \
	    -DCMAKE_TOOLCHAIN_FILE=$(ROOT_DIR)/$(TOOLCHAIN_PI) \
	    $(if $(wxWidgets_ROOT_DIR),-DwxWidgets_ROOT_DIR=$(wxWidgets_ROOT_DIR),) \
	    -S $(ROOT_DIR) -B $(BUILD_PI_WX)

$(BUILD_WIN_WX)/build.ninja:
	@echo "==> [configure] windows-wx (wxWidgets, MinGW x64, Release)"
	@mkdir -p $(BUILD_WIN_WX)
	$(CMAKE) -G Ninja \
	    -DGUI_ADAPTER=wx \
	    -DCMAKE_BUILD_TYPE=Release \
	    -DCMAKE_TOOLCHAIN_FILE=$(ROOT_DIR)/$(TOOLCHAIN_MINGW) \
	    $(if $(wxWidgets_ROOT_DIR),-DwxWidgets_ROOT_DIR=$(wxWidgets_ROOT_DIR),) \
	    -S $(ROOT_DIR) -B $(BUILD_WIN_WX)

# ===========================================================================
# Build rules — depend on their configure rule; skip cmake on rebuild.
# ===========================================================================

native-qt: $(BUILD_NATIVE_QT)/build.ninja
	@echo "==> [build] native-qt"
	$(NINJA) -C $(BUILD_NATIVE_QT)

native-wx: $(BUILD_NATIVE_WX)/build.ninja
	@echo "==> [build] native-wx"
	$(NINJA) -C $(BUILD_NATIVE_WX)

pi-qt: $(BUILD_PI_QT)/build.ninja
	@echo "==> [build] pi-qt"
	$(NINJA) -C $(BUILD_PI_QT)

pi-wx: $(BUILD_PI_WX)/build.ninja
	@echo "==> [build] pi-wx"
	$(NINJA) -C $(BUILD_PI_WX)

windows-wx: $(BUILD_WIN_WX)/build.ninja
	@echo "==> [build] windows-wx"
	$(NINJA) -C $(BUILD_WIN_WX)

# ===========================================================================
# Reconfigure — delete cmake cache so the next build re-runs cmake.
# Useful after changing GUI_ADAPTER or toolchain without a full clean.
# ===========================================================================

reconfigure-native-qt:
	@rm -f $(BUILD_NATIVE_QT)/CMakeCache.txt $(BUILD_NATIVE_QT)/build.ninja
	@$(MAKE) --no-print-directory $(BUILD_NATIVE_QT)/build.ninja

reconfigure-native-wx:
	@rm -f $(BUILD_NATIVE_WX)/CMakeCache.txt $(BUILD_NATIVE_WX)/build.ninja
	@$(MAKE) --no-print-directory $(BUILD_NATIVE_WX)/build.ninja

reconfigure-pi-qt:
	@rm -f $(BUILD_PI_QT)/CMakeCache.txt $(BUILD_PI_QT)/build.ninja
	@$(MAKE) --no-print-directory $(BUILD_PI_QT)/build.ninja

reconfigure-pi-wx:
	@rm -f $(BUILD_PI_WX)/CMakeCache.txt $(BUILD_PI_WX)/build.ninja
	@$(MAKE) --no-print-directory $(BUILD_PI_WX)/build.ninja

reconfigure-windows-wx:
	@rm -f $(BUILD_WIN_WX)/CMakeCache.txt $(BUILD_WIN_WX)/build.ninja
	@$(MAKE) --no-print-directory $(BUILD_WIN_WX)/build.ninja

# ===========================================================================
# Tests
# ===========================================================================

test-native-qt: native-qt
	dbus-run-session -- python3 -m robot \
	    --outputdir $(TESTS_DIR)/results/native_qt \
	    --loglevel DEBUG $(RF_OPTS) \
	    $(TESTS_DIR)/suites/native_tests.robot

test-native-wx: native-wx
	dbus-run-session -- python3 -m robot \
	    --outputdir $(TESTS_DIR)/results/native_wx \
	    --loglevel DEBUG $(RF_OPTS) \
	    $(TESTS_DIR)/suites/native_tests.robot

# ===========================================================================
# Docker — build inside a container (no local toolchain required)
# ===========================================================================

CONTAINER_WORKDIR := /workspace

docker-native-qt:
	docker build -t sensor-demo-native-qt -f .docker/Dockerfile.native-qt .
	docker run --rm -v $(ROOT_DIR):$(CONTAINER_WORKDIR) sensor-demo-native-qt make native-qt

docker-native-wx:
	docker build -t sensor-demo-native-wx -f .docker/Dockerfile.native-wx .
	docker run --rm -v $(ROOT_DIR):$(CONTAINER_WORKDIR) sensor-demo-native-wx make native-wx

docker-pi-qt:
	docker build -t sensor-demo-pi-qt -f .docker/Dockerfile.pi-qt .
	docker run --rm -v $(ROOT_DIR):$(CONTAINER_WORKDIR) sensor-demo-pi-qt make pi-qt

docker-pi-wx:
	docker build -t sensor-demo-pi-wx -f .docker/Dockerfile.pi-wx .
	docker run --rm -v $(ROOT_DIR):$(CONTAINER_WORKDIR) sensor-demo-pi-wx make pi-wx

docker-windows-wx:
	docker build -t sensor-demo-windows-wx -f .docker/Dockerfile.mingw-wx .
	docker run --rm -v $(ROOT_DIR):$(CONTAINER_WORKDIR) sensor-demo-windows-wx make windows-wx

# ===========================================================================
# Clean
# ===========================================================================

clean:
	@echo "==> Removing all build directories ..."
	@rm -rf $(BUILD_NATIVE_QT) $(BUILD_NATIVE_WX) \
	        $(BUILD_PI_QT) $(BUILD_PI_WX) \
	        $(BUILD_WIN_WX)
	@echo "==> Done."
