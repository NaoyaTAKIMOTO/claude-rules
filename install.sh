#!/bin/bash
# Mac(ローカル)用の導入スクリプト。何度実行してもよい。
# 1. ~/claude-rules にリポジトリを複製する(あれば最新にする)
# 2. ~/.claude/CLAUDE.md の末尾に取り込み行を足す(既存の内容は残す)
set -eu
repo="${CLAUDE_RULES_REPO:-https://github.com/NaoyaTAKIMOTO/claude-rules.git}"
dest="$HOME/claude-rules"
line='@~/claude-rules/CLAUDE.md'
target="$HOME/.claude/CLAUDE.md"

if [ -d "$dest/.git" ]; then
  git -C "$dest" pull --ff-only -q
else
  git clone -q "$repo" "$dest"
fi

mkdir -p "$HOME/.claude"
touch "$target"
if ! grep -qxF "$line" "$target"; then
  # 末尾に改行がなければ、取り込み行が既存の行とつながらないよう改行を足す
  if [ -s "$target" ] && [ "$(tail -c 1 "$target")" != "" ]; then echo >> "$target"; fi
  echo "$line" >> "$target"
fi
echo "完了: $target から $dest/CLAUDE.md を取り込みます"
