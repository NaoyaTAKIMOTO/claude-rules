#!/bin/bash
# Mac の SessionStart フックから呼ぶ。~/claude-rules を最新にする。
# 標準出力は Claude の文脈に入るので、成功時は何も出さず、失敗時だけ知らせる。
dest="${CLAUDE_RULES_DIR:-$HOME/claude-rules}"
if ! git -C "$dest" pull --ff-only -q >/dev/null 2>&1; then
  echo "共通ルール($dest)の更新に失敗しました。古いルールのままの可能性があることをユーザーに伝えてください。"
fi
exit 0
