#!/usr/bin/env bash
# Installe la configuration Claude Code globale (GLB-011) par liens symboliques :
# un `git pull` de engineering-guidelines suffit ensuite à la mettre à jour.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
target="$HOME/.claude"
mkdir -p "$target/skills"

link() {
  local src=$1 dest=$2
  if [[ -e $dest && ! -L $dest ]]; then
    mv "$dest" "$dest.backup-$(date +%Y%m%d%H%M%S)"
    echo "• ancien $(basename "$dest") sauvegardé à côté"
  fi
  ln -sfn "$src" "$dest"
  echo "✓ $dest → $src"
}

link "$here/CLAUDE.global.md" "$target/CLAUDE.md"
for skill in "$here"/skills/*/; do
  link "${skill%/}" "$target/skills/$(basename "$skill")"
done
