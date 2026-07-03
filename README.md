# claude-sonnet-to-fable-evolve-framework

Sonnet 5 を Fable 5 級の品質で動かすためのコンテキストフレームワーク。
モデルの地力を変えるのではなく、Fable 5 が暗黙にやっている行動——深い計画、
進捗の外部化、敵対的自己レビュー——を明示的な手順として Sonnet 5 に与える。
設計の背景と根拠は [docs/PLAN.md](docs/PLAN.md) を参照。

## 構成

- [`core/FABLE-CORE.md`](core/FABLE-CORE.md) — 中核となる行動原則。常時ロードして使う
- [`skills/deep-task/`](skills/deep-task/SKILL.md) — 複雑タスク用の計画→実行→検証オーケストレーション
- [`skills/adversarial-review/`](skills/adversarial-review/SKILL.md) — 敵対的レビュー(成果物の検証)
- [`skills/hard-problem/`](skills/hard-problem/SKILL.md) — 分解が効かない難問用(独立多重試行+敵対的照合+計算検証)
- [`templates/`](templates/) — claude.ai 用の指示文とチャット用プロンプトのコピペ元
- [`scripts/install.sh`](scripts/install.sh) — Claude Code 環境への導入スクリプト

## セットアップ

### Claude Code(CLI / デスクトップ)— 推奨環境

```bash
git clone https://github.com/rymetry/claude-sonnet-to-fable-evolve-framework.git
cd claude-sonnet-to-fable-evolve-framework
bash scripts/install.sh
```

スクリプトは以下を行う(再実行しても安全):

1. `skills/` 配下の 3 スキルを `~/.claude/skills/` にコピー
2. `core/FABLE-CORE.md` を `~/.claude/fable/FABLE-CORE.md` にコピー
3. `~/.claude/CLAUDE.md` に `@~/.claude/fable/FABLE-CORE.md` のインポート行を
   1 行追記(既存の CLAUDE.md の内容には触れない。既に行があればスキップ)

動作確認: `claude` を起動し、「利用可能なスキルを教えて」で 3 スキルが
見えることを確認。次に複雑なタスクを依頼して計画→STATE.md 作成→検証の
流れが発動するか確認。明示的に起動したいときは「deep-taskで進めて」と言う。
難しいタスクでは `/effort` を high/xhigh に上げると思考が深くなる
(旧来の "ultrathink" 等のキーワードは廃止済み)。

<details>
<summary>手動で導入する場合</summary>

1. `core/FABLE-CORE.md` の内容を `~/.claude/CLAUDE.md`(全プロジェクト共通)
   またはリポジトリ直下の `CLAUDE.md`(プロジェクト単位)に追記する。
   既存の CLAUDE.md がある場合は上書きせず末尾に追加すること。冒頭の HTML
   コメント(セットアップ説明)は貼らなくてよい。

   補足: CLAUDE.md の `@path` インポートは**パスにスペースを含むと無音で
   失敗する**既知バグがある。clone 先のパスにスペースが含まれる場合は、
   インポートではなく本文追記にするか、スペースなしの場所に置いた
   コピーを参照すること(install.sh はこのため `~/.claude/fable/` を使う)。

2. スキルを配置(リポジトリルートで):

   ```bash
   mkdir -p ~/.claude/skills
   cp -r skills/deep-task skills/adversarial-review skills/hard-problem ~/.claude/skills/
   ```

</details>

### Cowork(デスクトップ)

- clone したこのフォルダをセッションで選択すれば、Claude が
  `core/FABLE-CORE.md` を参照できる。セッション冒頭に
  「core/FABLE-CORE.md を読んでそれに従って」と一言添えるのが確実。
- スキルとして常用する場合は、設定 > Capabilities から
  `skills/` 配下の 3 スキルを登録する。

### claude.ai(チャット)

- プロジェクトを作成し、[`templates/claude-ai-project-instructions.md`](templates/claude-ai-project-instructions.md) の
  区切り線以下をプロジェクト指示に貼り付ける。
- プロジェクトを使わない単発チャットでは [`templates/kickoff-prompt.md`](templates/kickoff-prompt.md) の
  テンプレートを使う。

## 使い方の型

| 場面 | やること |
|---|---|
| 日常の質問・小タスク | 何もしない(フレームワークが自動でT1と判定し儀式を省く) |
| 複雑・重要なタスク | 「deep-taskで」と依頼。計画と成功基準が出てくるので最初に握る |
| 成果物の品質が不安 | 「adversarial-reviewして」で敵対的レビューを単体実行 |
| セッションを跨ぐ作業 | STATE.mdが作られるので、次セッションで「STATE.mdから再開」 |
| 極端に難しい単発推論 | 「hard-problemで」と依頼。多重試行+計算検証で挑む → [docs/PLAN.md](docs/PLAN.md) §6 |

## スキルの起動について

スキルはキーワードの完全一致ではなく、**説明文とリクエストの意味的なマッチング**で
起動する(判断するのはモデル自身)。説明文に載せたフレーズは確率を上げるアンカーで
あって、契約ではない。したがって:

- 確実に起動したいとき: スキル名をそのまま言う(「hard-problemで」「deep-taskで」)。
  これが唯一の決定的な起動方法。
- 「徹底的に考えて」等の類似フレーズ: 意味が近いので起動することが多いが保証はない。
  逆に「深く考えて」のような日常フレーズは、スキルをロードせず単に推論が深くなる
  だけのことも多い(それで十分な場面も多い)。
- 起動しすぎる/しなさすぎる場合: SKILL.md冒頭のdescriptionを編集して調整する。
  広げるほど誤発火が増える点に注意(「レビューして」を外したのはこのため)。

## チューニング

効果が薄い箇所があれば `core/FABLE-CORE.md` の該当セクションへ、否定形ではなく
「何をすべきか」の形で具体指示を足す(Sonnet 5は肯定形の指示と実例に最もよく従う)。
変更は少しずつ入れ、実タスクで確かめてから次を変えること。
将来モデルを乗り換えた場合は、FABLE-CORE冒頭のモデル名(Claude Sonnet 5)を
更新すること。

## ライセンス

[MIT License](./LICENSE)
