#!/usr/bin/env bash
# 使い方: bash check.sh CLAUDE.md | bash check.sh setup.sh
# CLAUDE.md とセットアップスクリプトが上限と必須項目を満たすか検査する。
set -u
f=${1:?file required}
[ -f "$f" ] || { echo "NG: $f がない"; exit 1; }

case "$f" in
  *.md) max_lines=90;  max_bytes=190 ;;
  *.sh) max_lines=100; max_bytes=200 ;;
  *) echo "NG: 拡張子は .md か .sh"; exit 1 ;;
esac

fail=0
lines=$(wc -l < "$f")
[ "$lines" -le "$max_lines" ] || { echo "NG: 行数 $lines > $max_lines"; fail=1; }

# LC_ALL=C で length() をバイト数として数える
LC_ALL=C awk -v m="$max_bytes" '
  length($0) > m { printf "NG: %d行目 %dバイト > %d\n", NR, length($0), m; bad = 1 }
  END { exit bad }' "$f" || fail=1

if LC_ALL=C grep -q $'\r' "$f"; then echo "NG: CR を含む"; fail=1; fi

if [[ "$f" == *.md ]]; then
  for kw in 大目的 先行事例 合意 docs/plans/ docs/log.md docs/status.html テストファースト コミット \
            失敗したときの出力 緩めない サブエージェント スクショ main dev feat e2e "GitHub Actions" Mac \
            セキュリティ リファクタリング 定数 承認; do
    grep -qF -- "$kw" "$f" || { echo "NG: 必須語「$kw」がない"; fail=1; }
  done
fi

[ "$fail" -eq 0 ] && echo OK
exit "$fail"
