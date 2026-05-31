---
title: VSCode Remote Debugging Quick Start
---

# VSCode Remote Debugging Setup

## Quick Setup (2 minutes)

### 1. Update launch.json
Edit `.vscode/launch.json` and replace the IP in the **miDebuggerServerAddress** field:

```json
"miDebuggerServerAddress": "192.168.1.100:2345"
```

### 2. Build for Pi
```bash
make pi-qt
```

### 3. Deploy & Start gdbserver
```bash
./deploy-and-debug.sh 192.168.1.100 pi 2345
```

The script:
- Copies `build_pi_qt/adapters/qt/SensorDemoQt` to the remote device
- Starts gdbserver listening on port 2345
- Waits for debugger connection

### 4. Debug in VSCode

1. **Select Configuration**: Click the debug config dropdown → "Debug Remote Pi (ARM64 via gdbserver)"
2. **Start Debugging**: Press `F5` or click the green play button
3. **Set Breakpoints**: Click line numbers in editor — they sync to remote execution
4. **Inspect Variables**: Hover over variables, use Debug Console

## How It Works

- **Host GDB**: `/usr/bin/gdb-multiarch` (cross-debugger on WSL)
- **Remote gdbserver**: Runs on CM5, executes actual code
- **Connection**: Host GDB → gdbserver on CM5:2345
- **Symbol Resolution**: Uses local `build_pi_qt/adapters/qt/SensorDemoQt` for debug symbols

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Connection refused" | Ensure gdbserver is running (`./deploy-and-debug.sh` keeps it waiting) |
| "Cannot find executable" | Run `make pi-qt` first |
| Wrong IP | Edit `.vscode/launch.json` `miDebuggerServerAddress` |
| "Symbol lookup error" | Confirm binary has debug symbols: `aarch64-linux-gnu-nm -g build_pi_qt/adapters/qt/SensorDemoQt \| head` |
| GDB times out on connect | Sysroot missing — run `sudo ./setup-pi-sysroot.sh` |

## Advanced: Custom Port or User

```bash
./deploy-and-debug.sh 192.168.1.100 root 5555
```

Then update `.vscode/launch.json` `miDebuggerServerAddress` to `192.168.1.100:5555`.

## One-liner: Build → Deploy → Debug

```bash
make pi-qt && ./deploy-and-debug.sh 192.168.1.100
```
