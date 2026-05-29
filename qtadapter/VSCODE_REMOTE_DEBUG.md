---
title: VSCode Remote Debugging Quick Start
---

# VSCode Remote Debugging Setup

## Quick Setup (2 minutes)

### 1. Update launch.json
Edit `.vscode/launch.json` and replace `<REMOTE_IP>` in the **pipeArgs** section:

```json
"pipeArgs": [
    "-T",
    "pi@192.168.1.100"     // Replace with your device IP
]
```

### 2. Build for Pi
```bash
make pi
```

### 3. Deploy & Start gdbserver
```bash
./deploy-and-debug.sh 192.168.1.100 pi 2345
```

The script:
- Copies `build_pi/Qt5DecoupledDemo` to the remote device
- Starts gdbserver listening on port 2345
- Waits for debugger connection

### 4. Debug in VSCode

1. **Select Configuration**: Click the debug config dropdown → "Debug Remote Pi (ARM64 via gdbserver)"
2. **Start Debugging**: Press `F5` or click the green play button
3. **Set Breakpoints**: Click line numbers in editor—they sync to remote execution
4. **Inspect Variables**: Hover over variables, use Debug Console

## How It Works

- **Host GDB**: `/usr/bin/aarch64-linux-gnu-gdb` (cross-debugger on WSL)
- **Remote gdbserver**: Runs on CM5, executes actual code
- **Connection**: Host GDB → gdbserver on CM5:2345 (SSH tunnel)
- **Symbol Resolution**: Uses local `build_pi/Qt5DecoupledDemo` binary for debug symbols

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Connection refused" | Ensure gdbserver is running on remote (`./deploy-and-debug.sh` keeps it running) |
| "Cannot find executable" | Run `make pi` first; binary path must match in launch.json |
| Wrong IP in launch.json | Edit `.vscode/launch.json` and replace `<REMOTE_IP>` with actual IP |
| "Symbol lookup error" | Confirm binary has debug symbols: `aarch64-linux-gnu-nm -g build_pi/Qt5DecoupledDemo \| head` |

## Advanced: Custom Port or User

```bash
./deploy-and-debug.sh 192.168.1.100 root 5555
# Uses custom user (root) and port (5555)
```

Then update launch.json to match:
```json
"target remote 192.168.1.100:5555"
```

## One-liner: Build → Deploy → Debug

```bash
make clean && make pi && ./deploy-and-debug.sh 192.168.1.100
```
