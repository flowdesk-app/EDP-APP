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

echo "Installing Python biometric dependencies..."
pip3 install --break-system-packages -r backend/requirements.txt || pip install -r backend/requirements.txt || python3 -m pip install -r backend/requirements.txt || true

echo "Installing backend Node dependencies..."
cd backend && npm install && cd ..

echo "Building Flutter Web..."
flutter build web --release

echo "Copying to backend/public..."
rm -rf backend/public/*
cp -r build/web/* backend/public/

echo "Ensuring biometric face photos exist in public uploads..."
mkdir -p backend/public/uploads/faces
cp -r assets/images/faces/* backend/public/uploads/faces/ 2>/dev/null || true

echo "Build complete! The output is in build/web and copied to backend/public"
