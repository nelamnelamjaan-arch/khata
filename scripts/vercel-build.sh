#!/usr/bin/env bash
# Builds Flutter web for Vercel (root URL). Firebase keys: flutterfire defaults or Vercel env → dart-define.
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

DART_DEFINES=()

_optional_define() {
  local name="$1"
  local value="${2:-}"
  if [ -n "$value" ]; then
    DART_DEFINES+=( "--dart-define=${name}=${value}" )
  fi
}

# Optional — only set in Vercel if you want to override flutterfire defaults
_optional_define "FIREBASE_API_KEY" "${FIREBASE_API_KEY:-}"
_optional_define "FIREBASE_APP_ID" "${FIREBASE_APP_ID:-}"
_optional_define "FIREBASE_MESSAGING_SENDER_ID" "${FIREBASE_MESSAGING_SENDER_ID:-}"
_optional_define "FIREBASE_PROJECT_ID" "${FIREBASE_PROJECT_ID:-}"
_optional_define "FIREBASE_AUTH_DOMAIN" "${FIREBASE_AUTH_DOMAIN:-}"
_optional_define "GEMINI_API_KEY" "${GEMINI_API_KEY:-}"

echo "Building web with defines: ${DART_DEFINES[*]}"
flutter build web --release --base-href / "${DART_DEFINES[@]}"

touch build/web/.nojekyll
echo "Build output:"
ls -la build/web/
