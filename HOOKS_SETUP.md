# gh-hooks プロジェクト用フック設定

このプロジェクトでは、release-pleaseを使用した自動リリース管理を行うためのフックを設定しています。

## 設定概要

`.gh-hooks.sh`ファイルに以下のフックを定義しています：

### 1. `gh_hook_pr_merged` - 通常のPRマージ時

PRがマージされた際に、release-pleaseを実行してリリースPRを自動作成・更新します。

```bash
gh pr merge <PR番号> --squash
```

↓ 自動実行

```bash
npx release-please release-pr \
  --repo-url="shabaraba/gh-hooks" \
  --token="${GITHUB_TOKEN}" \
  --config-file=release-please-config.json \
  --manifest-file=.release-please-manifest.json
```

### 2. `gh_hook_release_pr_merged` - リリースPRマージ時

リリースPR（タイトルが`chore(main): release`で始まるPR）がマージされた際に、GitHubリリースを自動作成します。

```bash
gh pr merge <リリースPR番号> --squash
```

↓ 自動実行

```bash
npx release-please github-release \
  --repo-url="shabaraba/gh-hooks" \
  --token="${GITHUB_TOKEN}" \
  --config-file=release-please-config.json \
  --manifest-file=.release-please-manifest.json
```

## 必要な環境

### Node.js / npx

release-pleaseをローカルで実行するために必要です。

```bash
# Node.jsがインストールされているか確認
node --version
npx --version
```

インストールされていない場合は、[Node.js公式サイト](https://nodejs.org/)からインストールしてください。

### GITHUB_TOKEN

release-pleaseとGitHubリリース作成に必要です。

**設定方法:**

```bash
# 1. GitHub Personal Access Tokenを作成
# https://github.com/settings/tokens/new
# 必要な権限: repo, workflow

# 2. 環境変数として設定
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"

# 3. .zshrc や .bashrc に追加して永続化
echo 'export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"' >> ~/.zshrc
```

## リリースフロー

### 通常の開発 → リリース

1. **機能開発**
   ```bash
   # feat: や fix: などのSemantic Commit Messageでコミット
   git commit -m "feat: add awesome feature"
   git push
   ```

2. **PRを作成してマージ**
   ```bash
   gh pr create --fill
   gh pr merge --squash
   ```

   → **自動実行**: release-pleaseがリリースPRを作成/更新

3. **リリースPRをマージ**
   ```bash
   gh pr merge <リリースPR番号> --squash
   ```

   → **自動実行**: GitHubリリースが作成される

### フローの図解

```
[開発者] feat: add feature
    ↓
[PR作成] gh pr create
    ↓
[PRマージ] gh pr merge → gh_hook_pr_merged()
    ↓                      ↓
    ↓                 release-please実行
    ↓                      ↓
    ↓              リリースPR作成/更新
    ↓
[リリースPRマージ] gh pr merge → gh_hook_release_pr_merged()
    ↓                               ↓
    ↓                          GitHubリリース作成
    ↓                               ↓
  完了                         バージョンタグ付与
                                CHANGELOG更新
```

## 動作確認

### 1. Shell Integrationの確認

```bash
# gh-hooksがロードされているか確認
type gh | grep function
# 出力: gh is a function

# ステータス確認
gh hooks status
# 出力:
# ✓ Shell integration: ACTIVE
# ✓ Git repository: FOUND
# ✓ Project configuration: FOUND
```

### 2. フック定義の確認

```bash
# プロジェクトルートで実行
source .gh-hooks.sh

# フック関数が定義されているか確認
type gh_hook_pr_merged
type gh_hook_release_pr_merged
```

### 3. デバッグモードでテスト

```bash
# デバッグモードを有効化
export GH_HOOKS_DEBUG=1

# テストPRをマージ（実際のPRが必要）
gh pr merge <PR番号> --squash

# ログ出力を確認
# [gh-hooks debug] 形式でデバッグ情報が表示される
```

## トラブルシューティング

### フックが実行されない

1. **Shell Integrationの確認**
   ```bash
   gh hooks status
   ```

   NOT ACTIVEの場合:
   ```bash
   gh hooks install
   exec $SHELL
   ```

2. **GITHUB_TOKENの確認**
   ```bash
   echo $GITHUB_TOKEN
   ```

   空の場合は環境変数を設定

3. **デバッグモードで詳細確認**
   ```bash
   export GH_HOOKS_DEBUG=1
   gh pr merge <PR番号> --squash
   ```

### release-pleaseが失敗する

- **権限不足**: GITHUB_TOKENに`repo`と`workflow`権限があるか確認
- **設定ファイル不足**: `release-please-config.json`が存在するか確認
- **マニフェスト不足**: `.release-please-manifest.json`が存在するか確認

### GitHubリリース作成が失敗する

- **バージョン重複**: 同じバージョンのリリースが既に存在する場合
- **CHANGELOG.md不足**: CHANGELOGファイルが見つからない場合は`--generate-notes`で作成

## カスタマイズ

### リリースタイプの変更

現在は`simple`タイプを使用していますが、`release-please-config.json`を編集することで変更可能です：

```json
{
  "release-type": "node",  // または "rust", "python" など
  ...
}
```

### リリースPRパターンの変更

デフォルトは`^chore\(main\): release`ですが、カスタマイズ可能：

```bash
# .gh-hooks.sh で設定
export GH_HOOKS_RELEASE_PATTERN="^release:"
```

## 参考リンク

- [release-please Documentation](https://github.com/googleapis/release-please)
- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
