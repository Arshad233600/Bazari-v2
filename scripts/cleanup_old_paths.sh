#!/usr/bin/env bash
set -e
[ -d lib/search ] && rm -rf lib/search
[ -d lib/seller ] && rm -rf lib/seller
[ -f lib/data/product.dart ] && rm -f lib/data/product.dart
echo "Cleanup done."
