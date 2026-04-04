# docker-elegooslicer

Web accessible Elegoo Slicer inside a Docker container.

This is a fork of [linuxserver/docker-orcaslicer](https://github.com/linuxserver/docker-orcaslicer) modified to run [Elegoo Slicer](https://github.com/ELEGOO-3D/ElegooSlicer) instead of OrcaSlicer.

## About

[Elegoo Slicer](https://github.com/ELEGOO-3D/ElegooSlicer) is a slicer software based on OrcaSlicer/Bambu Studio/PrusaSlicer, customized for Elegoo 3D printers including the Neptune, Saturn, and Mars series.

## Key Modifications

This fork includes the following changes on top of the linuxserver base:

### Binary Patch: `mIsInitialized` Bug Fix

Elegoo Slicer's `PrinterManager` class has a bug where the `mIsInitialized` member variable is not zero-initialized in the constructor. This causes undefined behavior — the field may contain garbage memory, leading the printer discovery and connection logic to believe it has already been initialized when it hasn't. Symptoms include printers not being discovered or the slicer hanging on startup.

The Dockerfile applies a binary patch at build time to the `elegoo-slicer` ELF binary:

| Offset | Original | Patched | Purpose |
|--------|----------|---------|---------|
| `0x1d4b24f` | `66 0f ef c9` (pxor xmm1,xmm1) | `c6 47 08 00` (mov byte ptr [rdi+8], 0) | Zero-initialize `mIsInitialized` in the constructor |
| `0x1d4b2cf` | `8f` (jg) | `87` (ja) | Fix conditional jump to use unsigned comparison |
| `0x1d4b2d6` | `8f` (jg) | `87` (ja) | Fix conditional jump to use unsigned comparison |

The patch includes assertions that verify the original bytes before writing, so the build will fail if the binary changes in a future release (requiring the offsets to be updated).

### Printer Discovery

Elegoo printers are discovered via UDP broadcast on the local network (not mDNS). This requires `network_mode: host` in docker-compose so the container can send and receive broadcast packets on the LAN. The slicer connects to discovered printers via MQTT.

## Supported Architectures

| Architecture | Available |
|--------------|-----------|
| x86-64       | ✅        |
| arm64        | ❌        |

## Usage

### docker-compose (recommended)

```yaml
---
services:
  elegooslicer:
    build: .
    container_name: elegooslicer
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./config:/config
    ports:
      - 3000:3000
      - 3001:3001
    shm_size: "1gb"
    restart: unless-stopped
```

### docker cli

```bash
docker build -t elegooslicer .
docker run -d \
  --name=elegooslicer \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Etc/UTC \
  -p 3000:3000 \
  -p 3001:3001 \
  -v /path/to/config:/config \
  --shm-size="1gb" \
  --restart unless-stopped \
  elegooslicer
```

## Application Setup

The application can be accessed at:

- **HTTPS**: https://yourhost:3001/
- **HTTP**: http://yourhost:3000/ (must be proxied, HTTPS required for full functionality)

### Security

> **Warning**: This container provides privileged access to the host system. Do not expose it to the Internet unless you have secured it properly.

By default, this container has no authentication. Set `CUSTOM_USER` and `PASSWORD` environment variables to enable basic HTTP auth for local network use.

For internet exposure, place the container behind a reverse proxy with robust authentication.

### Hardware Acceleration (GPU)

#### Intel & AMD (Open Source Drivers)

```yaml
    devices:
      - /dev/dri:/dev/dri
    environment:
      - PIXELFLUX_WAYLAND=true
      - DRINODE=/dev/dri/renderD128
      - DRI_NODE=/dev/dri/renderD128
```

#### Nvidia (Proprietary Drivers)

Prerequisites:
1. Proprietary drivers 580 or higher
2. Kernel parameter: `nvidia-drm.modeset=1`
3. Configure Docker for Nvidia runtime:
   ```bash
   sudo nvidia-ctk runtime configure --runtime=docker
   sudo systemctl restart docker
   ```

```yaml
    environment:
      - PIXELFLUX_WAYLAND=true
      - DRINODE=/dev/dri/renderD128
      - DRI_NODE=/dev/dri/renderD128
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [compute,video,graphics,utility]
```

## Parameters

| Parameter | Function |
|-----------|----------|
| `-p 3000:3000` | Elegoo Slicer desktop GUI HTTP (must be proxied) |
| `-p 3001:3001` | Elegoo Slicer desktop GUI HTTPS |
| `-e PUID=1000` | User ID |
| `-e PGID=1000` | Group ID |
| `-e TZ=Etc/UTC` | Timezone |
| `-e CUSTOM_USER=abc` | Optional: custom username |
| `-e PASSWORD=secret` | Optional: password for basic auth |
| `-e PIXELFLUX_WAYLAND=true` | Optional: enable Wayland mode |
| `-v /config` | User home directory, stores settings and files |
| `--shm-size=` | Set to 1gb to prevent browser crashes |

## Building locally

```bash
git clone <this-repo>
cd docker-elegooslicer
docker build --no-cache --pull -t elegooslicer:latest .
```

## Credits

- [linuxserver.io](https://linuxserver.io/) - Original docker-orcaslicer container
- [ELEGOO](https://github.com/ELEGOO-3D) - Elegoo Slicer software
- [OrcaSlicer](https://github.com/SoftFever/OrcaSlicer) - Base slicer software

## License

GPL-3.0 (following the original docker-orcaslicer license)
