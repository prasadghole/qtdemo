# ==========================================
# Paths & Files
# ==========================================
BUILD_NATIVE_DIR = build_native
BUILD_PI_DIR = build_pi
TOOLCHAIN_FILE = pi_toolchain.cmake

IMAGE_NAME = qt5-cross-builder
CONTAINER_WORK_DIR = /workspace

.PHONY: all native pi clean help docker-image docker-build-pi docker-build-native \
        install-test-deps test-native test-cross deploy-pi

# Default target when you just run 'make'
help:
	@echo "Available local build targets:"
	@echo "  make native             - Build natively for WSL (x86_64) [Ninja]"
	@echo "  make pi                 - Cross-compile for Raspberry Pi CM5 (ARM64) [Ninja]"
	@echo "  make clean              - Remove all build directories"
	@echo ""
	@echo "Available Docker build targets:"
	@echo "  make docker-image        - Build the Docker cross-compiler image"
	@echo "  make docker-build-native - Compile natively inside Docker container"
	@echo "  make docker-build-pi     - Cross-compile for Pi inside Docker container"
	@echo ""
	@echo "Available test targets:"
	@echo "  make install-test-deps   - Install system + Python test dependencies"
	@echo "  make test-native         - Build native binary and run Robot Framework tests"
	@echo "  make test-cross          - Cross-compile, deploy to Pi, and run cross tests"
	@echo "  make deploy-pi           - Cross-compile and deploy ARM64 binary to Pi"
	@echo ""
	@echo "Test options:"
	@echo "  PI_HOST=<ip>             - Raspberry Pi IP address (default: 192.168.1.100)"
	@echo "  PI_USER=<user>           - Pi SSH username (default: pi)"
	@echo "  RF_OPTS=<opts>           - Extra Robot Framework options (e.g. --include smoke)"

all: native pi

# ==========================================
# Local Compilation Targets
# ==========================================
native:
	@echo "==> Configuring and building natively for WSL (x86_64)..."
	mkdir -p $(BUILD_NATIVE_DIR)
	cd $(BUILD_NATIVE_DIR) && cmake -G Ninja ..
	ninja -C $(BUILD_NATIVE_DIR)

pi:
	@echo "==> Configuring and cross-compiling for Raspberry Pi CM5 (ARM64)..."
	mkdir -p $(BUILD_PI_DIR)
	cd $(BUILD_PI_DIR) && cmake -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_TOOLCHAIN_FILE=../$(TOOLCHAIN_FILE) ..
	ninja -C $(BUILD_PI_DIR)

clean:
	@echo "==> Cleaning up build folders..."
	rm -rf $(BUILD_NATIVE_DIR) $(BUILD_PI_DIR)
	@echo "==> Done."

# ==========================================
# Docker Automation Targets
# ==========================================
docker-image:
	@echo "==> Building Docker cross-compilation image..."
	docker build -t $(IMAGE_NAME) .

docker-build-pi:
	@echo "==> Compiling for Raspberry Pi inside Docker..."
	docker run --rm -v $(shell pwd):$(CONTAINER_WORK_DIR) $(IMAGE_NAME) make pi

docker-build-native:
	@echo "==> Compiling natively inside Docker..."
	docker run --rm -v $(shell pwd):$(CONTAINER_WORK_DIR) $(IMAGE_NAME) make native

# ==========================================
# Test Targets
# ==========================================
TESTS_DIR = ../tests
PI_HOST   ?= 192.168.1.100
PI_USER   ?= pi
RF_OPTS   ?=

install-test-deps:
	@echo "==> Installing system test dependencies..."
	sudo apt-get install -y xvfb at-spi2-core at-spi2-common \
	    python3-pyatspi python3-dbus python3-gi dbus-x11
	@echo "==> Installing Python test dependencies..."
	pip3 install robotframework robotframework-sshlibrary robotframework-pythonlibcore

test-native: native
	@echo "==> Running native GUI tests..."
	dbus-run-session -- python3 -m robot \
	    --variablefile $(TESTS_DIR)/variables/native_vars.py \
	    --outputdir $(TESTS_DIR)/results/native \
	    --loglevel DEBUG \
	    $(RF_OPTS) \
	    $(TESTS_DIR)/suites/native_tests.robot
	@echo "==> Results: $(TESTS_DIR)/results/native/report.html"

test-cross: deploy-pi
	@echo "==> Running cross (Pi) GUI tests..."
	dbus-run-session -- python3 -m robot \
	    --variablefile $(TESTS_DIR)/variables/cross_vars.py \
	    --variable PI_HOST:$(PI_HOST) \
	    --variable PI_USER:$(PI_USER) \
	    --outputdir $(TESTS_DIR)/results/cross \
	    --loglevel DEBUG \
	    $(RF_OPTS) \
	    $(TESTS_DIR)/suites/cross_tests.robot
	@echo "==> Results: $(TESTS_DIR)/results/cross/report.html"

deploy-pi: pi
	@echo "==> Deploying ARM64 binary to $(PI_HOST)..."
	$(TESTS_DIR)/scripts/deploy_pi.sh $(PI_HOST) $(PI_USER)