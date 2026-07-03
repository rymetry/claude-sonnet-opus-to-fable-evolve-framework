#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# install.sh — Sonnet 5 → Fable 5級 Elevation Framework を Claude Code に導入
#
# 使い方:
#   bash scripts/install.sh          # 対話モード(既存スキルの上書き前に確認)
#   bash scripts/install.sh --force  # 確認なしで上書き
#
# やること:
#   1. skills/ 配下の 3 スキルを ~/.claude/skills/ にコピー
#   2. core/FABLE-CORE.md を ~/.claude/fable/FABLE-CORE.md にコピー
#   3. ~/.claude/CLAUDE.md に @import 行を 1 行追記(既にあればスキップ)
#
# 再実行しても安全(冪等)。更新を取り込むには再実行するだけでよい。
# =============================================================================

FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    *) echo "❌ 不明な引数: $arg (使い方: bash scripts/install.sh [--force])"; exit 1 ;;
  esac
done

# スクリプト自身の位置からリポジトリルートを解決(パスにスペースがあっても動く)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CLAUDE_DIR="$HOME/.claude"
SKILLS_DST="$CLAUDE_DIR/skills"
FABLE_DST="$CLAUDE_DIR/fable"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
# チルダ表記で追記する(CLAUDE.md の @import は ~ を解釈する。絶対パスだと
# ホームディレクトリにスペースを含む環境で無音で壊れる)
IMPORT_LINE='@~/.claude/fable/FABLE-CORE.md'
SKILLS=(deep-task adversarial-review hard-problem)

[[ -f "$REPO_ROOT/core/FABLE-CORE.md" ]] || {
  echo "❌ core/FABLE-CORE.md が見つかりません。リポジトリ内から実行してください。"; exit 1;
}

echo ""
echo "==================================================="
echo "  Sonnet 5 → Fable 5級 Elevation Framework install"
echo "  Source: $REPO_ROOT"
echo "  Target: $CLAUDE_DIR"
echo "==================================================="
echo ""

# ---------------------------------------------------------------------------
# 1. スキルのコピー
# ---------------------------------------------------------------------------
echo "📦 Installing skills to $SKILLS_DST ..."
mkdir -p "$SKILLS_DST"

for skill in "${SKILLS[@]}"; do
  src="$REPO_ROOT/skills/$skill"
  dst="$SKILLS_DST/$skill"
  if [[ -d "$dst" && "$FORCE" -ne 1 ]]; then
    read -r -p "  ⚠️  $skill は既に存在します。上書きしますか? [y/N] " answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
      echo "  ⏭  $skill をスキップしました"
      continue
    fi
  fi
  rm -rf "$dst"
  cp -R "$src" "$dst"
  echo "  ✅ $skill"
done

# ---------------------------------------------------------------------------
# 2. FABLE-CORE の配置(スペースなし固定パス。@import はスペース入りパスで
#    無音で失敗する既知バグがあるため、clone 先を直接参照しない)
# ---------------------------------------------------------------------------
echo ""
echo "📄 Installing FABLE-CORE to $FABLE_DST ..."
mkdir -p "$FABLE_DST"
cp "$REPO_ROOT/core/FABLE-CORE.md" "$FABLE_DST/FABLE-CORE.md"
echo "  ✅ FABLE-CORE.md"

# ---------------------------------------------------------------------------
# 3. ~/.claude/CLAUDE.md に @import 行を追記(冪等)
# ---------------------------------------------------------------------------
echo ""
if [[ -f "$CLAUDE_MD" ]] && grep -qF "$IMPORT_LINE" "$CLAUDE_MD"; then
  echo "🔗 CLAUDE.md には既にインポート行があります(変更なし)"
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
echo "   1. claude を起動し「利用可能なスキルを教えて」で deep-task /"
echo "      adversarial-review / hard-problem が見えることを確認"
echo "   2. 複雑なタスクを依頼して 計画 → STATE.md 作成 → 検証 の流れが"
echo "      発動するか確認(明示起動は「deep-taskで進めて」)"
echo ""
