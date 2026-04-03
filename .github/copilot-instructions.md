# Copilot Instructions for docker-elegooslicer

## Project Overview

This is a Docker container that runs Elegoo Slicer via a web-accessible desktop (Selkies/KasmVNC). It is based on the linuxserver.io base image `baseimage-selkies:ubuntunoble` and uses s6-overlay for service management.

## Architecture

- **Base image**: `ghcr.io/linuxserver/baseimage-selkies:ubuntunoble` (Ubuntu 24.04 Noble)
- **App source**: Elegoo Slicer AppImage extracted from GitHub releases
- **Service manager**: s6-overlay (services in `root/etc/s6-overlay/s6-rc.d/`)
- **Desktop autostart**: `root/defaults/autostart` launches the slicer binary
- **Network**: Avahi/mDNS for printer discovery (requires `network_mode: host`)

## Binary Patch

The Dockerfile applies a binary patch to `elegoo-slicer` to fix an uninitialized `mIsInitialized` field in `PrinterManager`. The patch uses hardcoded offsets into the ELF binary with assertions on original byte values.

**When updating the Elegoo Slicer version:**
- The patch offsets will almost certainly change and need to be re-derived
- Build will fail with assertion errors if offsets are wrong (by design)
- Use a disassembler (e.g., Ghidra, objdump) to find the new `PrinterManager` constructor and re-calculate offsets
- The patch targets three locations: constructor zero-init and two conditional jump fixes

## Key Files

- `Dockerfile` — Main build file with package installation, AppImage extraction, and binary patch
- `docker-compose.yaml` — Development/deployment compose file
- `root/defaults/autostart` — X11 autostart script that launches Elegoo Slicer
- `root/etc/s6-overlay/s6-rc.d/svc-avahi/` — Avahi daemon service definition
- `root/etc/s6-overlay/s6-rc.d/svc-dbus/` — D-Bus service (dependency of Avahi)
- `config/` — Mounted as `/config` in the container; holds user settings and slicer profiles

## Conventions

- Follow linuxserver.io container conventions (PUID/PGID, /config volume, s6-overlay services)
- Use `DEBIAN_FRONTEND=noninteractive` for apt-get in Dockerfile
- Chain RUN commands with `&&` to minimize layers
- Always clean up apt caches and temp files at the end of RUN steps
- Use conventional commit messages (`feat:`, `fix:`, `chore:`, etc.)

## Testing

After building, verify:
1. Container starts without errors (`docker logs elegooslicer`)
2. Binary patch is applied (check assertion output in build log)
3. Elegoo Slicer process is running (`docker exec elegooslicer ps aux | grep elegoo`)
4. Web UI is accessible on ports 3000 (HTTP) / 3001 (HTTPS)
5. Printer discovery works via mDNS (requires host networking)
