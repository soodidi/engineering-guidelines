#!/usr/bin/env bash
# Installe la configuration Claude Code commune (GLB-011) dans le dossier racine, par liens symboliques :
# un `git pull` de engineering-guidelines suffit ensuite à la mettre à jour.
# Dossier racine : celui qui contient engineering-guidelines, boilerplates et shared-libs, où qu'il soit.
# Rien n'est écrit dans ~/.claude : CLAUDE.md vaut pour toute session lancée dans le dossier racine ou en dessous,
# les skills communs seulement pour une session lancée dans le dossier racine lui-même.
set -euo pipefail
shopt -s nullglob
here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
repo="$(basename "$(dirname "$here")")"
root="$(cd "$here/../.." && pwd)"
backup="$root/.claude/backup-$(date +%Y%m%d%H%M%S)"
mkdir -p "$root/.claude/skills"

# Liens relatifs : le dossier racine peut être déplacé sans réinstaller.
link() {
  local src=$1 dest=$2
  if [[ -e $dest && ! -L $dest ]]; then
    # Hors de skills/ : une copie de sauvegarde y serait chargée comme un skill en double.
    mkdir -p "$backup"
    mv "$dest" "$backup/"
    echo "• ancien $(basename "$dest") sauvegardé dans $backup"
  fi
  ln -sfn "$src" "$dest"
  echo "✓ $dest → $src"
}

link "$repo/ai/CLAUDE.global.md" "$root/CLAUDE.md"
for skill in "$here"/skills/*/; do
  name="$(basename "$skill")"
  link "../../$repo/ai/skills/$name" "$root/.claude/skills/$name"
done

# Skills retirés du repo : leurs liens seraient cassés.
for dest in "$root/.claude/skills"/*; do
  if [[ -L $dest && ! -e $dest ]]; then
    rm "$dest"
    echo "✗ $dest supprimé (lien cassé)"
  fi
done
