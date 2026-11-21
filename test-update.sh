#!/usr/bin/env bash
# update.sh(Mac の SessionStart フックから呼ぶ)の試験。
set -u
cd "$(dirname "$0")"
fail=0
work=$(mktemp -d) || exit 1
trap 'rm -rf -- "${work:?}"' EXIT
g() { git -c user.name=t -c user.email=t@example.com "$@"; }

src="$work/src"
mkdir -p "$src" && cp CLAUDE.md "$src/"
g -C "$src" init -q -b main && g -C "$src" add CLAUDE.md && g -C "$src" commit -qm init
g clone -q "$src" "$work/clone"

# (a) 更新できたときは何も出力しない(出力は Claude の文脈に入るため)
out=$(CLAUDE_RULES_DIR="$work/clone" bash update.sh); code=$?
[ "$code" = 0 ] || { echo "NG(a): 終了コード $code"; fail=1; }
[ -z "$out" ] || { echo "NG(a): 出力がある: $out"; fail=1; }

# (b) 更新に失敗したときは、ユーザーに伝えるよう標準出力で知らせる
mkdir -p "$work/not-a-repo"
out=$(CLAUDE_RULES_DIR="$work/not-a-repo" bash update.sh); code=$?
[ "$code" = 0 ] || { echo "NG(b): 終了コード $code"; fail=1; }
echo "$out" | grep -qF "更新に失敗しました" || { echo "NG(b): 失敗の知らせがない"; fail=1; }

[ "$fail" -eq 0 ] && echo OK
exit "$fail"
