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
- Au moins **1 approbation** d'une autre personne. 2 approbations pour : migrations de base de données, changements d'auth/sécurité, infrastructure de production.
- La CI DOIT être verte avant fusion.
- L'auteur fusionne sa propre PR une fois approuvée.

**Commentaires**
- Préfixer les commentaires pour lever l'ambiguïté :
  - `bloquant:` doit être traité avant fusion ;
  - `suggestion:` à l'appréciation de l'auteur ;
  - `question:` besoin de comprendre ;
  - `nit:` détail mineur, non bloquant.
- Le style (formatage, ordre des imports…) n'est PAS un sujet de revue : c'est le rôle du linter.
- Délai de première revue visé : **1 jour ouvré**.

**Code généré par IA**
- Le code produit avec un assistant IA est relu exactement comme le reste. L'auteur de la PR en est responsable et DOIT pouvoir l'expliquer.

## Alternatives envisagées

- **Pair/mob programming à la place des revues** : excellent ponctuellement, pas généralisable.
- **Pas de limite de taille** : favorise les revues superficielles.

## Conséquences

- ✅ Revues plus rapides et plus utiles.
- ⚠️ Demande de découper le travail en amont.

## Mise en application

- `.github/pull_request_template.md` dans chaque repo.
- Protection de branche : approbations requises, `CODEOWNERS` pour les zones sensibles (migrations, infra, auth).
- Action de labellisation de taille de PR (avertissement au-delà de 400 lignes, non bloquant).
