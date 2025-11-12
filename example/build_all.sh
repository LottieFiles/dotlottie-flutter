#!/bin/bash
# build_all.sh

echo "Building for Web..."
flutter build web

echo "Building for iOS..."
flutter build ios

echo "Building for macOS..."
flutter build macos

echo "Building for Android..."
flutter build apk

echo "All builds complete!"
