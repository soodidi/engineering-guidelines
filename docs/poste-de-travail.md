# Poste de travail : installer une nouvelle machine

Tout ce qu'il faut pour travailler sur les repos `engineering-guidelines`, `boilerplates` et `shared-libs`, avec Claude Code. Cible : macOS, Apple Silicon (M1 ou plus récent).

Ce document évolue avec les besoins : un outil ajouté à un boilerplate ou à la CI s'ajoute ici dans la même PR. Les versions indiquées sont celles qui fonctionnaient au 2026-10-28. Prendre au moins celles-ci, et les plus récentes si la CI les accepte.

## 1. Socle (tous les projets)

| Outil | Pourquoi | Installation | Vérification |
|-------|----------|--------------|--------------|
| Xcode Command Line Tools | git, compilateurs | `xcode-select --install` | `git --version` |
| Homebrew | gestionnaire de paquets | <https://brew.sh> | `brew --version` |
| GitHub CLI | PR, fusion automatique, `/new-project` | `brew install gh`, puis `gh auth login` (HTTPS, compte `soodidi`) | `gh auth status` |
| Python 3 | utilisé par les hooks Claude (`.claude/hooks/after-edit.sh`) | `brew install python` | `python3 --version` (3.12 ou plus) |
| gitleaks | hook de pré-commit (secrets) | `brew install gitleaks` | `gitleaks version` |

Cloner les trois repos côte à côte dans un **dossier racine**, au choix (par exemple `~/Documents/perso/projects`). Les docs, les skills et les agents le désignent par `<racine>` : aucun chemin absolu n'est codé en dur.

```bash
racine=~/Documents/perso/projects  # au choix
mkdir -p "$racine" && cd "$racine"
gh repo clone soodidi/engineering-guidelines
gh repo clone soodidi/boilerplates
gh repo clone soodidi/shared-libs
```

## 2. Node, web et API

| Outil | Pourquoi | Installation | Vérification |
|-------|----------|--------------|--------------|
| nvm + Node 26 | version imposée par les `.nvmrc` | `brew install nvm` (suivre les instructions pour `~/.zshrc`), puis `nvm install 26 && nvm alias default 26` | `node -v` (v26.x), `npm -v` |
| Docker Desktop (Apple Silicon) | PostgreSQL et Mailpit locaux, `npm run stack`, Testcontainers | <https://www.docker.com/products/docker-desktop/> | `docker --version`, `docker compose version` |

- **npm uniquement** (jamais pnpm ni yarn). Les hooks Git (lefthook) s'installent avec `npm install`.
- **Docker dans le PATH** : Testcontainers a besoin de `docker-credential-desktop`. S'il est introuvable, ajouter `/Applications/Docker.app/Contents/Resources/bin` au PATH dans `~/.zshrc`.
- Premier lancement de l'API : `cd boilerplates/api-nestjs && npm install && npm run setup && npm run stack`. `setup` crée le `.env` et ses secrets de dev, il n'y a rien à copier depuis l'ancienne machine.

## 3. Infra (OpenTofu, Scaleway)

| Outil | Pourquoi | Installation | Vérification |
|-------|----------|--------------|--------------|
| OpenTofu | `fmt`, `validate`, `plan` en local | `brew install opentofu` | `tofu version` (1.13 ou plus) |
| tflint (facultatif) | même lint que la CI | `brew install tflint` | `tflint --version` |
| CLI Scaleway (facultatif) | essais manuels | `brew install scw` | `scw version` |

Les secrets (clés Scaleway, `TF_STATE_PASSPHRASE`) viennent du **gestionnaire de mots de passe**, jamais d'un fichier copié. Un `tofu apply` se lance toujours à la main par l'utilisateur.

## 4. Android

| Outil | Pourquoi | Installation | Vérification |
|-------|----------|--------------|--------------|
| Android Studio (Apple Silicon) | SDK, émulateur, AGP Upgrade Assistant | <https://developer.android.com/studio> | ouvrir `boilerplates/android-compose` |
| JDK 17 ou plus | Gradle et AGP 8.13 | celui d'Android Studio (JBR 21), ou `brew install --cask temurin@17` | `java -version` |
| SDK Android 36 | compilation | Android Studio → SDK Manager → Android 16 (API 36) | `ls ~/Library/Android/sdk/platforms` |

- Dans `~/.zshrc` : `export ANDROID_HOME=~/Library/Android/sdk`, et ajouter `$ANDROID_HOME/platform-tools` au PATH.
- **Émulateur sur Apple Silicon** : image **`arm64-v8a`** (et non `x86_64`). En ligne de commande :

  ```bash
  sdkmanager --install "system-images;android-36;google_apis;arm64-v8a" emulator
  avdmanager create avd -n auth_test -k "system-images;android-36;google_apis;arm64-v8a" -d pixel_6
  ```

- Vérification : `./gradlew ktlintCheck lintDebug testDebugUnitTest assembleDebug`, puis `./gradlew connectedDebugAndroidTest` avec l'émulateur lancé. Ne pas lancer deux Gradle en parallèle sur le même projet : KSP casse.
- L'émulateur joint l'API locale sur `http://10.0.2.2:3000`.

## 5. iOS (Mac obligatoire)

| Outil | Pourquoi | Installation | Vérification |
|-------|----------|--------------|--------------|
| Xcode 26 | SDK iOS, simulateur, `sourcekit-lsp` | App Store, puis `sudo xcodebuild -license accept` et l'installation du simulateur iOS | `xcodebuild -version` |
| XcodeGen, SwiftLint, SwiftFormat | projet généré, lint et format | `brew install xcodegen swiftlint swiftformat` | `xcodegen --version`, `swiftlint version`, `swiftformat --version` |

- Vérification : `swiftformat --lint .`, `swiftlint --strict` et `swift test --package-path Packages` dans `boilerplates/ios-swiftui`.
- Le simulateur joint l'API locale sur `http://localhost:3000`.

## 6. Claude Code

1. Installer Claude Code (<https://docs.claude.com/claude-code>) et l'extension VS Code si besoin. Se connecter avec le **même compte claude.ai**.
2. Installer la configuration commune, depuis `<racine>` : `engineering-guidelines/ai/install.sh`. Le script relie `<racine>/CLAUDE.md` et les skills `/new-project`, `/upstream` et `/adr` dans `<racine>/.claude/skills`. Il n'écrit rien dans `~/.claude` : sur un poste partagé avec d'autres projets (poste pro, par exemple), cette configuration ne s'applique qu'aux sessions lancées dans `<racine>`.
   - Lancer Claude Code depuis le dossier du projet pour `/feature`, `/fix` et `/review`, et depuis `<racine>` pour `/new-project`, `/upstream <app>` et `/adr` : les skills de `<racine>/.claude/` ne sont pas chargés dans un projet en dessous.
   - **Confiance** : lancer `claude` une fois en interactif dans chaque nouveau repo (boilerplates, app créée) et accepter la confiance du dossier. Sans elle, les permissions et les plugins du `.claude/settings.json` du projet sont ignorés.
   - **Ancien poste** (configuration installée dans `~/.claude`) : supprimer les liens `~/.claude/CLAUDE.md` et `~/.claude/skills/{adr,new-project,upstream}`, puis relancer `install.sh`.
   - **Identité Git** : si le poste a une autre identité globale, la limiter au dossier racine dans `~/.gitconfig`, **après** la section `[user]` (sinon l'identité globale l'emporte) :

     ```ini
     [includeIf "gitdir:<racine>/"]
         path = ~/.gitconfig-perso
     ```

     avec `name` et `email` (`20190991+soodidi@users.noreply.github.com`) dans `~/.gitconfig-perso`. Vérifier avec `git -C <racine>/boilerplates config user.email`.
3. **Plugins** : l'installation (le téléchargement) peut suivre le compte claude.ai ; sinon, les installer avec `/plugin` depuis la marketplace `claude-plugins-official` (`anthropics/claude-plugins-official`). L'**activation**, elle, se fait par projet : chaque boilerplate active ceux qui lui servent dans son `.claude/settings.json` versionné (`enabledPlugins`), et l'app créée en hérite : ne pas les activer au niveau utilisateur sur un poste partagé. Pour les sessions lancées depuis `<racine>`, les activer dans `<racine>/.claude/settings.json`, hors des repos :

   | Plugin | Usage | Prérequis sur la machine |
   |--------|-------|--------------------------|
   | `sentry` | lire et corriger les erreurs Sentry | connexion à Sentry au premier usage |
   | `playwright` | piloter un navigateur (E2E web, vérifications visuelles) | aucun |
   | `context7` | documentation à jour des librairies | connexion à Context7 au premier usage (`/mcp`) |
   | `typescript-lsp` | diagnostics TypeScript | `npm install -g typescript-language-server typescript` (avec Node 26 actif) |
   | `kotlin-lsp` | diagnostics Kotlin | `brew install kotlin-language-server` |
   | `swift-lsp` | diagnostics Swift | `sourcekit-lsp`, fourni par Xcode |

4. **Connecteurs claude.ai** (Gmail, Google Calendar, Google Drive) : ils ne servent pas aux projets. S'ils sont utiles, les autoriser dans les réglages des connecteurs sur claude.ai.
5. **Ce qui ne suit pas la machine** : la mémoire locale de Claude (`~/.claude/projects/*/memory`) et l'historique des sessions. Tout ce qui compte est écrit dans les repos : préférences et état du chantier dans [`docs/suivi/HANDOFF.md`](suivi/HANDOFF.md), règles dans `CLAUDE.global.md` et les ADR.

## 7. Reprendre le travail

Dire à Claude : « Lis `engineering-guidelines/docs/suivi/HANDOFF.md` puis `PLAN-SUITE.md`, et continue. »

[`docs/suivi/`](suivi/) contient des **documents temporaires, à effacer** une fois le chantier terminé. Ils servent à fluidifier le travail entre les postes et entre les instances d'IA. L'état du chantier, les décisions prises, les préférences et les pièges déjà rencontrés y sont écrits, et non dans la mémoire d'une machine ou d'une session. Chaque tâche terminée les met à jour par PR. Ces documents sont temporaires : on les supprime quand le chantier est terminé, et on en ajoute d'autres selon les besoins.
