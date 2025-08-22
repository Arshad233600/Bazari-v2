#!/usr/bin/env bash
set -euo pipefail
flutter pub get
flutter analyze
flutter test
echo "✅ Build verify passed"