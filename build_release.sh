#!/usr/bin/env bash
set -e

# Usage:
#   export FIREBASE_API_KEY=xxx
#   export FIREBASE_APP_ID=xxx
#   export FIREBASE_MESSAGING_SENDER_ID=xxx
#   export FIREBASE_PROJECT_ID=xxx
#   export FIREBASE_STORAGE_BUCKET=xxx
#   export LICENSE_HASH=xxx          # sha256(key + salt)
#   export LICENSE_SALT=xxx
#   export MP_PUBLIC_KEY=xxx
#   export MP_ACCESS_TOKEN=xxx
#   bash build_release.sh

echo "==> Running flutter analyze..."
flutter analyze

echo "==> Running flutter test..."
flutter test

DEFINES=(
  "--dart-define=FIREBASE_API_KEY=${FIREBASE_API_KEY}"
  "--dart-define=FIREBASE_APP_ID=${FIREBASE_APP_ID}"
  "--dart-define=FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID}"
  "--dart-define=FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}"
  "--dart-define=FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET}"
  "--dart-define=LICENSE_HASH=${LICENSE_HASH}"
  "--dart-define=LICENSE_SALT=${LICENSE_SALT}"
  "--dart-define=MP_PUBLIC_KEY=${MP_PUBLIC_KEY}"
  "--dart-define=MP_ACCESS_TOKEN=${MP_ACCESS_TOKEN}"
)

echo "==> Building Android APK (release)..."
flutter build apk --release "${DEFINES[@]}"

echo "==> Build complete."
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
