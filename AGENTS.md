# Agent Context

Sonnet 5 を Fable 5 級の品質で動かすためのコンテキストフレームワーク。
コンテンツはすべて Markdown で、ビルド・テストは無い。
構成と設計判断は [README.md](README.md) と [docs/PLAN.md](docs/PLAN.md) を参照。

本リポジトリで作業する Claude Code 自体も FABLE mode で動作する:

@core/FABLE-CORE.md

## コマンド

- 導入スクリプトの構文チェック: `bash -n scripts/install.sh`
- 導入スクリプトの動作確認(実環境を汚さない): `HOME=$(mktemp -d) bash scripts/install.sh --force`

## 編集ルール

- `core/FABLE-CORE.md` とスキル(`skills/*/SKILL.md`)は一部を意図的に重複させて
  いる(スキル未導入環境でも中核だけで機能させるため)。片方を変えたら整合を確認する。
  競合時はスキル優先のルールが中核に明記されている。
- 言語方針: モデルに常時ロードされる操舵テキスト(core・skills・
  claude.ai プロジェクト指示)は英語、ユーザーが会話に貼るテンプレートと
  ドキュメント(README・docs)は日本語。
- 指示は否定形ではなく「何をすべきか」の肯定形で書く。変更は少しずつ入れ、
  実タスクで確かめてから次を変える。

## ルール

- Secrets やローカル環境固有の状態をコミットしない。
- `main` へ直接 push しない。変更は PR 経由で反映する。
- `main` への force push は禁止(`.claude/hooks/pre-tool-use-policy.sh` でブロックされる)。
- コンフリクトマーカーを残したまま作業を終えない(`.claude/hooks/stop-verify.sh` で検出される)。
