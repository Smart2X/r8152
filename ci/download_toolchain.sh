#!/usr/bin/env bash
# Download and unpack Synology toolchain and kernel archive, detect actual directories
# Usage: download_toolchain.sh <toolchain_url> <kernel_url>
set -euo pipefail

TOOLCHAIN_URL="${1:-}"
KERNEL_URL="${2:-}"

if [ -z "$TOOLCHAIN_URL" ] || [ -z "$KERNEL_URL" ]; then
  echo "Usage: $0 <toolchain_url> <kernel_url>"
  exit 1
fi

echo "[download_toolchain] TOOLCHAIN_URL=$TOOLCHAIN_URL"
echo "[download_toolchain] KERNEL_URL=$KERNEL_URL"

mkdir -p "$HOME/toolchain" "$HOME/kernel" "$HOME/.cache/ci_download"
TC_ARCHIVE="$HOME/.cache/ci_download/toolchain_archive"
KER_ARCHIVE="$HOME/.cache/ci_download/kernel_archive"

# Download with basic retry and follow redirects
wget -c -L --tries=3 --timeout=30 -O "$TC_ARCHIVE" "$TOOLCHAIN_URL"
wget -c -L --tries=3 --timeout=30 -O "$KER_ARCHIVE" "$KERNEL_URL"

# Extract (use tar -xf to accept various compressions like .tar.gz .txz .tar.bz2)
tar -xf "$TC_ARCHIVE" -C "$HOME/toolchain"
tar -xf "$KER_ARCHIVE" -C "$HOME/kernel"

# Detect actual extracted toolchain dir (the one that contains bin/)
TOOLCHAIN_DIR=""
# search up to depth 3 for a bin directory
found_bin_dir=$(find "$HOME/toolchain" -maxdepth 3 -type d -name bin -print -quit || true)
if [ -n "$found_bin_dir" ]; then
  TOOLCHAIN_DIR=$(dirname "$found_bin_dir")
else
  # fallback to first subdir
  TOOLCHAIN_DIR=$(find "$HOME/toolchain" -mindepth 1 -maxdepth 2 -type d -print -quit || true)
fi
TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-$HOME/toolchain}"

# Detect kernel source dir (look for top-level Makefile)
KERNEL_DIR=""
found_kern_make=$(find "$HOME/kernel" -maxdepth 5 -type f -name Makefile -print -quit || true)
if [ -n "$found_kern_make" ]; then
  KERNEL_DIR=$(dirname "$found_kern_make")
else
  KERNEL_DIR=$(find "$HOME/kernel" -mindepth 1 -maxdepth 3 -type d -print -quit || true)
fi
KERNEL_DIR="${KERNEL_DIR:-$HOME/kernel}"

echo "[download_toolchain] Detected TOOLCHAIN_DIR=$TOOLCHAIN_DIR"
echo "[download_toolchain] Detected KERNEL_DIR=$KERNEL_DIR"

# Export for GitHub Actions
if [ -n "${GITHUB_ENV:-}" ]; then
  echo "TOOLCHAIN_DIR=$TOOLCHAIN_DIR" >> "$GITHUB_ENV"
  echo "KERNEL_DIR=$KERNEL_DIR" >> "$GITHUB_ENV"
else
  # Not running in GH Actions: print exports for manual consumption
  echo "Export the following before running build:"
  echo "export TOOLCHAIN_DIR=$TOOLCHAIN_DIR"
  echo "export KERNEL_DIR=$KERNEL_DIR"
fi
