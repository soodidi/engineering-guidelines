---
name: new-project
description: Crée un nouveau projet à partir du repo boilerplates (GLB-010) : copie, renommage, repo GitHub, protection de main, labels, secrets à configurer. À utiliser pour démarrer une nouvelle app, ex. /new-project.
argument-hint: "[nom-du-projet]"
disable-model-invocation: true
---

Création d'un projet : $ARGUMENTS

`<racine>` est le dossier racine (défini dans le `CLAUDE.md` commun). Les boilerplates sont dans `<racine>/boilerplates`, les nouveaux projets vont dans `<racine>/<nom>`. Suis les étapes dans l'ordre et ne saute pas les confirmations.

## 1. Cadrer

L'humain ne remplit que le strict minimum : tout le reste a une valeur par défaut qu'il peut changer. Demande en une seule fois :

- **Nom** du projet en kebab-case.
- **Briques** : web (`web-react-vite`), api (`api-nestjs`), infra (`infra-scaleway`), android (`android-compose`), ios (`ios-swiftui`). Une brique = un repo. Avec plusieurs briques, les repos s'appellent `<nom>-web`, `<nom>-api`, `<nom>-infra`, `<nom>-android`, `<nom>-ios` ; avec une seule, `<nom>`.
- **Identifiant d'app**, seulement si Android ou iOS (ex. `fr.soodidi.monapp`).

Propose ensuite ces valeurs par défaut, dans le même message, et garde celles que l'humain ne change pas :

| Réglage | Par défaut |
|---|---|
| Description (une phrase) | déduite du nom |
| Nom affiché de l'app (e-mails, titre) | le nom en clair (`mon-app` → « Mon app ») |
| Thème (GLB-012) | épuré (`clean`) ; chaleureux (`warm`) ou coloré (`vivid`) sur demande |
| Visibilité GitHub | privé |
| Feature d'exemple `notes` | gardée comme modèle jusqu'à la première vraie feature |
| Domaine | à choisir plus tard ; **obligatoire avant le staging** s'il y a de l'auth web (BE-006) |

Récapitule ensuite le plan (repos créés, renommages, valeurs retenues) et attends un « ok ».

## 2. Prérequis

- `gh auth status` doit être connecté. `node -v` doit respecter le `.nvmrc` du boilerplate.
- `git -C <racine>/boilerplates pull --ff-only` pour partir de la dernière version.
- Le dossier cible ne doit pas exister.

## 3. Copier et renommer (pour chaque brique)

- `rsync -a --exclude node_modules --exclude dist --exclude build --exclude .gradle --exclude .terraform --exclude .build --exclude local.properties <racine>/boilerplates/<boilerplate>/ <racine>/<repo>/`
- Remplace le nom du boilerplate par celui du repo : `grep -rIl "<boilerplate>" --exclude-dir=node_modules .` puis édite chaque occurrence (package.json, package-lock.json via `npm install`, README, workflows, noms d'image Docker, Sentry, infra).
- Android : remplace `com.example.app` (namespace, `applicationId`, dossiers de packages). iOS : dans `project.yml`, remplace toutes les occurrences de `com.example` (`bundleIdPrefix`, `com.example.app`, `com.example.app.tests`, `com.example.app.uitests`).
- URL de production : si le domaine est connu, remplace `api.example.com` et `app.example.com` (Android : `app/build.gradle.kts` ; iOS : `project.yml`) ; sinon laisse-les et garde la case correspondante décochée dans la checklist.
- Thème : si ce n'est pas `clean`, remplace les fichiers générés par ceux du thème choisi, pris dans `<racine>/shared-libs/packages/design-tokens/generated/` : `css/<thème>.css` → `src/theme/` (et l'import de `src/styles.css`) en web, `android/<thème>/ThemeTokens.kt` (adapter la ligne `package`) en Android, `ios/<thème>/ThemeTokens.swift` en iOS.
- Remplace le titre et l'introduction du README par le nom et la description du projet. Garde les sections techniques.
- Si l'humain a choisi de supprimer `notes` : retire la feature, ses routes, tests, mocks et migrations, et garde un écran ou endpoint minimal pour que l'app démarre.
- Remplace « Mon app » par le nom affiché : `APP_NAME` dans `.env.example` (api), `app.name` dans `src/i18n/fr.ts` et `en.ts` (web), `app_name` dans les `terraform.tfvars.example` (infra).
- Ne copie pas `.env` à la main : `npm run setup` (api) le crée à l'étape suivante, avec des secrets de dev générés.
- Écris `.boilerplate.json` à la racine (commité) pour que `/upstream` puisse comparer l'app à son origine (GLB-010) :

  ```json
  {
    "boilerplate": "<boilerplate>",
    "commit": "<git -C <racine>/boilerplates rev-parse HEAD>",
    "createdAt": "<AAAA-MM-JJ>",
    "theme": "<clean|warm|vivid>",
    "renames": { "<boilerplate>": "<repo>", "com.example.app": "<identifiant d'app>" }
  }
  ```

## 4. Vérifier

- Installe (`npm install`, ou rien pour mobile et infra) puis lance la vérification indiquée dans l'`AGENTS.md` du projet. Elle **doit** passer avant la création du repo. Corrige ce que le renommage a cassé.
- API : lance `npm run setup` (crée `.env`, démarre PostgreSQL et Mailpit, applique les migrations), puis `npm run stack` et `npm run stack:smoke` : l'API tourne dans l'image de production et une inscription envoie bien un e-mail dans Mailpit. Arrête avec `npm run stack:down`. Si Docker ne répond pas, demande à l'humain de démarrer Docker Desktop.
- Web avec API : vérifie que `npm run dev:api` affiche l'app contre l'API locale.
- Plugins Claude : pour chaque plugin listé dans `enabledPlugins` du `.claude/settings.json` du projet, lance `claude plugin install <plugin> --scope project` depuis le dossier du projet (une installation ne vaut que pour le projet où elle est faite). `claude plugin list` ne doit afficher aucun `failed to load`, et le `settings.json` ne doit pas changer de contenu.

## 5. Créer le repo GitHub

- `git init -b main`, `git add -A`, `git commit -m "chore: bootstrap from <boilerplate> boilerplate"`.
- `gh repo create soodidi/<repo> --private --description "<description>" --source . --push` (ou `--public`).
- Réglages : `gh repo edit soodidi/<repo> --enable-squash-merge --enable-merge-commit=false --enable-rebase-merge=false --delete-branch-on-merge --enable-auto-merge`.
- Labels utilisés par les templates : `gh label create feature --color 1D76DB`, `gh label create security --color B60205` (ignorer s'ils existent ; `bug` existe par défaut).

## 6. Protéger main

- Attends la fin du premier run CI : `gh run watch`. Récupère les noms des jobs : `gh run view --json jobs -q '.jobs[].name'`.
- Crée la protection de `main` avec `gh api -X PUT repos/soodidi/<repo>/branches/main/protection` : PR obligatoire (0 approbation requise, car Mo travaille seul), statuts requis = les jobs CI, branche à jour requise, force-push et suppression interdits, **règles appliquées aussi aux admins** (`enforce_admins: true`) : l'IA fusionne avec `--auto` (GLB-011), et `--admin` ne doit pas pouvoir contourner la CI.
- Si l'API renvoie 403 : sur un compte GitHub gratuit, la protection de branche n'est pas disponible pour un repo privé. Ne contourne pas : explique les options (passer le repo en public, GitHub Pro, ou s'en passer pour l'instant) et laisse l'humain choisir.

## 7. Passphrase du state (si la brique infra est choisie)

Explique-la simplement à l'humain, **avant** tout `tofu init` et sans la lui demander dans la conversation :

- **À quoi elle sert** : le state OpenTofu contient des secrets générés (mot de passe de la base, clés API Scaleway, secret d'auth). Il est chiffré avec cette passphrase (OPS-006).
- **Ce qu'il doit faire** : en choisir une longue (16 caractères au moins, par exemple générée par son gestionnaire de mots de passe), la ranger dans le gestionnaire de mots de passe, puis dans le secret GitHub `TF_STATE_PASSPHRASE` des quatre environnements du repo infra (`gh secret set TF_STATE_PASSPHRASE -R soodidi/<repo> --env <env>`). En local, `export TF_VAR_state_passphrase=…` avant chaque commande `tofu`, `tofu init` compris.
- **Le risque** : la perdre rend le state illisible. Il faudrait alors réimporter ou recréer toute l'infrastructure. Elle ne se change pas sans procédure.
- Demande-lui de confirmer qu'il l'a rangée avant de passer à la suite.

## 8. Checklist « Mise en route »

Lis `<racine>/engineering-guidelines/docs/checklist-nouveau-projet.md` et adapte-la au projet :

- Garde la section **Tous les projets** et seulement les sections des briques choisies : Sentry (web, api), Scaleway (infra, ou web/api qui déploient), Domaine (web ou api déployés), Mobile (android, ios), Légal (dès qu'une app est publique, donc toujours avec android ou ios : une app sur un store l'est).
- Remplace `<nom>`, `<repo>` et les noms des repos par les vrais. Vérifie que les secrets et variables listés correspondent bien à ceux des workflows copiés (`grep -rhoE '(secrets|vars)\.[A-Za-z0-9_]+' .github/workflows | sort -u`, hors `GITHUB_TOKEN`) et ajoute ceux qui manqueraient.
- **Coche** ce que tu as fait toi-même (repo, réglages, labels, protection de `main` si elle a réussi). Laisse décoché tout le reste.

Puis, pour chaque repo créé, ouvre une issue avec la partie qui le concerne :

```bash
gh issue create -R soodidi/<repo> --title "Mise en route" --body-file <fichier>
```

Le corps commence par une phrase qui renvoie à la checklist de référence. Les sections communes à plusieurs repos (comptes Sentry, Scaleway, domaine, stores) vont dans l'issue du repo infra s'il existe, sinon dans celle du premier repo ; les autres issues y renvoient.

## 9. Terminer

Présente un récapitulatif court :

- Liens des repos créés, résultat de la vérification et liens des issues « Mise en route ».
- **Ce qui reste à remplir**, en une liste courte et exacte (valeurs à saisir, comptes à créer), et rien d'autre : tout ce qui a une valeur par défaut ou est généré n'y figure pas.
- La checklist adaptée, avec ce qui est déjà coché. Pour les secrets, donne la commande `gh secret set` mais **ne demande jamais la valeur d'un secret** dans la conversation.
- Ce qui est à lancer tôt parce que c'est long : comptes Apple Developer et Google Play (validation en plusieurs jours), achat du domaine.
- Avant la première session dans chaque repo : lancer `claude` en interactif depuis son dossier et accepter la confiance du dossier, sans quoi les permissions et les plugins du projet sont ignorés.
- Prochaine étape : créer une première issue « Fonctionnalité » puis `/feature <numéro>`.
