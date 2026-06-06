#!/bin/bash
# test/ 配下の test_*.sh を順に実行する。
HERE="$(cd "$(dirname "$0")" && pwd)"
rc=0
for t in "$HERE"/test_*.sh; do
  echo "=== $(basename "$t") ==="
  bash "$t" || rc=1
  echo
done
exit "$rc"
