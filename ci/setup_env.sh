#!/usr/bin/env bash
# Setup PATH, ARCH and auto-detect CROSS_COMPILE from $TOOLCHAIN_DIR
# Usage: setup_env.sh  (expects TOOLCHAIN_DIR and KERNEL_DIR in env, or set by download script)
set -euo pipefail

# Ensure TOOLCHAIN_DIR and KERNEL_DIR are set (may come from GITHUB_ENV)
: "${TOOLCHAIN_DIR:=${TOOLCHAIN_DIR:-}}"
: "${KERNEL_DIR:=${KERNEL_DIR:-}}"

if [ -z "${TOOLCHAIN_DIR}" ]; then
  echo "ERROR: TOOLCHAIN_DIR is not set. Run download_toolchain.sh first or export TOOLCHAIN_DIR."
  exit 1
fi

export PATH="$TOOLCHAIN_DIR/bin:$PATH"
export ARCH="${ARCH:-x86_64}"

# Try to detect cross-compiler prefix automatically:
CROSS_COMPILE_DETECTED=""
# look for something like x86_64-linux-gnu-gcc or synology-x64-gcc etc
gcc_candidate=$(ls "$TOOLCHAIN_DIR"/bin/*-gcc 2>/dev/null | head -n1 || true)
if [ -n "$gcc_candidate" ]; then
  gccname=$(basename "$gcc_candidate")
  CROSS_COMPILE_DETECTED="${gccname%gcc}"
else
  # fallback: any gcc in bin
  gcc_candidate2=$(ls "$TOOLCHAIN_DIR"/bin/*gcc 2>/dev/null | head -n1 || true)
  if [ -n "$gcc_candidate2" ]; then
    gccname2=$(basename "$gcc_candidate2")
    # try to strip suffix like 'gcc' or 'synogcc'
    CROSS_COMPILE_DETECTED="${gccname2%gcc}"
  fi
fi

if [ -n "${CROSS_COMPILE:-}" ]; then
  export CROSS_COMPILE="$CROSS_COMPILE"
elif [ -n "$CROSS_COMPILE_DETECTED" ]; then
  export CROSS_COMPILE="$CROSS_COMPILE_DETECTED"
else
  # Default for Geminilake/x86_64 if detection fails
  export CROSS_COMPILE="${CROSS_COMPILE:-x86_64-linux-gnu-}"
fi

echo "[setup_env] PATH updated with $TOOLCHAIN_DIR/bin"
echo "[setup_env] ARCH=$ARCH"
echo "[setup_env] CROSS_COMPILE=$CROSS_COMPILE"

# Print some diagnostics
echo "[setup_env] Compiler check:"
"$TOOLCHAIN_DIR/bin/${CROSS_COMPILE}gcc" --version 2>/dev/null || true

# Export to GitHub Actions env if present
if [ -n "${GITHUB_ENV:-}" ]; then
  echo "CROSS_COMPILE=$CROSS_COMPILE" >> "$GITHUB_ENV"
  echo "ARCH=$ARCH" >> "$GITHUB_ENV"
fi
