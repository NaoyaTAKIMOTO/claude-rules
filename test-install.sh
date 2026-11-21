#!/usr/bin/env bash
# install.sh の試験。ローカルの複製元と一時的な HOME を使う。
set -u
cd "$(dirname "$0")"
fail=0
work=$(mktemp -d) || exit 1
trap 'rm -rf -- "${work:?}"' EXIT
line='@~/claude-rules/CLAUDE.md'

# 複製元のリポジトリを用意する
src="$work/src"
mkdir -p "$src" && cp CLAUDE.md "$src/"
git -C "$src" init -q -b main
git -C "$src" -c user.name=t -c user.email=t@example.com add CLAUDE.md
git -C "$src" -c user.name=t -c user.email=t@example.com commit -qm init

inst() { HOME="$1" CLAUDE_RULES_REPO="$src" bash install.sh >/dev/null 2>&1; }

# (a) 既存の CLAUDE.md(末尾に改行なし)がある場合。2回実行する
home="$work/a"
mkdir -p "$home/.claude" && printf '既存の設定' > "$home/.claude/CLAUDE.md"
inst "$home" || { echo "NG(a): 1回目が失敗"; fail=1; }
inst "$home" || { echo "NG(a): 2回目が失敗"; fail=1; }
grep -qxF '既存の設定' "$home/.claude/CLAUDE.md" || { echo "NG(a): 既存の行が残っていない"; fail=1; }
n=$(grep -cxF "$line" "$home/.claude/CLAUDE.md")
[ "$n" = 1 ] || { echo "NG(a): import 行が $n 行"; fail=1; }
cmp -s CLAUDE.md "$home/claude-rules/CLAUDE.md" || { echo "NG(a): 複製の本文が一致しない"; fail=1; }

# (b) ~/.claude がない場合
home="$work/b"
mkdir -p "$home"
inst "$home" || { echo "NG(b): 失敗"; fail=1; }
[ "$(cat "$home/.claude/CLAUDE.md" 2>/dev/null)" = "$line" ] || { echo "NG(b): import 行だけの内容になっていない"; fail=1; }

[ "$fail" -eq 0 ] && echo OK
exit "$fail"
