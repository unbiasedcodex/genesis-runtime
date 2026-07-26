# Genesis Runtime

> Userspace system services for Genesis OS

---

## Overview

Genesis Runtime provides the userspace layer of Genesis OS (~42,000 lines of Genesis Lang). Following the microkernel philosophy, system services run in userspace as separate processes, loaded by GRUB as multiboot modules and communicating with the kernel via syscalls/IPC.

## Services

| Service | Status | Load address | Description |
|---------|--------|--------------|-------------|
| Init | Implemented | 0x800000 (PID 1) | Spawns services, lifecycle management, restart |
| VFS | Implemented | 0x900000 (PID 2) | Filesystem server (IPC-based) |
| Console | Implemented | 0xA00000 (PID 3) | Console server |
| Shell | Implemented | 0xB00000 (PID 4) | Interactive shell |
| Display | Planned | - | Dedicated display server (currently in kernel) |
| Audio | Planned | - | Audio mixer, playback |
| Input | Planned | - | Dedicated input server (currently in kernel) |

### Shell commands

System commands (`health`, `uptime`, `whoami`, `env`), network commands (DNS resolution, HTTP client), and a TLS handshake integration test for HTTPS requests.

## Libraries

| Module | Description |
|--------|-------------|
| `net` | DNS resolver, HTTP client, URL parsing |
| `tls` | TLS 1.2 client with certificate chain support and validation hooks |
| `crypto` | AES, GCM, HMAC, SHA-256 |
| `html` | HTML tokenizer and tree builder (Genesis Browser) |
| `css` | CSS tokenizer, parser, selectors, cascade, values |
| `layout` | Box model, block, inline, and flex layout |
| `js` | JavaScript lexer, parser, interpreter, DOM builtins |
| `image` | PNG, JPEG, GIF, WebP, SVG decoders (+ deflate, XML) |
| `browser` | Genesis Browser (Geb): tabs, UI, engine integration |

## Requirements

- Genesis Lang compiler (`glc` v0.1.2+) — the Makefile invokes it via `cargo run` from a sibling `../genesis-lang` checkout
- Genesis Kernel (v0.0.12+) in a sibling `../genesis-kernel` checkout
- `nasm`, `ld`, `objcopy`

## Building

```bash
# Build all services (init, vfs, console, shell)
make all

# Build a specific service
make init
make vfs
make console
make shell

# Copy service ELFs into the kernel ISO tree
make install
```

## Running

```bash
# After make install, build and run the ISO from the kernel repo
cd ../genesis-kernel
make run        # serial output
make run-vga    # VGA display
make run-net    # with E1000 networking (needed for shell network commands)
```

## Directory Structure

```
genesis-runtime/
├── src/
│   ├── init/           # Init system (PID 1)
│   ├── fs/             # VFS server
│   ├── console/        # Console server
│   ├── shell/          # Shell (commands, HTTP/TLS tests)
│   ├── net/            # DNS, HTTP, URL
│   ├── tls/            # TLS 1.2 client
│   ├── crypto/         # AES, GCM, HMAC, SHA-256
│   ├── html/           # HTML tokenizer + tree builder
│   ├── css/            # CSS engine
│   ├── layout/         # Layout engine
│   ├── js/             # JavaScript interpreter
│   ├── image/          # Image decoders
│   └── browser/        # Genesis Browser (Geb)
├── lib/                # Shared runtime library (libruntime.gl)
└── tests/              # Test suite
```

## License

MIT
