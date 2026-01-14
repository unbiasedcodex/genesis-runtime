# Genesis Runtime

> Userspace system services for Genesis OS

---

## Overview

Genesis Runtime provides the userspace layer of Genesis OS. Following the microkernel philosophy, all drivers and system services run in userspace, communicating via IPC with the kernel.

## Components

| Service | Status | Description |
|---------|--------|-------------|
| Init | Planned | Process manager, service spawner |
| Filesystem | Planned | FAT16/32, ext2 filesystem server |
| Network | Planned | TCP/IP stack, socket API |
| Display | Planned | Framebuffer, window compositor |
| Audio | Planned | Audio mixer, playback |
| Input | Planned | Keyboard, mouse handling |

## Requirements

- Genesis Lang compiler (`glc` v0.1.2+)
- Genesis Kernel (v0.0.12+)

## Building

```bash
# Build all services
make all

# Build specific service
make init
make fs
make net

# Create combined ISO with kernel
make iso
```

## Running

```bash
# Run with QEMU (requires kernel ISO)
make run
```

## Documentation

See `/docs/000 - Runtime.md` for detailed development plan.

## Directory Structure

```
genesis-runtime/
├── src/
│   ├── init/           # Init system
│   ├── fs/             # Filesystem server
│   ├── net/            # Network stack
│   ├── display/        # Display server
│   ├── audio/          # Audio server
│   └── input/          # Input server
├── lib/                # Shared libraries
└── tests/              # Test suite
```

## License

MIT
