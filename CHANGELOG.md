# Changelog

All notable user-visible changes to the UniFi Network Controller TOS application package.

## 8.0.24-2 — 2026-11-12

### Changed
- Icon: replaced the letter monogram with a functional vector mark that describes what the app does (the upstream project does not publish a compliant SVG).

## 8.0.24-1 — 2026-11-08

### Added
- First release. UniFi Network Controller (`linuxserver/unifi-controller:8.0.24`, Docker Hub official image, unmodified)
  packaged as a TOS 7 Docker application, published on port 8013 and running
  as a non-root user (1000:1000).
- Persistent data is kept under `/Volume1/DockerAppData/unificontrollerdocker/`.
