# claude-rules

Claude Code の共通作業ルール(`CLAUDE.md`)の正本です。クラウドとローカル(Mac)の両方が、このリポジトリの main から取り込みます。

## Mac での設定

1. 導入スクリプトを実行します。何度実行しても大丈夫です。既存の `~/.claude/CLAUDE.md` の内容は残り、末尾に取り込み行 `@~/claude-rules/CLAUDE.md` が1行だけ足されます。

   ```bash
   git clone https://github.com/NaoyaTAKIMOTO/claude-rules.git ~/claude-rules
   ```

   ```bash
   bash ~/claude-rules/install.sh
   ```

2. セッション開始のたびに最新版を取り込むよう、`~/.claude/settings.json` にフックを足します。既存の設定がある場合は `hooks` の中に統合してください。Mac の Claude Code に「claude-rules の README にある SessionStart フックを追加して」と頼んでもかまいません。

   ```json
   {
     "hooks": {
       "SessionStart": [
         {
           "hooks": [
             { "type": "command", "command": "bash ~/claude-rules/update.sh", "timeout": 15 }
           ]
         }
       ]
     }
   }
   ```

   直した内容は、次のセッションから効きます。`update.sh` は更新に失敗したときだけ、そのことを Claude に知らせます(Claude からあなたに伝わります)。`~/claude-rules` で直したまま commit と push をしないでいると、更新が失敗することがあります。

## クラウドでの設定

クラウド環境のセットアップスクリプトに、`setup-cloud.sh` の内容をそのまま貼ります。新しいセッションを始めるたびに、main の `CLAUDE.md` が `~/.claude/CLAUDE.md` に書き出されます。取得に失敗したときは、そのことをユーザーに伝えるよう書いた短いファイルになります。どちらの場合もセッションは起動します。

## ルールの直し方

1. `CLAUDE.md` を直す
2. `bash run-tests.sh` を実行し、すべて PASS になることを確かめる
3. main にコミットして push する(このリポジトリだけは、ブランチと e2e の決まりの対象外)

push すると GitHub Actions でも同じ検査が動きます。

## ファイル

| ファイル | 役割 |
|---|---|
| `CLAUDE.md` | ルール本文(正本) |
| `setup-cloud.sh` | クラウド環境のセットアップスクリプト |
| `install.sh` | Mac 用の導入スクリプト |
| `update.sh` | Mac の SessionStart フックから呼ぶ更新スクリプト |
| `check.sh` | 本文とスクリプトの上限・必須語の検査 |
| `test-setup-cloud.sh` / `test-install.sh` / `test-update.sh` | スクリプトの試験 |
| `run-tests.sh` | すべての検査と試験を実行する |
