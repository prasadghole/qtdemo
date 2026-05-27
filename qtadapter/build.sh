#!/bin/bash
set -e

echo "=========================================="
echo "  Qt5 Decoupled Architecture Demo"
echo "  Build script for WSL / Ubuntu"
echo "=========================================="

# ── Check dependencies ────────────────────────────────────────────────────────
check_dep() {
    if ! command -v "$1" &>/dev/null; then
        echo "[MISSING] $1 — installing..."
        sudo apt-get install -y "$2"
    else
        echo "[OK]      $1"
    fi
}

echo ""
echo "--- Checking dependencies ---"
check_dep cmake   cmake
check_dep make    make
check_dep g++     g++

# Check Qt5 dev package
if ! dpkg -l | grep -q "qtbase5-dev"; then
    echo "[MISSING] Qt5 dev — installing..."
    sudo apt-get update
    sudo apt-get install -y qtbase5-dev qtbase5-dev-tools
else
    echo "[OK]      Qt5 dev packages"
fi

# ── Build ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"

echo ""
echo "--- Configuring (CMake) ---"
cmake -S "$SCRIPT_DIR" \
      -B "$BUILD_DIR"  \
      -DCMAKE_BUILD_TYPE=Debug

echo ""
echo "--- Building ---"
cmake --build "$BUILD_DIR" --parallel "$(nproc)"

echo ""
echo "=========================================="
echo "  Build successful!"
echo "  Binary: $BUILD_DIR/Qt5DecoupledDemo"
echo ""
echo "  To run:"
echo "    $BUILD_DIR/Qt5DecoupledDemo"
echo ""
echo "  WSL display note: make sure your X server"
echo "  is running (VcXsrv, X410, or WSLg)."
echo "  If using WSLg (Windows 11): just run it."
echo "  If using VcXsrv: set DISPLAY=:0 first:"
echo "    export DISPLAY=:0"
echo "    $BUILD_DIR/Qt5DecoupledDemo"
echo "=========================================="
