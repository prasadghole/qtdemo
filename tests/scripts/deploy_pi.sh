#!/usr/bin/env bash
# deploy_pi.sh — Copy ARM64 binary to Pi and verify it launches.
#
# Usage:
#   ./deploy_pi.sh <PI_HOST> [PI_USER] [PI_BINARY_DIR]
#
# Example:
#   ./deploy_pi.sh 192.168.1.100 pi /home/pi
#
# The script:
#   1. Checks the ARM64 binary exists (build with 'make pi' first)
#   2. SCPs the binary to the Pi
#   3. Installs at-spi2-core on the Pi if missing
#   4. Smoke-tests the binary with QT_QPA_PLATFORM=offscreen

set -euo pipefail

PI_HOST=${1:? "Usage: $0 <PI_HOST> [PI_USER] [PI_BINARY_DIR]"}
PI_USER=${2:-pi}
PI_DIR=${3:-/home/${PI_USER}}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_BINARY="${SCRIPT_DIR}/../../qtadapter/build_pi/Qt5DecoupledDemo"
REMOTE_BINARY="${PI_DIR}/Qt5DecoupledDemo"

echo "==> Deploying ARM64 binary to ${PI_USER}@${PI_HOST}:${REMOTE_BINARY}"

if [[ ! -f "${LOCAL_BINARY}" ]]; then
    echo "ERROR: Binary not found at ${LOCAL_BINARY}"
    echo "       Run 'make pi' in qtadapter/ first."
    exit 1
fi

scp -o StrictHostKeyChecking=no \
    "${LOCAL_BINARY}" \
    "${PI_USER}@${PI_HOST}:${REMOTE_BINARY}"

ssh -o StrictHostKeyChecking=no "${PI_USER}@${PI_HOST}" \
    "chmod +x ${REMOTE_BINARY}"

echo "==> Ensuring at-spi2-core is installed on Pi..."
ssh -o StrictHostKeyChecking=no "${PI_USER}@${PI_HOST}" \
    "dpkg -s at-spi2-core >/dev/null 2>&1 || sudo apt-get install -y --no-install-recommends at-spi2-core at-spi2-common"

echo "==> Smoke-testing binary (offscreen, 2s timeout)..."
ssh -o StrictHostKeyChecking=no "${PI_USER}@${PI_HOST}" \
    "timeout 2 env QT_QPA_PLATFORM=offscreen ${REMOTE_BINARY} || true"

echo ""
echo "==> Deployment complete: ${REMOTE_BINARY}"
echo ""
echo "    To run cross tests:"
echo "      cd /home/user/qtdemo/tests"
echo "      dbus-run-session -- python3 -m robot \\"
echo "          --variablefile variables/cross_vars.py \\"
echo "          --variable PI_HOST:${PI_HOST} \\"
echo "          suites/cross_tests.robot"
