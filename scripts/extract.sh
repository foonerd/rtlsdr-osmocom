#!/bin/bash
set -e

if [[ ! -d "package-sources" ]]; then
  echo "Error: Run from repository root"
  exit 1
fi

SOURCE_ZIP="package-sources/rtl-sdr-master.zip"

if [[ ! -f "$SOURCE_ZIP" ]]; then
  echo "Error: $SOURCE_ZIP not found"
  exit 1
fi

DEST_DIR="build/rtlsdr/source"

echo "[+] Cleaning $DEST_DIR"
rm -rf "$DEST_DIR"
mkdir -p "$DEST_DIR"

echo "[+] Extracting rtl-sdr source"
unzip -q "$SOURCE_ZIP" -d /tmp/
mv /tmp/rtl-sdr-master/* "$DEST_DIR"/
rm -rf /tmp/rtl-sdr-master

echo "[+] Modifying debian packaging for fooNerd"

cd "$DEST_DIR"

# Patch src/CMakeLists.txt - replace ALL rtlsdr references
echo "[+] Patching src/CMakeLists.txt for fn-rtlsdr library name"
sed -i 's/\brtlsdr_static\b/fn-rtlsdr_static/g' src/CMakeLists.txt
sed -i 's/\brtlsdr\b/fn-rtlsdr/g' src/CMakeLists.txt
sed -i 's/OUTPUT_NAME fn-rtlsdr/OUTPUT_NAME fn-rtlsdr/g' src/CMakeLists.txt

# Patch librtlsdr.pc.in
sed -i 's/Name: librtlsdr/Name: libfn-rtlsdr/g' librtlsdr.pc.in
sed -i 's/Libs: -L\${libdir} -lrtlsdr/Libs: -L\${libdir} -lfn-rtlsdr/g' librtlsdr.pc.in

# Modify debian/control
cat > debian/control << 'EOF'
Source: foonerd-rtlsdr
Section: comm
Priority: optional
Maintainer: fooNerd (Just a Nerd) <nerd@foonerd.com>
Build-Depends: cmake,
               debhelper (>= 10~),
               libusb-1.0-0-dev,
               pkg-config
Standards-Version: 4.1.4
Homepage: https://github.com/foonerd/rtlsdr-osmocom

Package: libfn-rtlsdr-dev
Section: libdevel
Architecture: any
Depends: libfn-rtlsdr0 (= ${binary:Version}),
         libusb-1.0-0-dev,
         ${misc:Depends}
Description: fooNerd RTL-SDR library (development files)
 Software defined radio receiver for Realtek RTL2832U.
 Custom build by fooNerd for Volumio integration.
 .
 This package contains development files.

Package: libfn-rtlsdr0
Section: libs
Architecture: any
Depends: ${misc:Depends}, ${shlibs:Depends}
Description: fooNerd RTL-SDR library (shared library)
 Software defined radio receiver for Realtek RTL2832U.
 Custom build by fooNerd for Volumio integration.
 .
 This package contains the shared library.

Package: foonerd-rtlsdr
Architecture: any
Depends: libfn-rtlsdr0 (= ${binary:Version}), ${misc:Depends}, ${shlibs:Depends}
Description: fooNerd RTL-SDR tools
 Software defined radio receiver for Realtek RTL2832U.
 Custom build by fooNerd for Volumio integration.
 .
 Command line utilities with fn- prefix:
  * fn-rtl_adsb: ADS-B decoder
  * fn-rtl_eeprom: EEPROM programming tool
  * fn-rtl_fm: FM demodulator
  * fn-rtl_sdr: I/Q recorder
  * fn-rtl_tcp: I/Q spectrum server
  * fn-rtl_test: benchmark tool
  * fn-rtl_power: spectrum analyzer
  * fn-rtl_biast: bias tee control
EOF

# Modify debian/rules
cat > debian/rules << 'EOF'
#!/usr/bin/make -f
DEB_HOST_MULTIARCH ?= $(shell dpkg-architecture -qDEB_HOST_MULTIARCH)
export DEB_HOST_MULTIARCH

%:
	dh $@ --buildsystem=cmake

override_dh_auto_configure: debian/libfn-rtlsdr0.udev
	dh_auto_configure --buildsystem=cmake -- \
		-DCMAKE_CROSSCOMPILING=TRUE \
		-DTHREADS_PTHREAD_ARG=0 \
		-DCMAKE_THREAD_LIBS_INIT=-lpthread \
		-DCMAKE_HAVE_THREADS_LIBRARY=1 \
		-DCMAKE_USE_PTHREADS_INIT=1 \
		-DDETACH_KERNEL_DRIVER=ON \
		-DINSTALL_UDEV_RULES=ON \
		-DCMAKE_BUILD_TYPE=RelWithDebInfo

debian/libfn-rtlsdr0.udev: rtl-sdr.rules
	cp -p rtl-sdr.rules debian/libfn-rtlsdr0.udev

override_dh_auto_install:
	dh_auto_install
	# Rename binaries to fn-* prefix
	cd debian/tmp/usr/bin && \
	for f in rtl_*; do \
		mv "$$f" "fn-$$f"; \
	done
	# Rename pkg-config file
	cd debian/tmp/usr/lib/*/pkgconfig && \
	mv librtlsdr.pc libfn-rtlsdr.pc

override_dh_fixperms:
	dh_fixperms || true

override_dh_install:
	dh_install
EOF

chmod +x debian/rules

# Update install files
cat > debian/libfn-rtlsdr0.install << 'EOF'
usr/lib/*/libfn-rtlsdr.so.*
EOF

cat > debian/libfn-rtlsdr-dev.install << 'EOF'
usr/include
usr/lib/*/libfn-rtlsdr.so
usr/lib/*/libfn-rtlsdr.a
usr/lib/*/pkgconfig/libfn-rtlsdr.pc
EOF

cat > debian/foonerd-rtlsdr.install << 'EOF'
usr/bin/fn-rtl_*
EOF

# Rename udev and maintscript files
if [ -f debian/librtlsdr0.maintscript ]; then
  mv debian/librtlsdr0.maintscript debian/libfn-rtlsdr0.maintscript
fi

# Update changelog
cat > debian/changelog << 'EOF'
foonerd-rtlsdr (1.0.0-1) bookworm; urgency=medium

  * Initial fooNerd release
  * Custom build from osmocom/rtl-sdr source
  * Binary prefix: fn-*
  * Library name: libfn-rtlsdr0
  * For Volumio RTL-SDR Radio plugin

 -- fooNerd (Just a Nerd) <nerd@foonerd.com>  Sat, 23 Nov 2024 10:00:00 +0000
EOF

cd - > /dev/null

echo "[OK] Source prepared in $DEST_DIR"
