#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
flutter build ipa --release --tree-shake-icons "$@"
