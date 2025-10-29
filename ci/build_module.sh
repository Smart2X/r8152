#!/bin/bash
set -e
make -C "$KERNEL_DIR" M="$PWD" modules ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE"
mkdir -p artifacts
cp r8152.ko artifacts/
