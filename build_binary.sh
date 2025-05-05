#!/usr/bin/env bash
set -euo pipefail

# === CONFIGURATION ===
IMAGE_NAME="bitcoin-builder"
OUTPUT_TARBALL="bitcoin-binaries.tar.xz"

# === BUILD THE DOCKER IMAGE ===
echo "[+] Building Docker image..."
docker build -t "$IMAGE_NAME" .

# === EXTRACT ARTIFACT TO HOST ===
echo "[+] Extracting $OUTPUT_TARBALL to current directory..."
docker run --rm -v "$PWD:/out" "$IMAGE_NAME" \
    cp "/artifacts/$OUTPUT_TARBALL" /out/

# === DONE ===
echo "✅ Done. Output: ./$OUTPUT_TARBALL"
