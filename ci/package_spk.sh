#!/bin/bash
set -e
mkdir -p out
tar -czf out/r8152-dsm-${DSM_VERSION}-${PLATFORM}.tar.gz artifacts/r8152.ko
