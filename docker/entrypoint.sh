#!/bin/bash
set -e

cd /repo/dists/stable/main/binary-all

echo "📦 Generating APT index for all..."
dpkg-scanpackages . /dev/null | sed 's|^Filename: ./|Filename: dists/stable/main/binary-all/|' > Packages
gzip -9c Packages > Packages.gz
echo "✅ APT index generated:"
ls -lh Packages*

cd /repo/dists/stable/main/binary-arm64
echo "📦 Generating APT index for arm64..."
dpkg-scanpackages . /dev/null | sed 's|^Filename: ./|Filename: dists/stable/main/binary-arm64/|' > Packages
gzip -9c Packages > Packages.gz

echo "✅ APT index generated:"
ls -lh Packages*