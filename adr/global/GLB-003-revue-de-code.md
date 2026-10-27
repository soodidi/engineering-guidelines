# GLB-003 : Revue de code et pull requests

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : global
- **Auteurs** : Mo, Claude

## Contexte

Les grosses PR sont mal relues : au-delà de quelques centaines de lignes, la qualité de la revue chute. Sans conventions, les revues dérivent vers des débats de style que les outils devraient trancher.

## Décision

**Taille et contenu**

- Une PR DEVRAIT faire moins de **400 lignes modifiées** (hors fichiers générés, lockfiles, snapshots).
- Une PR DOIT traiter **un seul sujet**. Refactoring et changement fonctionnel vont dans des PR séparées.
- La description DOIT suivre le template : *Quoi*, *Pourquoi*, *Comment tester*, captures pour l'UI, ADR concernés.

**Validation**

- La CI DOIT être verte avant fusion.
- **À partir de deux personnes sur le projet** : au moins **1 approbation** d'une autre personne, 2 pour les migrations de base de données, les changements d'auth/sécurité et l'infrastructure de production. L'auteur fusionne sa propre PR une fois approuvée.
- **Seul sur le projet** : aucune approbation n'est requise, personne d'autre ne pouvant approuver. La relecture est assurée par les agents de contrôle de GLB-011, et la PR est fusionnée automatiquement une fois la CI verte. Les règles ci-dessus s'appliquent dès qu'une deuxième personne rejoint le projet.

**Commentaires**

- Préfixer les commentaires pour lever l'ambiguïté :
  - `bloquant:` doit être traité avant fusion ;
  - `suggestion:` à l'appréciation de l'auteur ;
  - `question:` besoin de comprendre ;
  - `nit:` détail mineur, non bloquant.
- Le style (formatage, ordre des imports…) n'est PAS un sujet de revue : c'est le rôle du linter.
- Délai de première revue visé : **1 jour ouvré**.

**Code généré par IA**

- Le code produit avec un assistant IA est relu exactement comme le reste (seul sur le projet : par les agents de contrôle). L'auteur de la PR en est responsable et DOIT pouvoir l'expliquer.

## Alternatives envisagées

- **Pair/mob programming à la place des revues** : excellent ponctuellement, pas généralisable.
- **Pas de limite de taille** : favorise les revues superficielles.

## Conséquences

- ✅ Revues plus rapides et plus utiles.
- ⚠️ Demande de découper le travail en amont.

## Mise en application

- `.github/pull_request_template.md` dans chaque repo.
- Protection de branche : checks CI requis ; approbations requises et `CODEOWNERS` pour les zones sensibles (migrations, infra, auth) à partir de deux personnes, 0 approbation tant qu'on est seul.
- Action de labellisation de taille de PR (avertissement au-delà de 400 lignes, non bloquant).
