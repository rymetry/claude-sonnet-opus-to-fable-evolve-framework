#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# install.sh — Sonnet 5 → Fable 5級 Elevation Framework の導入
#
# 使い方(プロジェクト単位で導入。導入したいプロジェクトのルートで実行):
#   cd /path/to/your-project
#   bash /path/to/claude-sonnet-to-fable-evolve-framework/scripts/install.sh
#
# オプション:
#   --force   既存スキルを確認なしで上書き(フレームワーク更新時の再導入用)
#   --global  プロジェクトではなく ~/.claude/(全プロジェクト共通)に導入
#
# やること(プロジェクト導入時。--global は対象が ~/.claude/ になる):
#   1. skills/ 配下の全スキルを <project>/.claude/skills/ にコピー
#   2. core/FABLE-CORE.md を <project>/.claude/fable/FABLE-CORE.md にコピー(常に上書き)
#   3. <project>/CLAUDE.md に @.claude/fable/FABLE-CORE.md を追記
#      (空行 + 1 行。FABLE-CORE の import 行が既にあればスキップ)
#
# 変更前に前提を一括検証し、検証に失敗した場合は何も変更せず終了する。
# 再実行しても安全(冪等)。非対話環境(CI 等)では既存スキルの上書き確認は
# 出ず、スキップして続行する。
# =============================================================================

FORCE=0
GLOBAL=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --global) GLOBAL=1 ;;
    *) echo "❌ 不明な引数: $arg (使い方: bash scripts/install.sh [--force] [--global])"; exit 1 ;;
  esac
done

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
  IMPORT_LINE='@~/.claude/fable/FABLE-CORE.md'
else
  TARGET_ROOT="$(pwd)"
  TARGET_DESC="プロジェクト ($TARGET_ROOT)"
  CLAUDE_DIR="$TARGET_ROOT/.claude"
  CLAUDE_MD="$TARGET_ROOT/CLAUDE.md"
  # プロジェクトの CLAUDE.md からの相対パスで参照する(リテラルにスペースを
  # 含まないため、プロジェクトの絶対パスにスペースがあっても壊れない)
  IMPORT_LINE='@.claude/fable/FABLE-CORE.md'
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

[[ -f "$REPO_ROOT/core/FABLE-CORE.md" ]] || {
  echo "❌ core/FABLE-CORE.md が見つかりません。フレームワークのリポジトリ配下の"
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
echo "  Sonnet 5 → Fable 5級 Elevation Framework install"
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
# 2. FABLE-CORE の配置
# ---------------------------------------------------------------------------
echo ""
echo "📄 Installing FABLE-CORE to $FABLE_DST ..."
mkdir -p "$FABLE_DST"
cp "$REPO_ROOT/core/FABLE-CORE.md" "$FABLE_DST/FABLE-CORE.md"
echo "  ✅ FABLE-CORE.md"

# ---------------------------------------------------------------------------
# 3. CLAUDE.md に @import 行を追記(冪等)
#    「@ で始まり FABLE-CORE.md で終わる行」があれば導入済みとみなす。
#    (@core/FABLE-CORE.md 等の別経路 import との二重ロードを防ぐ。
#     コメントアウト行や部分文字列は誤検知しない)
# ---------------------------------------------------------------------------
echo ""
if [[ -f "$CLAUDE_MD" ]] && grep -qE '^@.*FABLE-CORE\.md[[:space:]]*$' "$CLAUDE_MD"; then
  echo "🔗 CLAUDE.md には既に FABLE-CORE の import 行があります(変更なし)"
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
