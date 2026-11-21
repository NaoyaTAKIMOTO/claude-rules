#!/usr/bin/env bash
# setup-cloud.sh の試験。RULES_URL を差し替え、一時的な HOME で3通りを確かめる。
set -u
cd "$(dirname "$0")"
fail=0
work=$(mktemp -d) || exit 1
trap 'rm -rf -- "${work:?}"' EXIT

run() { # $1=試験名 $2=URL
  local home="$work/$1"
  mkdir -p "$home"
  HOME="$home" RULES_URL="$2" bash setup-cloud.sh >/dev/null 2>&1
  echo $?
}

# (a) 取得に成功したら、本文と同一のファイルになる
code=$(run ok "file://$PWD/CLAUDE.md")
[ "$code" = 0 ] || { echo "NG(a): 終了コード $code"; fail=1; }
cmp -s CLAUDE.md "$work/ok/.claude/CLAUDE.md" || { echo "NG(a): 本文と一致しない"; fail=1; }

# (b) 取得先がないときは、失敗を知らせる本文になり、終了コードは 0
code=$(run missing "file://$work/no-such-file.md")
[ "$code" = 0 ] || { echo "NG(b): 終了コード $code"; fail=1; }
grep -qF "共通ルールの取得に失敗しました" "$work/missing/.claude/CLAUDE.md" 2>/dev/null \
  || { echo "NG(b): 失敗の知らせがない"; fail=1; }

# (c) 中身が空のときも (b) と同じ
: > "$work/empty.md"
code=$(run empty "file://$work/empty.md")
[ "$code" = 0 ] || { echo "NG(c): 終了コード $code"; fail=1; }
grep -qF "共通ルールの取得に失敗しました" "$work/empty/.claude/CLAUDE.md" 2>/dev/null \
  || { echo "NG(c): 失敗の知らせがない"; fail=1; }

[ "$fail" -eq 0 ] && echo OK
exit "$fail"
