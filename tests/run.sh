#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Keep the offline shell safety suites explicit so none are silently dropped.
shell_suites=(
  tests/structure.sh
  tests/codex-config.sh
  tests/codex-global-config.sh
  tests/checkpoint-config.sh
)

echo "Checking shell syntax..."
for shell_file in install.sh hooks/*.sh tests/*.sh; do
  bash -n "$shell_file"
done

if [[ ! -f tests/checkpoint-config.sh ]]; then
  echo "missing required recovery suite: tests/checkpoint-config.sh" >&2
  exit 1
fi

echo "Running shell suites..."
for suite in "${shell_suites[@]}"; do
  bash "$suite"
done

echo "Running Python unit tests..."
python3 -m unittest discover -s tests -p 'test_*.py'

echo "Offline test suite passed."
