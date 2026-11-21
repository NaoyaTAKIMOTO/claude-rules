# 共通ルール 同期化 実装計画(第2版)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 公開リポジトリ `NaoyaTAKIMOTO/claude-rules` を正本にし、クラウドと Mac の両方が自動でそこから最新のルールを取り込むようにする。あわせて、最終チェックの指摘とユーザーの追加要望を本文に反映する。

**Architecture:** 正本は `CLAUDE.md` の1ファイル。クラウドはセットアップスクリプトで raw URL から取得し、Mac は複製したリポジトリを `@import` で取り込む。Mac の複製は SessionStart フックの `git pull` で最新に保つ。

**Tech Stack:** Markdown、bash、curl、git、GitHub Actions

**Spec:** `/home/user/claude-global-rules/design.md`(「変更(最終チェック後の見直し)」の節)

## Global Constraints
- raw URL: `https://raw.githubusercontent.com/NaoyaTAKIMOTO/claude-rules/main/CLAUDE.md`
- セットアップスクリプトは 100 行以内・1 行 200 バイト以内。CR を含まない。どんな場合も終了コードは 0
- CLAUDE.md は 90 行以内・1 行 190 バイト以内(簡潔さの目安として維持する)
- 「自分のリポジトリ」= リモートの所有者が NaoyaTAKIMOTO、またはリモートなし。フォークは除く
- `claude-rules` リポジトリ自体は、ブランチと e2e の決まりの対象外。check.sh が通ったら main に直接入れる

## Review Focus
1. 取得失敗(ネットワーク不通、404、空の応答)でもセッションが起動し、Claude が失敗に気づける(Task 2 で3通り試す)
2. Mac の既存 `~/.claude/CLAUDE.md` を消さない。install を2回実行しても import 行が重複しない(Task 3)
3. raw URL の中身がローカルの CLAUDE.md と一致する(Task 4)
4. 新しいクラウドセッションで、取得したルールが指示として読み込まれる(Task 5)
5. 本文で `dev 上でリファクタリング` の食い違いが再発しない(Task 1 の否定検査)

---

### Task 1: 本文を更新する

**Files:** Modify `CLAUDE.md`, `check.sh`

- [ ] **Step 1: check.sh に検査を足す**
  - 必須語の追加: `NaoyaTAKIMOTO`, `フォーク`, `[定期実行]`, `1か月`, `feat/refactor-`, `方針`
  - 含んではいけない語(新設): `dev 上でリファクタリング`
- [ ] **Step 2: 実行して失敗を確認する**
  - Run: `bash check.sh CLAUDE.md`
  - Expected: 追加した必須語がないこと、禁止語があることで NG
- [ ] **Step 3: CLAUDE.md を書き換える**
  - 適用範囲: 自分のリポジトリだけ。計画の手順は、方針や実装計画を決めるときだけ
  - リポジトリの準備は、計画に含めて合意を得てから行う
  - デプロイ時点の手順: セキュリティチェック → テストと e2e → 承認 → main
  - リファクタリング: 前回から1か月以上たっていれば、デプロイの前に `feat/refactor-YYYY-MM` で行い、PR で dev へ
  - 定期実行(`[定期実行]` の印)の自動承認と、その歯止め
- [ ] **Step 4: 再実行して OK を確認し、コミットする**

### Task 2: クラウド用の取得スクリプトを作る

**Files:** Create `setup-cloud.sh`(既存の `setup.sh` は削除する)

- [ ] **Step 1: 3通りの試験を書き、失敗を確認する**
  - 試験は `test-setup-cloud.sh` に書く。URL は環境変数 `RULES_URL` で差し替えられるようにする
  - (a) `file://` で CLAUDE.md を指す → 書き出したファイルが CLAUDE.md と同一
  - (b) 存在しない URL → 失敗を知らせる短い CLAUDE.md になり、終了コードは 0
  - (c) 空のファイルを指す → (b) と同じ
  - Expected: スクリプトがまだないので失敗する
- [ ] **Step 2: `setup-cloud.sh` を書く**
  - 処理: `curl -fsSL --max-time 20` で一時ファイルに取得し、空でなければ置き換える
  - 失敗時に書く本文: 「共通ルールの取得に失敗しました。作業を始める前に、このことをユーザーに伝えてください」
  - `HOME` が未設定なら `/root` を使う
- [ ] **Step 3: 試験と `check.sh setup-cloud.sh` が通ることを確認し、コミットする**

### Task 3: リポジトリの付属ファイルを作る

**Files:** Create `.github/workflows/check.yml`, `install.sh`, `README.md`, `test-install.sh`

- [ ] **Step 1: install の試験を書き、失敗を確認する**
  - 一時的な HOME と、ローカルに置いた複製元(`CLAUDE_RULES_REPO` で差し替え)を使う
  - 既存の `~/.claude/CLAUDE.md` の中身が残ること
  - import 行が1行だけ足されること。2回実行しても1行のまま
  - `~/claude-rules/CLAUDE.md` があること
- [ ] **Step 2: `install.sh` を書く**
  - 処理: 複製がなければ clone、あれば `pull --ff-only`。そのあと import 行がなければ追記する
  - settings.json は自動では書き換えない。フックの設定例は README に載せる
- [ ] **Step 3: `check.yml` と `README.md` を書く**
  - check.yml: push と PR のたびに、`bash check.sh CLAUDE.md`、`bash check.sh setup-cloud.sh`、2つの試験スクリプトを実行する
  - README: Mac の手順(install.sh の実行、SessionStart フックの設定例)と、本文の直し方
- [ ] **Step 4: 試験がすべて通ることを確認し、コミットする**

### Task 4: GitHub に公開する

- [ ] **Step 1: ユーザーが作った空のリポジトリを `add_repo`(push 権限)でつなぎ、main に push する**
- [ ] **Step 2: 公開された本文を確かめる**
  - Run: `curl -fsSL <raw URL> | diff - CLAUDE.md`
  - Expected: 差分なし
  - 反映されるまで数分かかることがある。その場合は時間を置いて再確認する
- [ ] **Step 3: GitHub Actions の検査が成功したことを確かめる**

### Task 5: クラウド環境を切り替えて確かめる

- [ ] **Step 1: `update_environment` で、セットアップスクリプトを `setup-cloud.sh` の内容に置き換える(承認カード)**
- [ ] **Step 2: 新しいセッションを立てて確かめる**
  - 確かめること: `~/.claude/CLAUDE.md` の1行目と大きさ、指示として読み込まれているか
  - Expected: raw URL の中身と同じ大きさで、指示として見えている

### Task 6: Mac の手順を渡す
- [ ] 実行するコマンドと、フックを追加する方法を渡す
