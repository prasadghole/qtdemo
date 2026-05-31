#!/bin/bash
set -e

# Deploy Qt binary to Pi and start gdbserver for remote debugging.
# Usage: ./deploy-and-debug.sh <REMOTE_IP> [USERNAME] [DEBUG_PORT]
#
# Examples:
#   ./deploy-and-debug.sh 192.168.1.100
#   ./deploy-and-debug.sh 192.168.1.100 root 5555

if [ $# -lt 1 ]; then
    echo "Usage: $0 <REMOTE_IP> [USERNAME] [DEBUG_PORT]"
    exit 1
fi

REMOTE_IP=$1
REMOTE_USER=${2:-pi}
DEBUG_PORT=${3:-2345}
BINARY_PATH="build_pi_qt/adapters/qt/SensorDemoQt"
REMOTE_BINARY="/home/${REMOTE_USER}/SensorDemoQt"

echo "Remote: ${REMOTE_USER}@${REMOTE_IP}  Port: ${DEBUG_PORT}"

if [ ! -f "${BINARY_PATH}" ]; then
    echo "Error: binary not found at ${BINARY_PATH} — run 'make pi-qt' first"
    exit 1
fi

echo "Deploying ${BINARY_PATH} ..."
rsync -azv "${BINARY_PATH}" "${REMOTE_USER}@${REMOTE_IP}:${REMOTE_BINARY}"

echo ""
echo "Starting gdbserver on remote (waiting for debugger on port ${DEBUG_PORT}) ..."
echo "VSCode: select 'Debug Remote Pi (ARM64 via gdbserver)' and press F5"
echo ""

ssh "${REMOTE_USER}@${REMOTE_IP}" "QT_QPA_PLATFORM=offscreen gdbserver :${DEBUG_PORT} ${REMOTE_BINARY}"
