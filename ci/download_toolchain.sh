#!/bin/bash
set -euo pipefail
TOOLCHAIN_URL="${1:-}"
KERNEL_URL="${2:-}"
if [ -z "$TOOLCHAIN_URL" ] || [ -z "$KERNEL_URL" ]; then
  echo "Usage: $0 <toolchain_url> <kernel_url>"
  exit 1
fi
mkdir -p "$HOME/toolchain" "$HOME/kernel"
wget -c -L --retry-connrefused --tries=3 -O "$HOME/toolchain/toolchain.tar.gz" "$TOOLCHAIN_URL"
tar -xzf "$HOME/toolchain/toolchain.tar.gz" -C "$HOME/toolchain"
wget -c -L --retry-connrefused --tries=3 -O "$HOME/kernel/kernel.tar.gz" "$KERNEL_URL"
tar -xzf "$HOME/kernel/kernel.tar.gz" -C "$HOME/kernel"
# find actual extracted dirs
TOOLCHAIN_DIR=$(find "$HOME/toolchain" -maxdepth 2 -type d -name bin -print -quit | xargs -I{} dirname {} || true)
if [ -z "$TOOLCHAIN_DIR" ]; then
  # fallback: find first subdir
  TOOLCHAIN_DIR=$(find "$HOME/toolchain" -mindepth 1 -maxdepth 2 -type d -print -quit || true)
fi
[ -z "$TOOLCHAIN_DIR" ] && TOOLCHAIN_DIR="$HOME/toolchain"
KERNEL_DIR=$(find "$HOME/kernel" -maxdepth 3 -type f -name Makefile -print -quit | xargs -I{} dirname {} || true)
if [ -z "$KERNEL_DIR" ]; then
  KERNEL_DIR=$(find "$HOME/kernel" -mindepth 1 -maxdepth 3 -type d -print -quit || true)
fi
[ -z "$KERNEL_DIR" ] && KERNEL_DIR="$HOME/kernel"
echo "Detected TOOLCHAIN_DIR=$TOOLCHAIN_DIR"
echo "Detected KERNEL_DIR=$KERNEL_DIR"
echo "TOOLCHAIN_DIR=$TOOLCHAIN_DIR" >> "$GITHUB_ENV"
echo "KERNEL_DIR=$KERNEL_DIR" >> "$GITHUB_ENV"
