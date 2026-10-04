# rtlsdr-osmocom

> [!IMPORTANT]
> **This repository is archived.** The work continues in [foonerd/rtlsdr-radio](https://github.com/foonerd/rtlsdr-radio), which holds the FM/DAB Radio plugin for Volumio together with the builds of every binary it ships.
>
> The RTL-SDR library and tools (`libfn-rtlsdr0`, `foonerd-rtlsdr`) are built there, in [`components/rtlsdr`](https://github.com/foonerd/rtlsdr-radio/tree/main/components/rtlsdr), from the same upstream, [osmocom/rtl-sdr](https://github.com/osmocom/rtl-sdr). The documentation is in the [wiki](https://github.com/foonerd/rtlsdr-radio/wiki).
>
> It stays available, read-only, as the source of the binaries that earlier versions of the plugin were built from. What follows describes this repository as it was when it was last worked on.

fooNerd custom build of RTL-SDR library and tools from osmocom/rtl-sdr.

## Attribution

- Author: fooNerd (Just a Nerd)
- Source: https://github.com/osmocom/rtl-sdr
- Build system: Custom for Volumio integration
- License: GPL-2.0 (upstream)

## Package Names

- foonerd-rtlsdr (command line tools)
- libfn-rtlsdr0 (shared library)
- libfn-rtlsdr-dev (development files)

## Binary Names

All tools use fn- prefix:
- fn-rtl_fm
- fn-rtl_test
- fn-rtl_power
- fn-rtl_sdr
- fn-rtl_tcp
- fn-rtl_adsb
- fn-rtl_eeprom
- fn-rtl_biast

## Supported Architectures

- armv6 (Raspberry Pi Zero, Pi 1)
- armhf (Raspberry Pi 2, 3)
- arm64 (Raspberry Pi 3, 4, 5)
- amd64 (x86_64)

## Setup

1. Clone repository
2. Copy rtl-sdr-master.zip to package-sources/
3. Make scripts executable:

```bash
chmod +x build-matrix.sh
chmod +x scripts/extract.sh
chmod +x docker/run-docker-rtlsdr.sh
```

## Build All Architectures

```bash
./build-matrix.sh
```

With verbose output:
```bash
./build-matrix.sh --verbose
```

With Volumio package naming:
```bash
./build-matrix.sh --volumio
```

## Build Single Architecture

```bash
./scripts/extract.sh
./docker/run-docker-rtlsdr.sh rtlsdr armhf
```

## Output

DEBs created in out/{arch}/:
- foonerd-rtlsdr_{version}_{arch}.deb
- libfn-rtlsdr0_{version}_{arch}.deb
- libfn-rtlsdr-dev_{version}_{arch}.deb

## Installation

```bash
sudo dpkg -i out/armhf/*.deb
sudo apt-get install -f
```

## Why Custom Build?

- Avoids conflicts with distribution rtl-sdr packages
- Allows side-by-side testing with rtlsdrblog version
- Custom naming for Volumio plugin integration
- Independent version control

## Testing

After installation:
```bash
fn-rtl_test -t
fn-rtl_fm -M fm -f 100.0M - | aplay -r 32k -f S16_LE
```

## Requirements

- Docker with buildx support
- 20GB free disk space
- rtl-sdr-master.zip in package-sources/
