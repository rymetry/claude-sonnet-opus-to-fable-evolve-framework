# claude-sonnet-to-fable-evolve-framework

> A context framework that makes Claude Sonnet (or Opus) approximate
> Fable-grade discipline in Claude Code. Documentation is in Japanese.

Sonnet を Fable 級の品質で動かすためのコンテキストフレームワーク。
モデルの地力を変えるのではなく、Fable が暗黙にやっている行動——深い計画、
進捗の外部化、敵対的自己レビュー——を明示的な手順として Sonnet に与える。
設計の背景と根拠は [docs/PLAN.md](docs/PLAN.md) を参照。

## 導入前に知っておくこと

- **なぜ**: Fable 5 は使用クレジット制に移行したため(経緯は
  [docs/PLAN.md](docs/PLAN.md) §1)、サブスク枠内のモデル(Sonnet / Opus)だけで
  Fable 級の作業品質を出す体制を作るのが目的。
- **コスト**: 導入すると core(約1.9kトークン)が**そのプロジェクトの全セッションで
  常時ロード**される。複雑なタスクでは検証パス・多重試行が追加のトークンを使う。
  単純なタスクには儀式を課さないトリアージ設計でこのコストを抑えている。
- **前提条件**: Claude Code(skills 対応版)、bash、macOS / Linux
  (Windows は WSL または Git Bash が必要)。

## 構成

- [`core/SONNET-FABLE-CORE.md`](core/SONNET-FABLE-CORE.md) — Sonnet 用の中核行動原則。常時ロードして使う
- [`core/OPUS-FABLE-CORE.md`](core/OPUS-FABLE-CORE.md) — Opus(4.8+)用の軽量ハーネス。Fable 5 が使えず
  Opus に切り替える場面用(設計根拠は [docs/PLAN.md](docs/PLAN.md) §8)
- [`skills/deep-task/`](skills/deep-task/SKILL.md) — 複雑タスク用の計画→実行→検証オーケストレーション
- [`skills/adversarial-review/`](skills/adversarial-review/SKILL.md) — 敵対的レビュー(成果物の検証)
- [`skills/hard-problem/`](skills/hard-problem/SKILL.md) — 分解が効かない難問用(独立多重試行+敵対的照合+計算検証)
- [`templates/`](templates/) — claude.ai 用の指示文とチャット用プロンプトのコピペ元
- [`scripts/install.sh`](scripts/install.sh) — Claude Code 環境への導入スクリプト

## セットアップ

### Claude Code(CLI / デスクトップ)— 推奨環境

**プロジェクト単位で導入する**(推奨。スコープが対象プロジェクトに閉じ、
`.claude/` と `CLAUDE.md` をコミットすればチームにも共有できる):

```bash
git clone https://github.com/rymetry/claude-sonnet-to-fable-evolve-framework.git
cd /path/to/your-project
bash /path/to/claude-sonnet-to-fable-evolve-framework/scripts/install.sh
```

スクリプトは導入先プロジェクトに以下を行う(再実行しても安全):

1. `skills/` 配下の 3 スキルを `<project>/.claude/skills/` にコピー(両モデル共用)
2. 選択したモデル用の core を `<project>/.claude/fable/CORE.md` にコピー
   (デフォルトは Sonnet 用。`--model opus` で Opus 用に切り替え)
3. `<project>/CLAUDE.md` に `@.claude/fable/CORE.md` のインポート行を
   1 行追記(既存の内容には触れない。core の import が既にあればスキップ)

**モデルの選択**: プロジェクトで主に使うモデルに合わせて core を選ぶ。
1プロジェクトに core は常に1つで、乗り換えは `--model` を変えて再実行するだけ
(中身だけ差し替わり、import 行は変わらない):

```bash
bash /path/to/claude-sonnet-to-fable-evolve-framework/scripts/install.sh                # Sonnet 用
bash /path/to/claude-sonnet-to-fable-evolve-framework/scripts/install.sh --model opus   # Opus 用
```

再実行時、既に導入済みのスキルがあると上書き前に確認プロンプトが出る
(非対話環境ではスキップして続行)。確認なしで全スキルを更新するには
`--force` を付ける:

```bash
# フレームワーク更新の反映(まず clone を git pull してから)
bash /path/to/claude-sonnet-to-fable-evolve-framework/scripts/install.sh --force
```

プロジェクトを問わず常用する場合は `--global` で `~/.claude/`(全プロジェクト
共通)に導入することもできる。**プロジェクト導入との併用は避けること**
(グローバルとプロジェクトの CLAUDE.md は両方読まれるため core が二重ロード
され、異なる `--model` を混ぜると矛盾した操舵になる):

```bash
bash /path/to/claude-sonnet-to-fable-evolve-framework/scripts/install.sh --global
```

動作確認: 導入先プロジェクトで `claude` を起動し、「利用可能なスキルを教えて」で 3 スキルが
見えることを確認。次に複雑なタスクを依頼して計画→STATE.md 作成→検証の
流れが発動するか確認。明示的に起動したいときは「deep-taskで進めて」と言う。
難しいタスクでは `/effort` を high/xhigh に上げると思考が深くなる
(旧来の "ultrathink" 等のキーワードは廃止済み)。

<details>
<summary>手動で導入する場合</summary>

1. 使うモデルに応じた core(`core/SONNET-FABLE-CORE.md` または `core/OPUS-FABLE-CORE.md`)を
   導入先プロジェクトの `.claude/fable/CORE.md` としてコピーし、
   プロジェクト直下の `CLAUDE.md` に `@.claude/fable/CORE.md` を1行追記する。
   全プロジェクト共通にする場合は、core を `~/.claude/fable/CORE.md` にコピーし、
   `~/.claude/CLAUDE.md` に `@~/.claude/fable/CORE.md` を追記する。
   CLAUDE.md が既にある場合は上書きせず末尾に追加すること。core 冒頭の
   HTML コメントはメタデータなので、本文ごと貼り付ける場合は省いてよい。

   補足: CLAUDE.md の `@path` インポートは**パスにスペースを含むと無音で
   失敗する**既知バグがある。プロジェクト相対の `@.claude/...` やチルダの
   `@~/.claude/...` はリテラルにスペースを含まないため安全(install.sh が
   この形式を使うのはそのため)。clone 先を直接 `@/absolute/path/...` で
   参照するのは避けること。

2. スキルを配置(フレームワークのリポジトリルートで):

   ```bash
   mkdir -p /path/to/your-project/.claude/skills
   cp -r skills/deep-task skills/adversarial-review skills/hard-problem \
     /path/to/your-project/.claude/skills/
   ```

</details>

### Cowork(デスクトップ)

- clone したこのフォルダをセッションで選択すれば、Claude が
  `core/SONNET-FABLE-CORE.md` を参照できる。セッション冒頭に
  「core/SONNET-FABLE-CORE.md を読んでそれに従って」と一言添えるのが確実。
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

効果が薄い箇所があれば `core/SONNET-FABLE-CORE.md` の該当セクションへ、否定形ではなく
「何をすべきか」の形で具体指示を足す(Sonnetは肯定形の指示と実例に最もよく従う)。
変更は少しずつ入れ、実タスクで確かめてから次を変えること。

Sonnet ↔ Opus の乗り換えは `install.sh --model` の再実行だけでよい。
操舵テキスト(core・skills・templates)はモデル名のバージョンを意図的に
含めていない(identity は「実際のモデル名を名乗る」指示なので、どのバージョン
でも誤った自己申告にならない)。設計対象バージョンの記録は
[docs/PLAN.md](docs/PLAN.md) のギャップ分析と各 core 冒頭の Calibration record
コメントにのみ残している。

将来の新世代モデル(Sonnet 6 等)が出た場合は、表記の置換ではなく
**挙動前提の再評価**を行うこと: PLAN.md のギャップ分析を新モデルで見直し、
不要になった補償を該当 core から削る。反映は導入済みの各プロジェクトで
`install.sh --force` を再実行する。

## 運用(更新・アンインストール)

**更新**: clone を `git pull` してから、導入済みの各プロジェクトで
`install.sh --force` を再実行する。導入されるのはコピーなので、clone を
消しても導入済み環境はそのまま動く(更新を受け取るには clone を残す)。

**導入先の .gitignore**: フレームワークは作業メモとして STATE.md を生成する
ことがある。導入先リポジトリの `.gitignore` に `STATE.md` と `STATE-*.md` を
追加しておくことを推奨(`.claude/` と `CLAUDE.md` 本体はコミットして
チーム共有してよい)。

**アンインストール**(導入先プロジェクトで):

```bash
rm -rf .claude/skills/deep-task .claude/skills/adversarial-review .claude/skills/hard-problem
rm -rf .claude/fable
# CLAUDE.md から次の1行を削除: @.claude/fable/CORE.md
```

グローバル導入の場合は `~/.claude/` 配下の同じパスを削除し、
`~/.claude/CLAUDE.md` から `@~/.claude/fable/CORE.md` の行を取り除く。

## ライセンス

[MIT License](./LICENSE)
