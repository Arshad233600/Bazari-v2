#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-.}"

DEST_DIR="$PROJECT_ROOT/lib/app/i18n"
OLD_PATH="$PROJECT_ROOT/lib/core/i18n/i18n.dart"
NEW_PATH="$PROJECT_ROOT/lib/app/i18n/i18n.dart"
TPL="$PROJECT_ROOT/templates/app_i18n_i18n.dart"

mkdir -p "$DEST_DIR"

# 1) Move existing i18n if present
if [ -f "$OLD_PATH" ]; then
  mv -f "$OLD_PATH" "$NEW_PATH"
fi

# 2) If new i18n.dart is missing, copy template
if [ ! -f "$NEW_PATH" ] && [ -f "$TPL" ]; then
  cp -f "$TPL" "$NEW_PATH"
fi

# 3) Replace imports across lib
while IFS= read -r -d '' file; do
  sed -i \
    -e "s#import \(['\"]\)core/i18n/i18n\.dart\1;#import 'package:bazari_8656/app/i18n/i18n.dart';#g" \
    -e "s#import \(['\"]\)package:bazari_8656/core/i18n/i18n\.dart\1;#import 'package:bazari_8656/app/i18n/i18n.dart';#g" \
    "$file"
done < <(find "$PROJECT_ROOT/lib" -type f -name "*.dart" -print0)

# 4) Ensure main.dart includes AppLang + AnimatedBuilder
MAIN="$PROJECT_ROOT/lib/main.dart"
if [ -f "$MAIN" ]; then
  if ! grep -q "app/i18n/i18n.dart" "$MAIN"; then
    sed -i "0,/import 'package:flutter\/material.dart';/s//import 'package:flutter\/material.dart';\nimport 'package:bazari_8656\/app\/i18n\/i18n.dart';/" "$MAIN"
  fi

  if ! grep -q "AnimatedBuilder(animation: AppLang.instance" "$MAIN"; then
    # Replace first 'return MaterialApp(' with AnimatedBuilder wrapper
    sed -i "0,/return MaterialApp(/s//return AnimatedBuilder(animation: AppLang.instance, builder: (context, _) => MaterialApp(/" "$MAIN"
    # Close the AnimatedBuilder at the end of build: replace final ');' with '));'
    # This is a heuristic for typical structure.
    awk 'BEGIN{changed=0} { if (!changed && $$0 ~ /\)\s*;\s*$/) { sub(/\)\s*;\s*$/, "));"); changed=1 } print }' "$MAIN" > "$MAIN.tmp" && mv "$MAIN.tmp" "$MAIN"
  fi
fi

echo "✔ i18n path fix applied."
echo "Next:"
echo "  flutter clean && flutter pub get && flutter analyze && flutter run -d chrome"
