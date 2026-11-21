# Claude Code 共通ルール 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ユーザーの作業ルールを `~/.claude/CLAUDE.md` にまとめ、ローカルとクラウドの両方で読み込まれるようにする。

**Architecture:** ルール本文は `CLAUDE.md` の1ファイルにまとめる。クラウドには、この本文から作るセットアップスクリプトで書き出す。ローカルには、ユーザーが同じファイルをコピーする。

**Tech Stack:** Markdown、bash(セットアップスクリプトと検査スクリプト)、クラウド環境ツール(update_environment / create_session)

**Spec:** `/home/user/claude-global-rules/design.md`

## Global Constraints
- セットアップスクリプトは100行以内、1行200バイト以内。CR・NUL・制御文字は使わない
- そのため `CLAUDE.md` は90行以内、1行190バイト以内(日本語なら約60字)に収める
- 文書の置き場所: `docs/plans/YYYY-MM-DD-<テーマ>.md`、`docs/log.md`、`docs/status.html`
- 「テスト」は単体・結合テストを指す。e2e は main / dev へのマージ条件
- 適用範囲はコードを変える作業。質問への回答や調べものだけのときは手順を省く

## Review Focus
1. Mac にすでに `~/.claude/CLAUDE.md` がある場合、上書きで消える。そのためコピー前にバックアップする手順を渡す(Task 4)
2. セットアップスクリプトが失敗すると、セッション自体が起動しなくなる。そのため `mkdir -p` と書き出しだけの最小構成にする(Task 2 で検査)
3. 本文中の `$` やバッククォートがシェルに展開されると、内容が変わる。引用符つき heredoc(`<<'EOF'`)を使い、書き出したファイルが元と完全に一致することを `diff` で確かめる(Task 2)
4. スクリプトの開始ディレクトリは決まっていない。そのため書き出し先は `$HOME/.claude/CLAUDE.md` で指定する(Task 2)
5. セットアップスクリプトは、コンテナを新しく作るときにしか動かない。既存のセッションを再開しても反映されないので、確認は新しいセッションで行う(Task 3)

---

### Task 1: ルール本文 `CLAUDE.md` を作る

**Files:**
- Create: `/home/user/claude-global-rules/CLAUDE.md`
- Test: `/home/user/claude-global-rules/check.sh`

**Interfaces:**
- Produces: `CLAUDE.md`(Task 2 と Task 4 で使う)。`check.sh CLAUDE.md` は、合格なら終了コード0
- `check.sh setup.sh` の形でも使えるようにする(Task 2 で使う)

- [ ] **Step 1: 検査スクリプト `check.sh` を書く**
  - 共通の検査: 行数の上限(md は90行、sh は100行)、1行のバイト数の上限(md は190、sh は200)、CR が含まれないこと
  - md だけの検査: 次の語がすべて含まれること
    `大目的`, `先行事例`, `合意`, `docs/plans/`, `docs/log.md`, `docs/status.html`, `テストファースト`, `コミット`, `失敗したときの出力`, `緩めない`, `サブエージェント`, `スクショ`, `main`, `dev`, `feat`, `e2e`, `GitHub Actions`, `Mac`, `セキュリティ`, `リファクタリング`, `定数`, `承認`
- [ ] **Step 2: 実行して失敗を確認する**
  - Run: `bash check.sh CLAUDE.md`
  - Expected: ファイルがないため、終了コードが0以外になる
- [ ] **Step 3: `CLAUDE.md` を書く**
  - 構成: 適用範囲 → 目的の整理 → 計画と合意 → 記録(docs の3ファイル) → テストとコミット → 動作確認 → ブランチと e2e → dev → main の手順(リファクタリング → セキュリティチェック → e2e → 承認後にマージ) → ブランチ保護が使えない場合
  - 内容は design.md の「ユーザーが決めたこと」と「私が決めたこと」に沿う
- [ ] **Step 4: 再実行して合格を確認する**
  - Run: `bash check.sh CLAUDE.md`
  - Expected: `OK` を表示し、終了コード0
- [ ] **Step 5: ユーザーに本文を見せて確認を取る**
  - 直してほしい点が出たら、修正して Step 4 からやり直す

### Task 2: セットアップスクリプトを作り、クラウド環境に設定する

**Files:**
- Create: `/home/user/claude-global-rules/setup.sh`

**Interfaces:**
- Consumes: Task 1 の `CLAUDE.md` と `check.sh`
- Produces: 「デフォルトクラウド環境」に保存されたセットアップスクリプト

- [ ] **Step 1: 一時的な HOME で `setup.sh` を実行し、失敗を確認する**
  - Run: `T=$(mktemp -d); HOME=$T bash setup.sh; diff CLAUDE.md $T/.claude/CLAUDE.md`
  - Expected: `setup.sh` がまだないので失敗する
- [ ] **Step 2: `setup.sh` を作る**
  - 中身は `mkdir -p "$HOME/.claude"` と、`cat > "$HOME/.claude/CLAUDE.md" <<'EOF'` に本文を続け、`EOF` で閉じる形
  - `CLAUDE.md` から機械的に組み立てる
- [ ] **Step 3: 動作と上限を確かめる**
  - Run: Step 1 のコマンドと `bash check.sh setup.sh`
  - Expected: `diff` が何も出さない。`check.sh` は `OK`
  - スクリプトを2回続けて実行しても成功すること(何度実行しても同じ結果になること)も確かめる
- [ ] **Step 4: `get_environment` で現在の設定を確かめ、`update_environment` で設定を提案する**
  - `script_change` は "adds a setup script" にする
  - ユーザーが承認カードで許可する

### Task 3: 新しいクラウドセッションで読み込まれているか確かめる

**Interfaces:**
- Consumes: Task 2 で保存したセットアップスクリプト

- [ ] **Step 1: `create_session` で、この環境に新しいセッションを1つ作る**
  - そのセッションに確認してもらうこと:
    - `~/.claude/CLAUDE.md` があるか、その1行目
    - 「適用範囲」の節が指示として見えているか
- [ ] **Step 2: 結果を `get_session` / `list_events` で読む**
  - Expected: ファイルがあり、ルールが指示として見えている
  - 失敗した場合は原因を調べ、その結果を `docs/log.md` に相当する記録としてユーザーに報告する

### Task 4: ローカルに置くファイルと手順を渡す

- [ ] **Step 1: `CLAUDE.md` をユーザーに送る(SendUserFile)**
- [ ] **Step 2: Mac で実行するコマンドを渡す**
  - 既存ファイルがあればバックアップ: `cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak`
  - 配置: `mkdir -p ~/.claude` と、ダウンロードしたファイルを `~/.claude/CLAUDE.md` にコピー
  - 既存ファイルがある場合は、上書きではなく内容を統合したいかを確認する
- [ ] **Step 3: 今後の更新方法を伝える**
  - 直すときは2か所を更新する: ローカルのファイルと、環境のセットアップスクリプト
  - 「Default」環境も使っている場合は、そちらにも手作業で貼る
