# unifi-controller-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [UniFi Network Controller](https://github.com/linuxserver/docker-unifi-controller).

## What this is

A four-file TOS Docker application archive (`unificontrollerdocker.tar.gz`) that installs
UniFi Network Controller on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `unificontrollerdocker`)
- `unificontrollerdocker.lang` — 23-language superset (TOS requires 14)
- `unificontrollerdocker.svg` — application icon (326 bytes, 2 SVG elements)
- `docker-compose.yml` — one service, image `linuxserver/unifi-controller:8.0.24`

## How it works

| | |
|---|---|
| Container image | `linuxserver/unifi-controller:8.0.24` (Docker Hub, used unmodified) |
| Open | `https://<NAS-IP>:8013/` (container port 8443, self-signed certificate) |
| Runs as | non-root, `user: "1000:1000"` |
| Persistent data | `/config` → `/Volume1/DockerAppData/unificontrollerdocker/config`, `/usr/lib/unifi/data` → `/Volume1/DockerAppData/unificontrollerdocker/data`, `/usr/lib/unifi/logs` → `/Volume1/DockerAppData/unificontrollerdocker/logs`, `/usr/lib/unifi/run` → `/Volume1/DockerAppData/unificontrollerdocker/run` |
| Extra ports | `8014/tcp` device inform, `8015/udp` STUN, `8016/udp` discovery |
| Logs | `docker logs unificontrollerdocker` (stdout/stderr) |

`data/` (mounted at `/usr/lib/unifi/data`) holds `system.properties`, the `db/` MongoDB database, `keystore/` and the adoption credentials; `logs/` holds the controller logs; `config/` is the working directory. Copying the `unificontrollerdocker` folder is a complete backup of the controller.

## Design highlights

- **Non-root.** `user: "1000:1000"`; verified on real hardware (the container reports uid 1000).
- **Entrypoint wrapper** (not a privilege shim): the image's s6 init needs root to prepare its data paths, so `src/entrypoint.sh` performs that setup and starts the bundled UniFi Java controller directly as the unprivileged container user.
- **Deterministic build**: GNU tar with uid/gid 0 and zeroed timestamps, gzip without a timestamp, plus the review-standards self-check above.
- **Non-root by construction.** The image's s6 init needs root to prepare its data paths, so the wrapper prepares them itself and runs the bundled Java controller as `1000:1000`; `/usr/lib/unifi/data` and `/usr/lib/unifi/logs` are bind-mounted from the application data folder so they are writable.
- **Fixed image tag `8.0.24`**, Docker Hub only, no `privileged`, no `network_mode: host`, no `cap_add`, no Docker socket.
- **Multi-port by necessity**: 8013/tcp web UI, 8014/tcp device inform, 8015/udp STUN, 8016/udp discovery. Only the web UI is opened by the App Center.
- **Health check** over HTTPS with `curl -k` (self-signed certificate) and a 300 s start period.

## Runtime file manifest

Everything the application writes on the NAS lives inside its own data
directory; the container-internal `/tmp` is discarded with the container. The
table lists what is created and how it behaves. Nothing else is written.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `config` | working directory of the controller (ace.jar start runs here) | first start | static | kept; contains no user data itself |
| `data/system.properties` | controller properties, including the Java heap limits (MEM_LIMIT/MEM_STARTUP) | first start from the image defaults | static | never overwritten after first run; edit it to change the heap |
| `data/db` | MongoDB database with sites, devices, clients, WiFi configuration and statistics | first start | grows with devices, clients and retained statistics | never delete; it is the controller's whole state |
| `data/keystore` | keys used for device adoption and the controller certificate | first start | static | never delete; without it adopted devices cannot be managed |
| `logs` | controller log files | first start | rotated by the controller | safe to delete |
| `/Volume1/DockerAppData/unificontrollerdocker/config` | UniFi Network Controller application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/unificontrollerdocker/data` | UniFi Network Controller application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/unificontrollerdocker/logs` | UniFi Network Controller application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/unificontrollerdocker/run` | UniFi Network Controller application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |

## Build

```bash
scripts/build.sh                  # -> out/unificontrollerdocker.tar.gz + .sha256
scripts/build.sh 8.0.24-2   # packaging iteration bump
scripts/build.sh 8.0.24-1 aarch64
```

The build stages the four files, substitutes the version/platform placeholders,
embeds `src/entrypoint.sh` into the compose file (escaping every `$` as `$$`), removes CRLF/BOM/AppleDouble, then runs
`tools/verify.py`, a review-standards self-check (archive layout, JSON validity,
required fields, 14+ language coverage, version consistency, Docker-Hub-only
images, fixed tag, reserved/recommended host ports, non-root user, per-service
healthcheck/TZ/restart, data path below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no
literal secrets and the SVG size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/unificontrollerdocker.tar.gz   # official spec check
bash test/install-and-verify.sh                  # on-device E2E (needs root)
```

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (code + README only).
2. Release **tag `v8.0.24-1`**, assets `unificontrollerdocker.tar.gz` +
   `unificontrollerdocker.tar.gz.sha256` (Docker asset naming: `<app_id>.tar.gz`, **no
   platform suffix**).
3. Developer platform → Add Application: ID `unificontrollerdocker`, package type Docker,
   repository URL, architecture `x86_64`.
4. Version Management → Add Version `8.0.24-1` → automated validation → review.

## License / branding

UniFi Network Controller is distributed by its upstream authors under **GPL-3.0**. The container image is the official image from Docker Hub (`linuxserver/unifi-controller:8.0.24`) and is used unmodified; no upstream source code is redistributed here. This packaging is an independent community submission by Moechz and is not affiliated with the upstream project or TerraMaster.

## Limitations

The LinuxServer.io UniFi image is legacy: Ubiquiti moved to the "UniFi Network Application" with an external MongoDB. This package keeps 8.0.24 working but new controller features and updates are not available until the image is rebased.
Devices must be able to reach ports 8014/tcp (inform) and 8016/udp (discovery) on the NAS; if you change the ports in docker-compose.yml, also point the devices at the new inform address.
The UI is HTTPS with a self-signed certificate. Put it behind a TLS reverse proxy if you expose it outside the LAN.

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
