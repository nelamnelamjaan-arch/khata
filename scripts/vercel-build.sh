#!/usr/bin/env bash
# Builds Flutter web for Vercel (root URL, not GitHub Pages subpath).
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Installing Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "${HOME}/flutter"
  export PATH="${HOME}/flutter/bin:${PATH}"
  flutter config --enable-web
  flutter precache --web
fi

if [ ! -f .env ] && [ -f .env.example ]; then
  cp .env.example .env
fi

flutter pub get
flutter build web --release --base-href /
echo "Build output:"
ls -la build/web/
