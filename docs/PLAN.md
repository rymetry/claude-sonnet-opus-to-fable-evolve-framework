# Sonnet 5 → Fable 5級 引き上げフレームワーク 設計プラン

作成日: 2026-07-03 / 対象: Claude Code (CLI・デスクトップ), Cowork, claude.ai

## 1. 背景

2026年6月30日に輸出規制が解除されFable 5は7月1日から全ユーザーに再開放されたが、
7月7日まではサブスク枠(週次上限の50%まで)、**7月8日以降は使用クレジット制**
(API料金: 入力$10/出力$50 per 1Mトークン)に移行する。Anthropicは「キャパシティが
確保でき次第サブスクに戻す」としているが時期は未定。
(本段落の日付・価格は二次情報由来で未検証。判断に使う前に末尾の参考情報源の
注記どおり一次情報での確認を推奨。)よって当面は、追加コストを
かけず**Sonnet 5のみで全タスクを完結させる**体制を整えるのが本プランの方針である。

## 2. ギャップ分析 — 何を埋めるのか

まず正直な前提として、**コンテキストだけでモデルの地力は変わらない**。Fable 5との
差のうち「単発の深い推論力」そのものはプロンプトでは埋まらない。しかしベンチマークと
公式ドキュメントを見ると、差の大部分は地力ではなく**振る舞いの差**に由来する:

| ギャップ | 中身 | コンテキストで埋まるか |
|---|---|---|
| 長期タスクの計画・遂行 | SWE-bench Proで約17pt差。数十ステップに及ぶ作業での一貫性 | ◎ 外部メモリ+計画プロトコルで大部分補償可能 |
| 初回正答率 | Fableは1回目で正しいことが多い | ◎ 検証パス(2周目)で回収可能 |
| サブエージェント並列管理 | Fableは並列委譲の采配が上手い | ○ 委譲ルールを明文化すれば近づく |
| スコープの汲み取り | Sonnet 5は指示を字義通りに解釈し、頼まれていないことを推測しない | ◎ 「意図で解釈せよ」と明示すれば解消 |
| 単発の深い推論 | 新規アルゴリズム設計等、分解が効かない問題 | △ 完全には埋まらないが、独立試行の多数決+敵対的照合+計算検証で大幅に縮小(§6) |

**なぜ埋まるのか**: Sonnet 5は指示追従が極めて忠実で、公式ドキュメントも
「ツール使用や自己検証ループをより積極的に行う」性質とプロンプトによる誘発を
明記している。つまり「言えばやる」モデルなので、
Fableが暗黙にやっている行動——深い計画、進捗の外部化、敵対的自己レビュー——を
**明示的な手順として与えれば**、大半のタスクで同等品質に近づける(「8〜9割」は
実務コミュニティで流通する定性的な目安であり、実測値ではない点に注意)。

## 3. 設計原則 — 4つの補償メカニズム

**(1) 複雑度トリアージ**: 全タスクをT1(単純)/T2(標準)/T3(複雑)に分類し、プロトコルの
重さを変える。簡単な質問に儀式を課すとむしろ品質と速度が落ちるため。

**(2) 計画→実行→検証の強制**: Fableの長期一貫性は「良い計画を立てて守る」能力。
成功基準の明文化・ステップ分解・**検証方法を作業前に決める**ことで代替する。
検証パスは本フレームワークで最もレバレッジが高い: 初回正答率の差を2周目で回収する。

**(3) 外部メモリ (STATE.md)**: コンテキストウィンドウは揮発する。目標・決定(理由付き)・
完了・次の一手をファイルに書き続けることで、コンパクション後・セッション跨ぎでも
Fable並みの一貫性を維持する。Anthropicのlong-running agentsハーネス設計と同じ発想。

**(4) 新鮮なコンテキストでの敵対的レビュー**: 自分の作業を自分の文脈のままレビュー
すると、書いた時の思い込みを引き継いでしまう。サブエージェント(または明示的に
敵対者の役を与えた再パス)に「あなたはこれを書いていない」前提で全指摘を出させる。
Sonnet 5は「重要なものだけ報告せよ」と言うと本当に間引いてしまうため、
**網羅優先・フィルタは後段**という指示にするのが公式推奨。

## 4. 成果物構成

```
claude-sonnet-to-fable-evolve-framework/
├── README.md                    ← 環境別セットアップ手順
├── docs/
│   └── PLAN.md                  ← 本書
├── core/
│   ├── SONNET-FABLE-CORE.md     ← Sonnet 5 用中核。常時ロードされる行動原則(英語)
│   └── OPUS-FABLE-CORE.md       ← Opus 用軽量ハーネス(§8。install.sh --model opus で導入)
├── skills/
│   ├── deep-task/SKILL.md       ← T3タスク用フル・オーケストレーション
│   ├── adversarial-review/SKILL.md ← 敵対的レビュー(単体でも使用可)
│   └── hard-problem/SKILL.md    ← 分解が効かない難問用(多重試行+計算検証)
├── templates/
│   ├── claude-ai-project-instructions.md ← claude.aiプロジェクト指示(縮約版)
│   └── kickoff-prompt.md        ← 単発チャット用テンプレート
└── scripts/
    └── install.sh               ← Claude Code 環境への導入スクリプト
```

このほかリポジトリには repo-template 由来の運用ファイル(`.claude/hooks/`、
`.github/`、AGENTS.md 等)があるが、フレームワークの成果物ではないため
本ツリーには含めていない。

設計上の判断:
- **中核は薄く、重い手順はスキルに**。CLAUDE.md相当は常時コンテキストを消費する
  ため行動原則のみに絞り、フル手順は必要時にだけロードされるスキルへ分離した。
  中核とスキルは一部重複するが(スキル未導入環境でも中核だけで機能させるため)、
  競合時はスキルが優先というルールを中核に明記してある。
- **言語の使い分け**: モデルに常時ロードされる操舵テキスト(中核・スキル・
  claude.aiプロジェクト指示)は精度とトークン効率のため英語。ユーザーが日本語の
  会話に都度貼るチャットテンプレートは、会話の言語と揃える方が自然なため日本語。
- **全環境で同じ思想、環境ごとに搬送手段を変える**(README参照)。

## 5. 環境別マッピング

| 環境 | 中核の載せ方 | スキル | サブエージェント |
|---|---|---|---|
| Claude Code | `.claude/fable/CORE.md` に配置し CLAUDE.md から import(install.sh が自動化) | .claude/skills/ | Task tool(フル機能) |
| Cowork | フォルダ選択+セッション冒頭で中核を読ませる(手順はREADME) | 設定 > Capabilities から登録 | Agent tool |
| claude.ai | プロジェクト指示に縮約版を貼付 | 不可 | 不可(自己再パスで代替) |

claude.aiだけ機能が限られるため、縮約版はファイル・委譲に依存しない要素
(トリアージ、計画、意図解釈、自己検証、状態サマリ、難問手順)を中心に構成した。

## 6. 最難関タスクのSonnet 5完結戦略(hard-problemプロトコル)

本フレームワークはSonnet 5のみで完結する。分解が効かない深い推論(従来なら上位
モデルに回す領域)には、地力の不足を**試行回数と検証の非対称性**で補う専用スキル
`hard-problem` を当てる。原理は3つ:

1. **自己一貫性(多数決)**: 独立したコンテキストで2〜3回別アプローチで解かせると、
   誤りは試行ごとに相関しないため、一致は正しさの証拠になり、不一致は「本当に
   難しい箇所」をピンポイントで炙り出す。
2. **検証の非対称性**: 答えを作るより検証する方がはるかに簡単。受け入れ条件を
   解く前に定義し、コード実行・小ケース全列挙・リファレンス実装との突合で
   機械的に検証する。再推論より実行結果が常に優先。
3. **問題の再定式化**: 「難しすぎる」問題の多くは実は定義が曖昧なだけ。複数の
   定式化と簡易版の完全解によって、難しさの核を特定してから挑む。

50ステップ超の長期自律実行は一気にやらず、STATE.mdチェックポイント+チャンク境界
ごとの検証ゲートで分割する。遅くなるが、各チャンクが検証済みで積み上がる。

## 7. 制約と正直な限界

- 上記の戦略でも、単発の深い推論の品質差はゼロにはならない(縮まるが残る)。
  そのためhard-problemは「確立済み/おそらく正しい/未解決」を峻別して報告する
  設計にした——どこまで信用できるかが明確なら、残った差は実用上管理できる。
- 検証パスと多重試行はトークン(=サブスク使用量)を追加消費する。T1タスクに
  適用しないためのトリアージ、hard-problemを乱用しないための起動条件が重要。
- 効果は定性的。導入後、実タスクでの体感差(特にコードレビュー網羅性と長期タスクの
  迷子率)を見てSONNET-FABLE-COREをチューニングすることを推奨。

## 8. Opus 用変種(OPUS-FABLE-CORE)の設計

Fable 5 が使えない場面の受け皿は Sonnet 5 だけでなく Opus(4.8+)もありうる。
そのための軽量ハーネス `core/OPUS-FABLE-CORE.md` を用意した。導入は
`install.sh --model opus`。配置先は両変種共通の `.claude/fable/CORE.md` で、
1プロジェクトに core は常に1つ。モデル乗り換えは `--model` を変えて再実行する
だけで中身が差し替わり、CLAUDE.md の import 行は変わらない(**同一スコープ内では**
2つの core が同時ロードされない設計。グローバル導入とプロジェクト導入を併用すると
両方の CLAUDE.md が読まれてこの保証は破れるため、README で併用を非推奨としている)。

ギャップ分析(Opus 4.8 対 Fable 5)の要点と対処:

| ギャップ | 中身 | OPUS-FABLE-CORE での対処 |
|---|---|---|
| 字義通り解釈 | Sonnet 固有ではなく世代共通(公式が Opus 4.8 にも同一文言で明記) | 意図スコープの明示指示を維持 |
| 長期セッションの一貫性 | 超長セッションで劣化し、タスクが長いほど Fable との差が開く | STATE.md 外部メモリ+「コンパクション連打より新セッション再開」を維持(最高レバレッジ) |
| 最難問の初回正答率 | 分解が効かない問題で Fable の約半分の完了率(二次情報) | hard-problem プロトコルを維持しつつ、発動を「検証失敗後」に限定 |
| ツール・委譲の過小使用 | 推論を優先しツールを呼ばない・サブエージェントを立てない傾向(公式) | 「調べられるものは調べる」「独立作業は一括 fan-out」へ押す指示を追加(Sonnet 用と逆方向) |
| 些末タスクの過剰思考 | 単純タスクで考えすぎて劣化(公式の effort 注記+実務報告) | T1「儀式なし・考えすぎない」を明文化 |

SONNET-FABLE-CORE から削ったもの(Opus 4.8 がネイティブに持つため):
自己検証の反復強制(4.7 比で欠陥見逃し約1/4)、誠実さ系の念押し、
委譲の詳細な手順書き。一方「網羅優先レビュー」(放置すると高重大度
のみに間引く挙動は Opus も同じ)と検証ゲート1回は残した。

§番号は SONNET-FABLE-CORE と揃えてあり、スキル内の「SONNET-FABLE-CORE §n」参照は
OPUS-FABLE-CORE の同番号節に解決される(OPUS-FABLE-CORE 冒頭に明記)。スキル3種は
両変種で共用する。

正直な限界: 最難問の初回正答率と超長文脈の検索精度は地力差であり、
ハーネスで縮むが消えない。本節のベンチ数値は大半が二次情報のため、
判断に使う前に一次情報での確認を推奨(「参考情報源」の節を参照)。

## 9. 次のステップ

1. README.md の手順で Claude Code に導入(最も効果が出る環境)
2. 代表的なタスク2〜3件をSonnet 5+フレームワークで実行し、過去にFableで得た
   成果物(手元にあるもの)と品質を比較して基準線を把握する
3. 差が残る領域があればSONNET-FABLE-COREの該当セクションに具体指示を追記

## 参考情報源

一次情報(Anthropic公式):

- [Redeploying Claude Fable 5](https://www.anthropic.com/news/redeploying-fable-5) — 提供変更の根拠
- [Prompting Claude Sonnet 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5) — §2の「字義通り解釈」「自己検証の誘発」、§3(4)の「網羅優先レビュー」の根拠
- [Prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
- [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) — §3外部メモリの根拠
- [How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) — 委譲設計(中核§4)の根拠
- [Prompting Claude Opus 4.8](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-4-8) — §8 の「字義通り解釈は世代共通」「ツール・委譲の過小使用」「網羅優先レビューは Opus にも必要」の根拠
- [Introducing Claude Opus 4.8](https://www.anthropic.com/news/claude-opus-4-8) — §8 の「自己検証はネイティブ(欠陥見逃し約1/4)」の根拠
- [What's new in Claude Opus 4.8](https://platform.claude.com/docs/en/about-claude/models/whats-new-claude-4-8) — effort デフォルト等の根拠

二次情報(非公式。日付・価格・ベンチ数値はここ由来のため、判断に使う前に一次情報での再確認を推奨):

- [Fable 5 usage-credits切替の解説 (digitalapplied.com)](https://www.digitalapplied.com/blog/claude-fable-5-usage-credits-july-7-pricing-guide-2026)
- [サブスク復帰方針の報道 (BleepingComputer)](https://www.bleepingcomputer.com/news/artificial-intelligence/claude-fable-5-isnt-permanently-leaving-subscriptions-anthropic-says/)
- [Fable 5 vs Sonnet 5 ベンチマーク (BenchLM)](https://benchlm.ai/compare/claude-fable-vs-claude-sonnet-5)
- [Fable 5 vs Opus 4.8 比較 (CodingFleet)](https://codingfleet.com/blog/claude-fable-5-vs-claude-opus-4-8/) — §8 のベンチ数値の主な出典
- [Opus 4.8 実務フィードバック集 (claudeai.dev)](https://claudeai.dev/blog/claude-opus-4-8-feedback/) — §8 の失敗モード(過剰思考・長セッション劣化)の出典
