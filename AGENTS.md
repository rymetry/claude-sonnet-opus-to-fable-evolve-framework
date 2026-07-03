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
  いる(スキル未導入環境でも中核だけで機能させるため)。片方を変えたら下の
  重複対応表の対応先を必ず確認する。競合時はスキル優先のルールが中核に明記されている。
- 言語方針: モデルに常時ロードされる操舵テキスト(core・skills・
  claude.ai プロジェクト指示)は英語、ユーザーが会話に貼るテンプレートと
  ドキュメント(README・docs)は日本語。例外が2つある:
  - スキル description 内の日本語フレーズ(「敵対的レビュー」「本気で考えて」等)は
    日本語リクエストからの起動確率を上げる意図的な意味アンカー。削除しないこと。
  - 本ファイル(AGENTS.md)は常時ロードされるが、利用者の可読性を優先して
    日本語で書く意図的判断。
- 指示は否定形ではなく「何をすべきか」の肯定形で書く。変更は少しずつ入れ、
  実タスクで確かめてから次を変える。

## 重複対応表(片方を変えたら対応先を確認)

| core/FABLE-CORE.md | 対応する重複先 |
|---|---|
| §1 Triage / §2 Planning | `skills/deep-task` Phase 0-1 |
| §3 External Memory (STATE.md) | `skills/deep-task` Phase 1 のスケルトンと終了時ルール |
| §5 Verification | `skills/adversarial-review` 全体(スケール: blocker/major/minor/nit) |
| §7 Hard-Problem | `skills/hard-problem` 全体 |
| 全体の縮約 | `templates/claude-ai-project-instructions.md` |

## ルール

- Secrets やローカル環境固有の状態をコミットしない(STATE.md は .gitignore 済み)。
- `main` へ直接 push しない。変更は PR 経由で反映する。
- `main` への force push は禁止(`.claude/hooks/pre-tool-use-policy.sh` が
  ベストエフォートで検出する。実効的な強制は GitHub のブランチ保護)。
- コンフリクトマーカーを残したまま作業を終えない(`.claude/hooks/stop-verify.sh` で検出される)。
