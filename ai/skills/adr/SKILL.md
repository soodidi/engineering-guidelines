---
name: adr
description: Rédige un brouillon d'ADR dans engineering-guidelines quand une décision d'architecture n'est couverte par aucun ADR (GLB-001), puis ouvre la PR. Ne tranche pas à la place de l'humain. Ex. /adr choix de la file de messages.
argument-hint: <sujet de la décision>
disable-model-invocation: true
---

Décision à documenter : $ARGUMENTS

Les ADR vivent dans le repo engineering-guidelines, cloné dans `~/Documents/projects/engineering-guidelines` (chemin à confirmer dans `~/.claude/CLAUDE.md`). Toutes les commandes de ce skill s'exécutent dans ce repo, même si tu es lancé depuis un projet.

## 1. Vérifier qu'il manque vraiment un ADR

- `git -C <repo> switch main && git -C <repo> pull --ff-only`.
- Lis `adr/global/README.md` et le README du domaine concerné. Cherche aussi par mots-clés dans `adr/` (`grep -ri`).
- Si un ADR couvre déjà le sujet, arrête-toi : cite-le et explique comment il s'applique. S'il le couvre mal, propose plutôt un ADR qui le **remplace** (GLB-001 : un ADR accepté ne se réécrit pas sur le fond).

## 2. Cadrer avec l'humain

Demande en une seule fois ce qui te manque :

- le **contexte** : problème, contraintes, ce qui oblige à décider maintenant ;
- les **options** sérieuses, au moins deux, avec leurs coûts ;
- sa **préférence**, s'il en a une.

Si le choix n'est pas fait, présente les options avec ta recommandation argumentée et **attends sa décision**. L'ADR écrit la décision de l'humain, pas la tienne.

## 3. Rédiger

- Domaine et préfixe (GLB-001) : `global` GLB, `frontend` FE, `backend` BE, `devops` OPS, `android` AND, `ios` IOS. Numéro = le plus grand du dossier + 1, sur trois chiffres.
- Fichier `adr/<domaine>/<PRÉFIXE>-<nnn>-<titre-en-kebab-case>.md`, à partir de `adr/template.md`. Statut **Proposé**, date du jour, auteurs : l'humain et Claude.
- En français (GLB-007). Règles formulées en **DOIT / NE DOIT PAS / DEVRAIT / PEUT**, vérifiables. La section « Mise en application » dit comment la règle est contrôlée (lint, CI, test d'architecture) ou écrit « revue de code uniquement ».
- Mets à jour le `README.md` du domaine : une ligne dans « Règles en bref » et une ligne dans l'index.
- Si l'ADR change une règle outillée (lint, CI, permissions, kit IA), liste dans la PR les changements à faire ensuite dans `shared-libs` ou `boilerplates`. Ne les fais pas dans la même PR.

## 4. Livrer

- Branche `adr/<sujet>`, commit `adr(<domaine>): add <PRÉFIXE>-<nnn> <titre court en anglais>` (type `adr` de GLB-002).
- `git push -u origin adr/<sujet>` puis `gh pr create` : résumé de la décision, options écartées, impacts sur les projets existants.
- **Ne fusionne jamais la PR.** Termine par son lien et rappelle que l'ADR reste **Proposé** jusqu'à ce que l'humain le passe en **Accepté**.
