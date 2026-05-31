# =============================================================================
# Multiplatform GUI Demo — top-level Makefile
#
# Adapters : qt (Qt5)  |  wx (wxWidgets)
# Platforms: native (Linux x86_64)  |  pi (ARM64 cross)  |  windows (MinGW)
#
# All Linux / Pi targets use the Ninja generator.
# The Windows target also uses Ninja (cross-compiling on a Linux host).
# "MinGW Makefiles" is the generator for running CMake natively on Windows.
# =============================================================================

ROOT_DIR   := $(shell pwd)
CMAKE      := cmake
NINJA      := ninja

TOOLCHAIN_PI    := cmake/pi_toolchain.cmake
TOOLCHAIN_MINGW := cmake/mingw_toolchain.cmake

BUILD_NATIVE_QT := build_native_qt
BUILD_NATIVE_WX := build_native_wx
BUILD_PI_QT     := build_pi_qt
BUILD_PI_WX     := build_pi_wx
BUILD_WIN_WX    := build_windows_wx

PI_HOST ?= 192.168.1.100
PI_USER ?= pi
TESTS_DIR ?= tests
RF_OPTS   ?=

.PHONY: help all \
        native-qt native-wx \
        pi-qt pi-wx \
        windows-wx \
        test-native-qt test-native-wx \
        docker-native-qt docker-native-wx \
        docker-pi-qt docker-pi-wx \
        docker-windows-wx \
        clean

# ── Help ─────────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  Targets"
	@echo "  -------"
	@echo "  native-qt        Build Qt5 adapter natively (Linux x86_64, Ninja, Debug)"
	@echo "  native-wx        Build wxWidgets adapter natively (Linux x86_64, Ninja, Release)"
	@echo "  pi-qt            Cross-compile Qt5 for Raspberry Pi ARM64 (Ninja, Debug)"
	@echo "  pi-wx            Cross-compile wxWidgets for Raspberry Pi ARM64 (Ninja, Debug)"
	@echo "  windows-wx       Cross-compile wxWidgets for Windows via MinGW (Ninja, Release)"
	@echo ""
	@echo "  test-native-qt   Build + Robot Framework GUI tests (Qt adapter)"
	@echo "  test-native-wx   Build + Robot Framework GUI tests (wx adapter)"
	@echo ""
	@echo "  Docker targets (build inside container):"
	@echo "  docker-native-qt / docker-native-wx"
	@echo "  docker-pi-qt     / docker-pi-wx"
	@echo "  docker-windows-wx"
	@echo ""
	@echo "  clean            Remove all build directories"
	@echo ""
	@echo "  Variables:"
	@echo "  GUI_ADAPTER      Override adapter from make (qt|wx)"
	@echo "  wxWidgets_ROOT_DIR   Override wxWidgets install prefix"
	@echo "  PI_HOST          Raspberry Pi address  (default: $(PI_HOST))"
	@echo "  PI_USER          Raspberry Pi SSH user (default: $(PI_USER))"
	@echo ""

all: native-qt native-wx

# ── Native builds ─────────────────────────────────────────────────────────────
native-qt:
	@echo "==> Native Qt build (x86_64, Ninja, Debug) ..."
	@mkdir -p $(BUILD_NATIVE_QT)
	@cd $(BUILD_NATIVE_QT) && $(CMAKE) -G Ninja \
	    -DGUI_ADAPTER=qt \
	    -DCMAKE_BUILD_TYPE=Debug \
	    $(ROOT_DIR)
	@$(NINJA) -C $(BUILD_NATIVE_QT)
	@echo "==> Done: $(BUILD_NATIVE_QT)/SensorDemoQt"

native-wx:
	@echo "==> Native wxWidgets build (x86_64, Ninja, Release) ..."
	@mkdir -p $(BUILD_NATIVE_WX)
	@cd $(BUILD_NATIVE_WX) && $(CMAKE) -G Ninja \
	    -DGUI_ADAPTER=wx \
	    -DCMAKE_BUILD_TYPE=Release \
	    $(if $(wxWidgets_ROOT_DIR),-DwxWidgets_ROOT_DIR=$(wxWidgets_ROOT_DIR),) \
	    $(ROOT_DIR)
	@$(NINJA) -C $(BUILD_NATIVE_WX)
	@echo "==> Done: $(BUILD_NATIVE_WX)/SensorDemoWx"

# ── Raspberry Pi cross-compile ────────────────────────────────────────────────
pi-qt:
	@echo "==> Pi ARM64 Qt cross-compile (Ninja, Debug) ..."
	@mkdir -p $(BUILD_PI_QT)
	@cd $(BUILD_PI_QT) && $(CMAKE) -G Ninja \
	    -DGUI_ADAPTER=qt \
	    -DCMAKE_BUILD_TYPE=Debug \
	    -DCMAKE_TOOLCHAIN_FILE=$(ROOT_DIR)/$(TOOLCHAIN_PI) \
	    $(ROOT_DIR)
	@$(NINJA) -C $(BUILD_PI_QT)
	@echo "==> Done: $(BUILD_PI_QT)/SensorDemoQt"

pi-wx:
	@echo "==> Pi ARM64 wxWidgets cross-compile (Ninja, Debug) ..."
	@mkdir -p $(BUILD_PI_WX)
	@cd $(BUILD_PI_WX) && $(CMAKE) -G Ninja \
	    -DGUI_ADAPTER=wx \
	    -DCMAKE_BUILD_TYPE=Debug \
	    -DCMAKE_TOOLCHAIN_FILE=$(ROOT_DIR)/$(TOOLCHAIN_PI) \
	    $(if $(wxWidgets_ROOT_DIR),-DwxWidgets_ROOT_DIR=$(wxWidgets_ROOT_DIR),) \
	    $(ROOT_DIR)
	@$(NINJA) -C $(BUILD_PI_WX)
	@echo "==> Done: $(BUILD_PI_WX)/SensorDemoWx"

# ── Windows MinGW cross-compile ───────────────────────────────────────────────
windows-wx:
	@echo "==> Windows x86_64 wxWidgets cross-compile (MinGW Ninja, Release) ..."
	@mkdir -p $(BUILD_WIN_WX)
	@cd $(BUILD_WIN_WX) && $(CMAKE) -G Ninja \
	    -DGUI_ADAPTER=wx \
	    -DCMAKE_BUILD_TYPE=Release \
	    -DCMAKE_TOOLCHAIN_FILE=$(ROOT_DIR)/$(TOOLCHAIN_MINGW) \
	    $(if $(wxWidgets_ROOT_DIR),-DwxWidgets_ROOT_DIR=$(wxWidgets_ROOT_DIR),) \
	    $(ROOT_DIR)
	@$(NINJA) -C $(BUILD_WIN_WX)
	@echo "==> Done: $(BUILD_WIN_WX)/SensorDemoWx.exe"

# ── Tests ─────────────────────────────────────────────────────────────────────
test-native-qt: native-qt
	@echo "==> Qt native GUI tests ..."
	dbus-run-session -- python3 -m robot \
	    --outputdir $(TESTS_DIR)/results/native_qt \
	    --loglevel DEBUG $(RF_OPTS) \
	    $(TESTS_DIR)/suites/native_tests.robot

test-native-wx: native-wx
	@echo "==> wxWidgets native GUI tests ..."
	dbus-run-session -- python3 -m robot \
	    --outputdir $(TESTS_DIR)/results/native_wx \
	    --loglevel DEBUG $(RF_OPTS) \
	    $(TESTS_DIR)/suites/native_tests.robot

# ── Docker targets ────────────────────────────────────────────────────────────
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

# ── Clean ─────────────────────────────────────────────────────────────────────
clean:
	@echo "==> Removing all build directories ..."
	@rm -rf $(BUILD_NATIVE_QT) $(BUILD_NATIVE_WX) \
	        $(BUILD_PI_QT) $(BUILD_PI_WX) \
	        $(BUILD_WIN_WX)
	@echo "==> Done."
