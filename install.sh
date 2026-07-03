#!/usr/bin/env bash
# Symlink this repo's skills and subagents into Claude Code's config dirs.
# Safe to re-run. Works on macOS and Ubuntu. Existing symlinks are refreshed;
# real files/dirs at the target are left untouched and reported.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$REPO/skills"
AGENTS_SRC="$REPO/agents"
SKILLS_DST="${CLAUDE_HOME:-$HOME/.claude}/skills"
AGENTS_DST="${CLAUDE_HOME:-$HOME/.claude}/agents"

mkdir -p "$SKILLS_DST" "$AGENTS_DST"

link() { # $1 = source path, $2 = destination path
  local src="$1" dst="$2"
  if [ -L "$dst" ]; then
    ln -sfn "$src" "$dst"; echo "  refreshed  $(basename "$dst")"
  elif [ -e "$dst" ]; then
    echo "  SKIPPED    $(basename "$dst")  (real file/dir already there — remove it to link)"
  else
    ln -s "$src" "$dst"; echo "  linked     $(basename "$dst")"
  fi
}

echo "Skills → $SKILLS_DST"
if [ -d "$SKILLS_SRC" ]; then
  for d in "$SKILLS_SRC"/*/; do [ -d "$d" ] && link "${d%/}" "$SKILLS_DST/$(basename "$d")"; done
fi

echo "Agents → $AGENTS_DST"
if [ -d "$AGENTS_SRC" ]; then
  for f in "$AGENTS_SRC"/*.md; do [ -e "$f" ] && link "$f" "$AGENTS_DST/$(basename "$f")"; done
fi

# Knowledge base at a fixed path so skills find it regardless of clone location.
KNOW_DST="${CLAUDE_HOME:-$HOME/.claude}/bb-knowledge"
echo "Knowledge → $KNOW_DST"
[ -d "$REPO/knowledge" ] && link "$REPO/knowledge" "$KNOW_DST"

echo "Done. Skills read deep playbooks from $KNOW_DST."
echo "Restart Claude Code (or reload) to pick up new skills."
