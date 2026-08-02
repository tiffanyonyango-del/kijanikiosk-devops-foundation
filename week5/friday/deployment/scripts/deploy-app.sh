#!/bin/bash

set -e

# Find the repository root relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SOURCE_DIR="$REPO_ROOT/app"
TARGET_DIR="/opt/kijanikiosk/app"

echo "===================================="
echo "KijaniKiosk Deployment"
echo "===================================="

echo "Source: $SOURCE_DIR"
echo "Target: $TARGET_DIR"

echo ""
echo "Cleaning previous deployment..."
sudo rm -rf "$TARGET_DIR"/*

echo "Copying application..."
sudo cp -r "$SOURCE_DIR"/* "$TARGET_DIR"

cd "$TARGET_DIR"

echo "Installing production dependencies..."
sudo npm install --omit=dev

echo ""
echo "Deployment completed successfully!"