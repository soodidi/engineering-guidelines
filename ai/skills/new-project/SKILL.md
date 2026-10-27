---
name: new-project
description: Crée un nouveau projet à partir du repo boilerplates (GLB-010) : copie, renommage, repo GitHub, protection de main, labels, secrets à configurer. À utiliser pour démarrer une nouvelle app, ex. /new-project.
argument-hint: "[nom-du-projet]"
disable-model-invocation: true
---

Création d'un projet : $ARGUMENTS

Les boilerplates sont dans `~/Documents/projects/boilerplates`, les nouveaux projets vont dans `~/Documents/projects/<nom>`. Suis les étapes dans l'ordre et ne saute pas les confirmations.

## 1. Cadrer

Demande en une seule fois ce qui manque :

- **Nom** du projet en kebab-case, et une **description** d'une phrase.
- **Briques** : web (`web-react-vite`), api (`api-nestjs`), infra (`infra-scaleway`), android (`android-compose`), ios (`ios-swiftui`). Une brique = un repo. Avec plusieurs briques, les repos s'appellent `<nom>-web`, `<nom>-api`, `<nom>-infra`, `<nom>-android`, `<nom>-ios` ; avec une seule, `<nom>`.
- **Identifiant d'app** pour Android et iOS si concernés (ex. `fr.soodidi.monapp`).
- **Thème** (GLB-012) : épuré (`clean`), chaleureux (`warm`) ou coloré (`vivid`). Si l'humain hésite, décris les trois thèmes à partir du tableau de GLB-012.
- **Visibilité** GitHub : privé par défaut.
- Garder la feature d'exemple **notes** comme modèle jusqu'à la première vraie feature (recommandé), ou la supprimer tout de suite.

Récapitule ensuite le plan (repos créés, renommages) et attends un « ok ».

## 2. Prérequis

- `gh auth status` doit être connecté. `node -v` doit respecter le `.nvmrc` du boilerplate.
- `git -C ~/Documents/projects/boilerplates pull --ff-only` pour partir de la dernière version.
- Le dossier cible ne doit pas exister.

## 3. Copier et renommer (pour chaque brique)

- `rsync -a --exclude node_modules --exclude dist --exclude build --exclude .gradle --exclude .terraform --exclude .build --exclude local.properties ~/Documents/projects/boilerplates/<boilerplate>/ ~/Documents/projects/<repo>/`
- Remplace le nom du boilerplate par celui du repo : `grep -rIl "<boilerplate>" --exclude-dir=node_modules .` puis édite chaque occurrence (package.json, package-lock.json via `npm install`, README, workflows, noms d'image Docker, Sentry, infra).
- Android : remplace `com.example.app` (namespace, `applicationId`, dossiers de packages). iOS : bundle identifier dans `project.yml`.
- Thème : si ce n'est pas `clean`, remplace les fichiers générés par ceux du thème choisi, pris dans `~/Documents/projects/shared-libs/packages/design-tokens/generated/` : `css/<thème>.css` → `src/theme/` (et l'import de `src/styles.css`) en web, `android/<thème>/ThemeTokens.kt` (adapter la ligne `package`) en Android, `ios/<thème>/ThemeTokens.swift` en iOS.
- Remplace le titre et l'introduction du README par le nom et la description du projet. Garde les sections techniques.
- Si l'humain a choisi de supprimer `notes` : retire la feature, ses routes, tests, mocks et migrations, et garde un écran ou endpoint minimal pour que l'app démarre.
- Copie `.env.example` en `.env` pour le développement local quand il existe.
- Écris `.boilerplate.json` à la racine (commité) pour que `/upstream` puisse comparer l'app à son origine (GLB-010) :

  ```json
  {
    "boilerplate": "<boilerplate>",
    "commit": "<git -C ~/Documents/projects/boilerplates rev-parse HEAD>",
    "createdAt": "<AAAA-MM-JJ>",
    "theme": "<clean|warm|vivid>",
    "renames": { "<boilerplate>": "<repo>", "com.example.app": "<identifiant d'app>" }
  }
  ```

## 4. Vérifier

- Installe (`npm install`, ou rien pour mobile et infra) puis lance la vérification indiquée dans l'`AGENTS.md` du projet. Elle **doit** passer avant la création du repo. Corrige ce que le renommage a cassé.

## 5. Créer le repo GitHub

- `git init -b main`, `git add -A`, `git commit -m "chore: bootstrap from <boilerplate> boilerplate"`.
- `gh repo create soodidi/<repo> --private --description "<description>" --source . --push` (ou `--public`).
- Réglages : `gh repo edit soodidi/<repo> --enable-squash-merge --enable-merge-commit=false --enable-rebase-merge=false --delete-branch-on-merge --enable-auto-merge`.
- Labels utilisés par les templates : `gh label create feature --color 1D76DB`, `gh label create security --color B60205` (ignorer s'ils existent ; `bug` existe par défaut).

## 6. Protéger main

- Attends la fin du premier run CI : `gh run watch`. Récupère les noms des jobs : `gh run view --json jobs -q '.jobs[].name'`.
- Crée la protection de `main` avec `gh api -X PUT repos/soodidi/<repo>/branches/main/protection` : PR obligatoire (0 approbation requise, car Mo travaille seul), statuts requis = les jobs CI, branche à jour requise, force-push et suppression interdits, **règles appliquées aussi aux admins** (`enforce_admins: true`) : l'IA fusionne avec `--auto` (GLB-011), et `--admin` ne doit pas pouvoir contourner la CI.
- Si l'API renvoie 403 : sur un compte GitHub gratuit, la protection de branche n'est pas disponible pour un repo privé. Ne contourne pas : explique les options (passer le repo en public, GitHub Pro, ou s'en passer pour l'instant) et laisse l'humain choisir.

## 7. Checklist « Mise en route »

Lis `~/Documents/projects/engineering-guidelines/docs/checklist-nouveau-projet.md` et adapte-la au projet :

- Garde la section **Tous les projets** et seulement les sections des briques choisies : Sentry (web, api), Scaleway (infra, ou web/api qui déploient), Domaine (web ou api déployés), Mobile (android, ios), Légal (dès qu'une app est publique).
- Remplace `<nom>`, `<repo>` et les noms des repos par les vrais. Vérifie que les secrets et variables listés correspondent bien à ceux des workflows copiés (`grep -rhoE '(secrets|vars)\.[A-Za-z0-9_]+' .github/workflows | sort -u`, hors `GITHUB_TOKEN`) et ajoute ceux qui manqueraient.
- **Coche** ce que tu as fait toi-même (repo, réglages, labels, protection de `main` si elle a réussi). Laisse décoché tout le reste.

Puis, pour chaque repo créé, ouvre une issue avec la partie qui le concerne :

```bash
gh issue create -R soodidi/<repo> --title "Mise en route" --body-file <fichier>
```

Le corps commence par une phrase qui renvoie à la checklist de référence. Les sections communes à plusieurs repos (comptes Sentry, Scaleway, domaine, stores) vont dans l'issue du repo infra s'il existe, sinon dans celle du premier repo ; les autres issues y renvoient.

## 8. Terminer

Présente un récapitulatif court :

- Liens des repos créés, résultat de la vérification et liens des issues « Mise en route ».
- La checklist adaptée, avec ce qui est déjà coché. Pour les secrets, donne la commande `gh secret set` mais **ne demande jamais la valeur d'un secret** dans la conversation.
- Ce qui est à lancer tôt parce que c'est long : comptes Apple Developer et Google Play (validation en plusieurs jours), achat du domaine.
- Prochaine étape : créer une première issue « Fonctionnalité » puis `/feature <numéro>`.
