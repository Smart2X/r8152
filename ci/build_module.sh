#!/usr/bin/env bash
# Build kernel module using detected KERNEL_DIR and CROSS_COMPILE
# Usage: build_module.sh
set -euo pipefail

ARTIFACTS_DIR="${ARTIFACTS_DIR:-artifacts}"
LOGFILE="${ARTIFACTS_DIR}/build.log"
mkdir -p "$ARTIFACTS_DIR"

: "${KERNEL_DIR:=${KERNEL_DIR:-}}"
: "${TOOLCHAIN_DIR:=${TOOLCHAIN_DIR:-}}"
: "${CROSS_COMPILE:=${CROSS_COMPILE:-}}"
: "${ARCH:=${ARCH:-x86_64}}"

if [ -z "$KERNEL_DIR" ]; then
  echo "ERROR: KERNEL_DIR not set. Run download_toolchain.sh first."
  exit 1
fi

echo "[build_module] KERNEL_DIR=$KERNEL_DIR"
echo "[build_module] TOOLCHAIN_DIR=${TOOLCHAIN_DIR:-<not set>}"
echo "[build_module] CROSS_COMPILE=${CROSS_COMPILE:-<not set>}"
echo "[build_module] ARCH=$ARCH"
echo "[build_module] Build log: $LOGFILE"

# Apply patches if any
if [ -d patches ] && ls patches/*.patch 1> /dev/null 2>&1; then
  echo "[build_module] Applying patches..."
  for p in patches/*.patch; do
    echo "[build_module] applying $p" | tee -a "$LOGFILE"
    git apply --whitespace=fix "$p" 2>>"$LOGFILE" || { echo "Patch apply failed for $p"; tail -n 80 "$LOGFILE"; exit 1; }
  done
fi

# Run make to build external module
# Use M=$(pwd) to build module in-tree against provided kernel source
MAKE_CMD="make -C \"$KERNEL_DIR\" M=\"$(pwd)\" ARCH=\"$ARCH\" CROSS_COMPILE=\"$CROSS_COMPILE\" modules -j$(nproc)"
echo "[build_module] Running: $MAKE_CMD" | tee -a "$LOGFILE"
# Shell-eval to allow quoted variables
eval $MAKE_CMD 2>&1 | tee -a "$LOGFILE"
MAKE_EXIT=${PIPESTATUS[0]:-0}
if [ "$MAKE_EXIT" -ne 0 ]; then
  echo "[build_module] make failed (exit=$MAKE_EXIT). See $LOGFILE"
  exit $MAKE_EXIT
fi

# Collect built .ko files
echo "[build_module] Collecting .ko files..." | tee -a "$LOGFILE"
find . -type f -name "*.ko" -print -exec cp -v --parents {} "$ARTIFACTS_DIR" \; 2>&1 | tee -a "$LOGFILE" || true

# If r8152.ko exists directly, copy to top-level artifacts
if [ -f "./r8152.ko" ]; then
  cp -v r8152.ko "$ARTIFACTS_DIR/" | tee -a "$LOGFILE" || true
fi

# Show artifacts
echo "[build_module] Artifacts in $ARTIFACTS_DIR:" | tee -a "$LOGFILE"
ls -l "$ARTIFACTS_DIR" | tee -a "$LOGFILE" || true
