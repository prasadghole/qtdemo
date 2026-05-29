# ==========================================
# Paths & Files
# ==========================================
BUILD_NATIVE_DIR = build_native
BUILD_PI_DIR = build_pi
TOOLCHAIN_FILE = pi_toolchain.cmake

IMAGE_NAME = qt5-cross-builder
CONTAINER_WORK_DIR = /workspace

.PHONY: all native pi clean help docker-image docker-build-pi docker-build-native

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