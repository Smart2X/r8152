#!/usr/bin/env bash
# Package built .ko into a simple tarball with install/uninstall helper scripts and README.
# This is a minimal test-package (not a full signed SPK). Use on your NAS for manual install.
# Usage: package_spk.sh  (reads DSM_VERSION and PLATFORM from env or defaults)
set -euo pipefail

DSM_VERSION="${DSM_VERSION:-7.3}"
PLATFORM="${PLATFORM:-geminilake}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-artifacts}"
OUT_DIR="${OUT_DIR:-out}"
PKGNAME="r8152-dsm-${DSM_VERSION}-${PLATFORM}"

mkdir -p "$OUT_DIR"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# copy ko(s) into package dir
mkdir -p "$TMPDIR"/package
if [ ! -d "$ARTIFACTS_DIR" ]; then
  echo "ERROR: artifacts dir '$ARTIFACTS_DIR' not found. Run build_module.sh first."
  exit 1
fi

# copy *.ko (preserve basename)
shopt -s nullglob
KO_FILES=("$ARTIFACTS_DIR"/*.ko)
if [ ${#KO_FILES[@]} -eq 0 ]; then
  echo "ERROR: no .ko files found in $ARTIFACTS_DIR"
  exit 1
fi
mkdir -p "$TMPDIR/package/ko"
for k in "${KO_FILES[@]}"; do
  cp -v "$k" "$TMPDIR/package/ko/"
done

# create a simple install script that should be run on the NAS (as root)
cat > "$TMPDIR/package/install.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
KO_DIR="./ko"
# Destination module dir on NAS
KVER="$(uname -r)"
DEST="/lib/modules/$KVER/extra"
mkdir -p "$DEST"
echo "Copying kernel modules to $DEST"
cp -v "$KO_DIR"/*.ko "$DEST/"
depmod -a || true
echo "Loading module(s)"
for m in "$DEST"/*.ko; do
  modname=$(basename "$m" .ko)
  if lsmod | grep -q "^$modname "; then
    echo "$modname already loaded"
  else
    modprobe "$modname" || /sbin/insmod "$m" || true
  fi
done
echo "Install complete. Check dmesg for driver messages."
EOF
chmod +x "$TMPDIR/package/install.sh"

# uninstall script
cat > "$TMPDIR/package/uninstall.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
KVER="$(uname -r)"
DEST="/lib/modules/$KVER/extra"
for m in "$DEST"/*.ko; do
  modname=$(basename "$m" .ko)
  if lsmod | grep -q "^$modname "; then
    echo "Removing module $modname"
    modprobe -r "$modname" || /sbin/rmmod "$modname" || true
  fi
done
echo "Removing module files from $DEST"
rm -f "$DEST"/*.ko || true
depmod -a || true
echo "Uninstall complete."
EOF
chmod +x "$TMPDIR/package/uninstall.sh"

# README
cat > "$TMPDIR/package/README.txt" <<EOF
This archive contains built r8152 kernel module(s) and simple install/uninstall scripts.
Usage (on target Synology NAS, as root):
  1. Upload and extract this archive on the NAS.
  2. Run: sudo ./install.sh
  3. Check: dmesg, lsmod, ip link, ethtool -i <iface>

Note: This is a minimal manual installer, not a signed SPK. For SPK packaging follow Synology SPK spec.
EOF

# Create the package tarball
pushd "$TMPDIR/package" > /dev/null
TARBALL="$OUT_DIR/${PKGNAME}.tar.gz"
tar -czf "$TARBALL" ./*
popd > /dev/null

echo "Package created: $TARBALL"
ls -lh "$TARBALL"
