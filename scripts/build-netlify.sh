#!/bin/bash
# Netlify build script for Iris (Flutter web app).
# Installs Flutter SDK on Netlify's Ubuntu build image, then builds the web app.
#
# The GEMINI_API_KEY is NOT passed to the build — it stays server-side in the
# Netlify function. The client uses proxy mode (calls /api/gemini) in production.

set -e

FLUTTER_DIR="$HOME/flutter"
FLUTTER_VERSION="3.41.7"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

echo "=== Iris Netlify Build ==="
echo "Node version: $(node --version 2>/dev/null || echo 'not installed')"
echo "Flutter target: ${FLUTTER_VERSION}"
echo ""

# Install Flutter if not already cached
if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Installing Flutter ${FLUTTER_VERSION}..."
  echo "Downloading from: ${FLUTTER_URL}"
  
  mkdir -p "$HOME"
  curl -fsSL "$FLUTTER_URL" | tar -xJ -C "$HOME"
  
  if [ ! -d "$FLUTTER_DIR" ]; then
    echo "ERROR: Flutter installation failed."
    exit 1
  fi
  
  echo "Flutter installed to ${FLUTTER_DIR}"
else
  echo "Using cached Flutter SDK at ${FLUTTER_DIR}"
fi

# Add Flutter to PATH
export PATH="$FLUTTER_DIR/bin:$PATH"
export PATH="$FLUTTER_DIR/bin/cache/dart-sdk/bin:$PATH"

echo ""
echo "Flutter version:"
flutter --version

echo ""
echo "Installing dependencies..."
flutter pub get

echo ""
echo "Building web app (release mode)..."
flutter build web --release

echo ""
echo "=== Build complete ==="
echo "Output: build/web/"
echo "Functions: netlify/functions/"
echo ""
echo "NOTE: GEMINI_API_KEY is server-side only (in Netlify env vars)."
echo "      The client uses proxy mode (/api/gemini) in production."
