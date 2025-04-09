#!/bin/bash
set -e

cd /repo/dists/stable/main/binary-all

echo "📦 Generating APT index..."
dpkg-scanpackages . /dev/null > Packages
gzip -9c Packages > Packages.gz

echo "✅ APT index generated:"
ls -lh Packages*