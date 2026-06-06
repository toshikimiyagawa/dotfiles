#!/bin/bash

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")" && pwd)}"
SRC="$DOTFILES_DIR/.config"
DST="$HOME/.config"

info() { echo "[INFO]  $*"; }
ok()   { echo "[OK]    $*"; }
warn() { echo "[WARN]  $*"; }

# --- 前提状態の判定 ---
if [ -L "$DST" ]; then
  if [ "$(readlink "$DST")" = "$SRC" ]; then
    ok "既に移行済みです: $DST -> $SRC"
    exit 0
  fi
  warn "$DST は別のリンクです ($(readlink "$DST"))。手動で確認してください。"
  exit 1
fi

if [ ! -e "$DST" ]; then
  info "$DST は存在しません。移行対象はありません。'./install.sh' でリンクを作成してください。"
  exit 0
fi

if [ ! -d "$DST" ]; then
  warn "$DST は実ファイルです。手動で確認してください。"
  exit 1
fi

# --- 退避してリンク作成 ---
BAK="$DST.bak.$(date +%Y%m%d%H%M%S)"
mv "$DST" "$BAK"
ok "退避しました: $DST -> $BAK"

ln -s "$SRC" "$DST"
ok "リンクを作成しました: $DST -> $SRC"

# --- 退避先のリーフを走査して repo へ取り込む ---
migrate_entry() {
  local e="$1"
  local rel="${e#"$BAK"/}"
  local repo_path="$SRC/$rel"

  # シンボリックリンク（repo 内を指すものは親リンクで吸収済み）
  if [ -L "$e" ]; then
    local target
    target="$(readlink "$e")"
    case "$target" in
      "$SRC"/*|"$SRC") info "スキップ (repo 内リンク): $rel" ;;
      *) warn "repo 外を指すリンクが残っています: $rel -> $target（退避先に保持）" ;;
    esac
    return 0
  fi

  # repo に同じパスが存在する場合
  if [ -e "$repo_path" ]; then
    if diff -r "$e" "$repo_path" >/dev/null 2>&1; then
      info "一致のためスキップ: $rel"
    else
      warn "衝突: $rel は repo 版と相違します。自動上書きしません（原本は退避先に残存）。"
      echo "----- diff (左: repo / 右: backup) -----"
      diff -u "$repo_path" "$e" || true
      echo "----------------------------------------"
    fi
    return 0
  fi

  # repo に存在しない → コピーする（成否は実際の結果で報告する）
  if mkdir -p "$(dirname "$repo_path")" && cp -R "$e" "$repo_path"; then
    if git -C "$DOTFILES_DIR" check-ignore -q ".config/$rel"; then
      ok "コピー (非追跡 / .gitignore 対象): $rel"
    else
      warn "コピー (追跡対象 → レビューしてコミットしてください): $rel"
    fi
  else
    warn "コピー失敗: $rel（退避先に原本あり）"
  fi
  return 0
}

while IFS= read -r -d '' e; do
  migrate_entry "$e" || warn "処理中にエラー: ${e#"$BAK"/}（継続します）"
done < <(find "$BAK" -mindepth 1 \( -type f -o -type l \) -print0)

# --- サマリ ---
info "移行が完了しました。"
info "退避ディレクトリ: $BAK（内容を確認後、不要なら削除してください）"
info "追跡対象に追加されたファイルは 'git status' で確認し、レビューのうえコミットしてください。"
info "衝突 (WARN) があった場合は退避先の原本を手動で反映してください。"
