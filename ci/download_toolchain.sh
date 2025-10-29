#!/bin/bash
set -e
TOOLCHAIN_URL="$1"
KERNEL_URL="$2"
mkdir -p $HOME/toolchain $HOME/kernel
wget -O $HOME/toolchain/toolchain.tar.gz "$TOOLCHAIN_URL"
tar -xf $HOME/toolchain/toolchain.tar.gz -C $HOME/toolchain
wget -O $HOME/kernel/kernel.tar.gz "$KERNEL_URL"
tar -xf $HOME/kernel/kernel.tar.gz -C $HOME/kernel
echo "TOOLCHAIN_DIR=$HOME/toolchain" >> $GITHUB_ENV
echo "KERNEL_DIR=$HOME/kernel" >> $GITHUB_ENV
