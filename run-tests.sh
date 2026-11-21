#!/usr/bin/env bash
# すべての検査と試験を実行する。GitHub Actions からも使う。
set -u
cd "$(dirname "$0")"
fail=0
for t in "check.sh CLAUDE.md" "check.sh setup-cloud.sh" "test-setup-cloud.sh" "test-install.sh"; do
  set -- $t
  if [ ! -f "$1" ]; then echo "SKIP: $1 がない"; continue; fi
  if out=$(bash "$@" 2>&1); then echo "PASS: $t"; else echo "FAIL: $t"; echo "$out"; fail=1; fi
done
exit "$fail"
