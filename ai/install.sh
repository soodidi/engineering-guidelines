#!/usr/bin/env bash
# Installe la configuration Claude Code commune (GLB-011) dans le dossier de travail, par liens symboliques :
# un `git pull` de engineering-guidelines suffit ensuite à la mettre à jour.
# Dossier de travail : celui qui contient engineering-guidelines, boilerplates et shared-libs, où qu'il soit.
# Rien n'est écrit dans ~/.claude : la configuration ne vaut que pour les sessions lancées dans ce dossier.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(basename "$(dirname "$here")")"
root="$(cd "$here/../.." && pwd)"
mkdir -p "$root/.claude/skills"

# Liens relatifs : le dossier de travail peut être déplacé sans réinstaller.
link() {
  local src=$1 dest=$2
  if [[ -e $dest && ! -L $dest ]]; then
    mv "$dest" "$dest.backup-$(date +%Y%m%d%H%M%S)"
    echo "• ancien $(basename "$dest") sauvegardé à côté"
  fi
  ln -sfn "$src" "$dest"
  echo "✓ $dest → $src"
}

link "$repo/ai/CLAUDE.global.md" "$root/CLAUDE.md"
for skill in "$here"/skills/*/; do
  name="$(basename "$skill")"
  link "../../$repo/ai/skills/$name" "$root/.claude/skills/$name"
done
