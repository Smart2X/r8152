#!/bin/bash
set -e
export PATH="$TOOLCHAIN_DIR/bin:$PATH"
export CROSS_COMPILE="x86_64-linux-gnueabihf-"  # 按你下载的toolchain实际前缀调整
export ARCH=x86_64
