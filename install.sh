#!/bin/bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
ZSHRC="$HOME/.zshrc"
AUTO_UPDATE_BLOCK_START="# >>> dotai auto-update >>>"
AUTO_UPDATE_BLOCK_END="# <<< dotai auto-update <<<"
AUTO_UPDATE_LINE="source \"$DOTFILES_DIR/auto-update.sh\""

OPENCODE_DIR="$HOME/.config/opencode"

ensure_link() {
  local src="$1"
  local dst="$2"

  # If destination is a real directory (not a symlink), remove it first
  if [ -d "$dst" ] && [ ! -L "$dst" ]; then
    rm -rf "$dst"
  fi

  ln -sfn "$src" "$dst"
  printf '   %s -> %s\n' "$dst" "$src"
}

ensure_auto_update_hook() {
  local block
  block="${AUTO_UPDATE_BLOCK_START}"$'\n'"${AUTO_UPDATE_LINE}"$'\n'"${AUTO_UPDATE_BLOCK_END}"

  if [ ! -f "$ZSHRC" ]; then
    printf '%s\n' "$block" > "$ZSHRC"
    echo "✅ Created ~/.zshrc with auto-update hook"
    return
  fi

  if grep -Fq "$AUTO_UPDATE_BLOCK_START" "$ZSHRC"; then
    if grep -Fq "$AUTO_UPDATE_LINE" "$ZSHRC"; then
      echo "✅ Auto-update hook already in ~/.zshrc"
      return
    fi
    printf '\n%s\n' "$block" >> "$ZSHRC"
    echo "✅ Auto-update hook updated in ~/.zshrc"
    return
  fi

  printf '\n%s\n' "$block" >> "$ZSHRC"
  echo "✅ Auto-update hook added to ~/.zshrc"
}

echo "Installing dotai from: $DOTFILES_DIR"

if [ -d "$OPENCODE_DIR" ]; then
  echo "✅ Found $OPENCODE_DIR, creating symlinks:"
  ensure_link "$DOTFILES_DIR/setting/AGENTS.md" "$OPENCODE_DIR/AGENTS.md"
  ensure_link "$DOTFILES_DIR/setting/skills" "$OPENCODE_DIR/skills"
else
  echo "⚠️  $OPENCODE_DIR not found, skipping symlinks"
fi

CLAUDE_DIR="$HOME/.claude"
if [ -d "$CLAUDE_DIR" ]; then
  echo "✅ Found $CLAUDE_DIR, creating symlinks:"
  ensure_link "$DOTFILES_DIR/setting/AGENTS.md" "$CLAUDE_DIR/CLAUDE.md"
  ensure_link "$DOTFILES_DIR/setting/skills" "$CLAUDE_DIR/skills"
  if [ -f "$DOTFILES_DIR/setting/mcp.json" ]; then
    ensure_link "$DOTFILES_DIR/setting/mcp.json" "$CLAUDE_DIR/.mcp.json"
  fi
else
  echo "⚠️  $CLAUDE_DIR not found, skipping symlinks"
fi

CODEX_DIR="$HOME/.codex"
if [ -d "$CODEX_DIR" ]; then
  echo "✅ Found $CODEX_DIR, creating symlinks:"
  ensure_link "$DOTFILES_DIR/setting/AGENTS.md" "$CODEX_DIR/AGENTS.md"
else
  echo "⚠️  $CODEX_DIR not found, skipping symlinks"
fi

ensure_auto_update_hook

# Install git hooks (post-merge: auto-sync after pull)
HOOKS_SRC="$DOTFILES_DIR/hooks"
HOOKS_DST="$DOTFILES_DIR/.git/hooks"
if [ -d "$HOOKS_SRC" ] && [ -d "$DOTFILES_DIR/.git" ]; then
  for hook in "$HOOKS_SRC"/*; do
    [ -f "$hook" ] || continue
    hook_name="$(basename "$hook")"
    cp "$hook" "$HOOKS_DST/$hook_name"
    chmod +x "$HOOKS_DST/$hook_name"
  done
  echo "✅ Git hooks installed"
fi

# Sync external skills from other repositories
bash "$DOTFILES_DIR/sync-external.sh"

# Sync MCP server config to OpenCode and Codex
bash "$DOTFILES_DIR/sync-mcp.sh"

echo ""
echo "Done!"
