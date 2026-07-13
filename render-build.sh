#!/usr/bin/env bash
# Exit on error
set -e

echo "Downloading Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1

echo "Adding Flutter to PATH..."
export PATH="$PATH:`pwd`/flutter/bin"

echo "Enabling Flutter Web..."
flutter config --enable-web

echo "Getting dependencies..."
flutter pub get

echo "Building Flutter Web..."
flutter build web --release

echo "Copying to backend/public..."
rm -rf backend/public/*
cp -r build/web/* backend/public/

echo "Build complete! The output is in build/web and copied to backend/public"
