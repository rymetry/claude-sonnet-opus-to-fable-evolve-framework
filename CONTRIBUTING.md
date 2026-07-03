# コントリビューションガイド

このプロジェクトへのコントリビューションを歓迎します。

## はじめに

1. このリポジトリを fork する
2. feature ブランチを作成する (`git checkout -b feature/my-feature`)
3. 変更をコミットする (`git commit -m "feat: 新機能の追加"`)
4. ブランチを push する (`git push origin feature/my-feature`)
5. Pull Request を作成する

## コミットメッセージ

[Conventional Commits](https://www.conventionalcommits.org/) に従います。

| Prefix | 用途 |
|--------|------|
| `feat:` | 新機能 |
| `fix:` | バグ修正 |
| `docs:` | ドキュメントのみの変更 |
| `refactor:` | リファクタリング |
| `test:` | テストの追加・修正 |
| `chore:` | ビルド・CI・依存関係の変更 |

## Pull Request

- PR はなるべく小さく保つ
- 変更内容と理由を明記する
- `scripts/install.sh` を変更した場合は `bash -n scripts/install.sh` が通ること、
  一時ディレクトリでの動作確認を行うこと(このリポジトリに CI・ビルド・テストは無い):
  - プロジェクト導入: `REPO=$(pwd) && (cd "$(mktemp -d)" && bash "$REPO/scripts/install.sh" --force)`
  - グローバル導入: `HOME=$(mktemp -d) bash scripts/install.sh --global --force`
- `core/` 配下の core(SONNET / OPUS どちらでも)またはスキルを変更した場合は、
  AGENTS.md の重複対応表に従い対応箇所の整合(§番号の一致を含む)を確認すること

## Issue

バグ報告や機能リクエストは Issue テンプレートを利用してください。

## Code of Conduct

[CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md) を遵守してください。
