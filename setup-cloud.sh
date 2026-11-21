#!/bin/bash
# クラウド環境のセットアップスクリプト。共通ルールの正本を取得して ~/.claude/CLAUDE.md に置く。
# 失敗してもセッションの起動を止めないよう、常に終了コード 0 で終える。
url="${RULES_URL:-https://raw.githubusercontent.com/NaoyaTAKIMOTO/claude-rules/main/CLAUDE.md}"
dir="${HOME:-/root}/.claude"
mkdir -p "$dir" || exit 0
tmp="$dir/CLAUDE.md.tmp"
if curl -fsSL --max-time 20 "$url" -o "$tmp" && [ -s "$tmp" ]; then
  mv -f "$tmp" "$dir/CLAUDE.md"
else
  rm -f "$tmp"
  cat > "$dir/CLAUDE.md" <<'EOF'
# 共通ルールの取得に失敗しました
作業を始める前に、このことをユーザーに伝えてください。
取得元: https://raw.githubusercontent.com/NaoyaTAKIMOTO/claude-rules/main/CLAUDE.md
EOF
fi
exit 0
