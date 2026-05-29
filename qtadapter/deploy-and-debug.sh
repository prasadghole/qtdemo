#!/bin/bash
set -e

# Deploy binary and start gdbserver on remote host
# Usage: ./deploy-and-debug.sh <REMOTE_IP> [USERNAME] [DEBUG_PORT]

if [ $# -lt 1 ]; then
    echo "Usage: $0 <REMOTE_IP> [USERNAME] [DEBUG_PORT]"
    echo ""
    echo "Examples:"
    echo "  $0 192.168.1.100              # Default: user 'pi', port 2345"
    echo "  $0 192.168.1.100 root 5555    # Custom user and port"
    exit 1
fi

REMOTE_IP=$1
REMOTE_USER=${2:-pi}
DEBUG_PORT=${3:-2345}
BINARY_PATH="build_pi/Qt5DecoupledDemo"
REMOTE_HOME="/home/${REMOTE_USER}"
REMOTE_BINARY="${REMOTE_HOME}/Qt5DecoupledDemo"

echo "=========================================="
echo "Deploy & Debug Configuration"
echo "=========================================="
echo "Remote Host:  ${REMOTE_USER}@${REMOTE_IP}"
echo "Debug Port:   ${DEBUG_PORT}"
echo "Binary:       ${BINARY_PATH}"
echo ""

# Step 1: Check if binary exists
if [ ! -f "${BINARY_PATH}" ]; then
    echo "❌ Error: Binary not found at ${BINARY_PATH}"
    echo "   Run 'make pi' first to cross-compile"
    exit 1
fi

# Step 2: Deploy binary
echo "📦 Deploying binary to ${REMOTE_IP}..."
rsync -azv "${BINARY_PATH}" "${REMOTE_USER}@${REMOTE_IP}:${REMOTE_BINARY}"
if [ $? -ne 0 ]; then
    echo "❌ rsync failed. Check SSH connection and permissions."
    exit 1
fi
echo "✅ Binary deployed"

# Step 3: Start gdbserver on remote
echo ""
echo "🚀 Starting gdbserver on remote host (headless mode)..."
echo "   Command: QT_QPA_PLATFORM=offscreen gdbserver :${DEBUG_PORT} ${REMOTE_BINARY}"
echo ""
echo "⚠️  Process waiting for debugger connection on ${REMOTE_IP}:${DEBUG_PORT}"
echo ""
echo "Next steps:"
echo "  • VSCode: Select 'Debug Remote Pi (ARM64 via gdbserver)' and press F5"
echo "  • Qt Creator: Debug → Start Debugging → Attach to Running Debug Server"
echo "             Local executable: build_pi/Qt5DecoupledDemo"
echo "             Server: ${REMOTE_IP}:${DEBUG_PORT}"
echo ""

ssh "${REMOTE_USER}@${REMOTE_IP}" "QT_QPA_PLATFORM=offscreen gdbserver :${DEBUG_PORT} ${REMOTE_BINARY}"
