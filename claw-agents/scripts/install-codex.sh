#!/usr/bin/env bash

set -euo pipefail

# Install claw-agents into the Codex skills directory.
# Usage:
#   bash scripts/install-codex.sh
#   bash scripts/install-codex.sh --link

SKILL_NAME="claw-agents"
CODEX_SKILLS_DIR="$HOME/.codex/skills"
TARGET_DIR="$CODEX_SKILLS_DIR/$SKILL_NAME"
SOURCE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Installing $SKILL_NAME for Codex..."

if [[ ! -f "$SOURCE_DIR/SKILL.md" ]]; then
  echo "Error: SKILL.md not found in $SOURCE_DIR" >&2
  exit 1
fi

mkdir -p "$CODEX_SKILLS_DIR"

if [[ -e "$TARGET_DIR" ]]; then
  if [[ -L "$TARGET_DIR" ]]; then
    EXISTING="$(readlink "$TARGET_DIR")"
    echo "Already installed as symlink -> $EXISTING"
    echo "To reinstall, remove it first: rm $TARGET_DIR"
    exit 0
  fi

  echo "Already installed at $TARGET_DIR"
  echo "To reinstall, remove it first: rm -rf $TARGET_DIR"
  exit 0
fi

if [[ "${1:-}" == "--link" ]]; then
  ln -s "$SOURCE_DIR" "$TARGET_DIR"
  echo "Symlinked: $TARGET_DIR -> $SOURCE_DIR"
else
  cp -R "$SOURCE_DIR" "$TARGET_DIR"
  echo "Copied to: $TARGET_DIR"
fi

echo ""
echo "Done. Start a new Codex session and use:"
echo "  /claw-agents setup"
echo "  /claw-agents doctor"
