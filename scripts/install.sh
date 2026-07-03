#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# install.sh — Claude Evolve Framework の導入(Sonnet 用 / Opus 用)
#
# 使い方(プロジェクト単位で導入。導入したいプロジェクトのルートで実行):
#   cd /path/to/your-project
#   bash /path/to/claude-sonnet-to-fable-evolve-framework/scripts/install.sh
#
# オプション:
#   --model sonnet|opus  導入する core を選択(デフォルト: sonnet)
#                        sonnet → core/SONNET-FABLE-CORE.md(Sonnet を Fable 級に引き上げる)
#                        opus   → core/OPUS-FABLE-CORE.md(Opus 用の軽量ハーネス)
#   --force              既存スキルを確認なしで上書き(フレームワーク更新時の再導入用)
#   --global             プロジェクトではなく ~/.claude/(全プロジェクト共通)に導入
#
# やること(プロジェクト導入時。--global は対象が ~/.claude/ になる):
#   1. skills/ 配下の全スキルを <project>/.claude/skills/ にコピー(両モデル共用)
#   2. 選択した core を <project>/.claude/fable/CORE.md にコピー(常に上書き)
#      → モデルを乗り換えたら --model を変えて再実行するだけで中身が差し替わる。
#        1プロジェクトに core は常に1つで、import 行は変わらない
#   3. <project>/CLAUDE.md に @.claude/fable/CORE.md を追記
#      (空行 + 1 行。core の import 行が既にあればスキップ)
#
# 変更前に前提を一括検証し、検証に失敗した場合は何も変更せず終了する。
# 再実行しても安全(冪等)。非対話環境(CI 等)では既存スキルの上書き確認は
# 出ず、スキップして続行する。
# =============================================================================

FORCE=0
GLOBAL=0
MODEL="sonnet"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1 ;;
    --global) GLOBAL=1 ;;
    --model)
      [[ $# -ge 2 ]] || { echo "❌ --model には値が必要です (sonnet|opus)"; exit 1; }
      MODEL="$2"; shift ;;
    --model=*) MODEL="${1#*=}" ;;
    *) echo "❌ 不明な引数: $1 (使い方: bash scripts/install.sh [--model sonnet|opus] [--force] [--global])"; exit 1 ;;
  esac
  shift
done

case "$MODEL" in
  sonnet) CORE_BASENAME="SONNET-FABLE-CORE.md" ;;
  opus)   CORE_BASENAME="OPUS-FABLE-CORE.md" ;;
  *) echo "❌ --model は sonnet または opus を指定してください(指定値: $MODEL)"; exit 1 ;;
esac

# スクリプト自身の位置からリポジトリルートを解決(パスにスペースがあっても動く)
SCRIPT_SOURCE="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ "$GLOBAL" -eq 1 ]]; then
  : "${HOME:?❌ HOME が設定されていません}"
  TARGET_DESC="グローバル ($HOME/.claude)"
  CLAUDE_DIR="$HOME/.claude"
  CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
  # チルダ表記で追記する(CLAUDE.md の @import は ~ を解釈する。絶対パスだと
  # ホームディレクトリにスペースを含む環境で無音で壊れる)
  IMPORT_LINE='@~/.claude/fable/CORE.md'
else
  TARGET_ROOT="$(pwd)"
  TARGET_DESC="プロジェクト ($TARGET_ROOT)"
  CLAUDE_DIR="$TARGET_ROOT/.claude"
  CLAUDE_MD="$TARGET_ROOT/CLAUDE.md"
  # プロジェクトの CLAUDE.md からの相対パスで参照する(リテラルにスペースを
  # 含まないため、プロジェクトの絶対パスにスペースがあっても壊れない)
  IMPORT_LINE='@.claude/fable/CORE.md'
fi
SKILLS_DST="$CLAUDE_DIR/skills"
FABLE_DST="$CLAUDE_DIR/fable"

# 対話可能か(stdin が端末か)。非対話では確認プロンプトを出さずスキップする
INTERACTIVE=0
[[ -t 0 ]] && INTERACTIVE=1

# スキルは skills/ 配下を走査して収集(ハードコードしない)
SKILLS=()
for dir in "$REPO_ROOT"/skills/*/; do
  [[ -f "${dir}SKILL.md" ]] && SKILLS+=("$(basename "$dir")")
done

# ---------------------------------------------------------------------------
# 0. プリフライト検証 — 失敗したら何も変更せずに終了する
# ---------------------------------------------------------------------------
PREFLIGHT_OK=1

CORE_SRC="$REPO_ROOT/core/$CORE_BASENAME"
[[ -f "$CORE_SRC" ]] || {
  echo "❌ core/$CORE_BASENAME が見つかりません。フレームワークのリポジトリ配下の"
  echo "   scripts/install.sh を実行してください。"
  PREFLIGHT_OK=0
}
[[ ${#SKILLS[@]} -gt 0 ]] || {
  echo "❌ skills/ 配下にスキル(SKILL.md を含むディレクトリ)が見つかりません。"
  PREFLIGHT_OK=0
}
if [[ -d "$CLAUDE_MD" ]]; then
  echo "❌ $CLAUDE_MD がディレクトリです。ファイルである必要があります。"
  PREFLIGHT_OK=0
elif [[ -e "$CLAUDE_MD" && ( ! -r "$CLAUDE_MD" || ! -w "$CLAUDE_MD" ) ]]; then
  echo "❌ $CLAUDE_MD を読み書きできません。権限を確認してください。"
  PREFLIGHT_OK=0
fi

if [[ "$PREFLIGHT_OK" -ne 1 ]]; then
  echo ""
  echo "⛔ 事前検証に失敗したため、何も変更せずに終了しました。"
  exit 1
fi

echo ""
echo "==================================================="
echo "  Claude Evolve Framework install"
echo "  Model:  $MODEL (core/$CORE_BASENAME)"
echo "  Source: $REPO_ROOT"
echo "  Target: $TARGET_DESC"
echo "==================================================="
echo ""

if [[ "$GLOBAL" -ne 1 && "$TARGET_ROOT" == "$REPO_ROOT" ]]; then
  echo "ℹ️  フレームワーク自身のリポジトリが導入先です(このリポジトリで"
  echo "   スキルを有効化する意図ならこのまま進めて問題ありません)。"
  echo ""
fi

# ---------------------------------------------------------------------------
# 1. スキルのコピー
# ---------------------------------------------------------------------------
echo "📦 Installing skills to $SKILLS_DST ..."
mkdir -p "$SKILLS_DST"

for skill in "${SKILLS[@]}"; do
  src="$REPO_ROOT/skills/$skill"
  dst="$SKILLS_DST/$skill"
  # ディレクトリ以外(通常ファイル・壊れた symlink 含む)も既存物として扱う
  if [[ ( -e "$dst" || -L "$dst" ) && "$FORCE" -ne 1 ]]; then
    if [[ "$INTERACTIVE" -eq 1 ]]; then
      read -r -p "  ⚠️  $skill は既に存在します。上書きしますか? [y/N] " answer
      if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo "  ⏭  $skill をスキップしました"
        continue
      fi
    else
      echo "  ⏭  $skill は既に存在するためスキップしました(上書きするには --force)"
      continue
    fi
  fi
  rm -rf "$dst"
  cp -R "$src" "$dst"
  echo "  ✅ $skill"
done

# ---------------------------------------------------------------------------
# 2. core の配置(選択したモデル用の core を CORE.md として配置)
# ---------------------------------------------------------------------------
echo ""
echo "📄 Installing core ($CORE_BASENAME) to $FABLE_DST/CORE.md ..."
mkdir -p "$FABLE_DST"
cp "$CORE_SRC" "$FABLE_DST/CORE.md"
echo "  ✅ CORE.md ($MODEL)"
# 旧レイアウト(FABLE-CORE.md 直接参照)からの移行: 旧ファイルが残っている場合は
# 中身を選択した core で更新し、旧 import 行が生きていても同じ内容が読まれるようにする
if [[ -f "$FABLE_DST/FABLE-CORE.md" ]]; then
  cp "$CORE_SRC" "$FABLE_DST/FABLE-CORE.md"
  echo "  ℹ️  旧レイアウトの FABLE-CORE.md も更新しました(旧 import 行との互換)"
fi

# ---------------------------------------------------------------------------
# 3. CLAUDE.md に @import 行を追記(冪等)
#    「@ で始まり CORE.md で終わる行」があれば導入済みとみなす。
#    (@core/SONNET-FABLE-CORE.md・旧 @.claude/fable/FABLE-CORE.md 等の
#     別経路 import との二重ロードを防ぐ。コメントアウト行や部分文字列は誤検知しない)
# ---------------------------------------------------------------------------
echo ""
if [[ -f "$CLAUDE_MD" ]] && grep -qE '^@.*CORE\.md[[:space:]]*$' "$CLAUDE_MD"; then
  echo "🔗 CLAUDE.md には既に core の import 行があります(変更なし)"
else
  {
    [[ -f "$CLAUDE_MD" && -s "$CLAUDE_MD" ]] && echo ""
    echo "$IMPORT_LINE"
  } >> "$CLAUDE_MD"
  echo "🔗 $CLAUDE_MD にインポート行を追記しました: $IMPORT_LINE"
fi

# ---------------------------------------------------------------------------
# 完了
# ---------------------------------------------------------------------------
echo ""
echo "🎉 導入完了。動作確認:"
if [[ "$GLOBAL" -eq 1 ]]; then
  echo "   1. claude を起動し「利用可能なスキルを教えて」で deep-task /"
else
  echo "   1. 導入先プロジェクトで claude を起動し「利用可能なスキルを教えて」で deep-task /"
fi
echo "      adversarial-review / hard-problem が見えることを確認"
echo "   2. 複雑なタスクを依頼して 計画 → STATE.md 作成 → 検証 の流れが"
echo "      発動するか確認(明示起動は「deep-taskで進めて」)"
echo ""
