#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Keep the existing offline shell safety suites explicit so none are silently
# dropped. Task 3's checkpoint suite joins this list automatically when present.
shell_suites=(
  tests/structure.sh
  tests/codex-config.sh
  tests/codex-global-config.sh
)
checkpoint_suite=tests/checkpoint-config.sh

echo "Checking shell syntax..."
bash -n install.sh tests/*.sh

echo "Running shell suites..."
for suite in "${shell_suites[@]}"; do
  bash "$suite"
done

if [[ -f "$checkpoint_suite" ]]; then
  bash "$checkpoint_suite"
else
  echo "SKIP: $checkpoint_suite is not present yet (Task 3 deliverable)."
fi

echo "Running Python unit tests..."
python3 -m unittest discover -s tests -p 'test_*.py'

echo "Offline test suite passed."
