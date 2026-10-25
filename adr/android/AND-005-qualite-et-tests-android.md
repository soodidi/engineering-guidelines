# AND-005 : Qualité de code, tests et livraison Android

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : android
- **Auteurs** : Mo, Claude

## Contexte

Déclinaison Android de GLB-004 et OPS-002. Une app publiée ne se corrige pas instantanément : les bugs restent chez les utilisateurs jusqu'à la mise à jour.

## Décision

**Qualité statique**
- **ktlint** pour le formatage, **detekt** (avec règles Compose) pour l'analyse, **Android Lint** avec les avertissements traités comme des erreurs pour les catégories sécurité et correction.
- Conventions Kotlin officielles : classes en `PascalCase`, fonctions et variables en `camelCase`, constantes en `SCREAMING_SNAKE_CASE`, fichiers nommés comme leur classe principale.

**Tests**

| Niveau | Outils | Cible |
|--------|--------|-------|
| Unitaire | JUnit, `kotlinx-coroutines-test`, **Turbine** | ViewModels, UseCases, repositories (avec fakes) |
| UI Compose | Compose UI Test | composants et écrans clés |
| Captures d'écran | Roborazzi ou Paparazzi | design system, écrans principaux |
| Intégration | Room in-memory, MockWebServer | data layer |

- On utilise des **fakes** (implémentations de test des interfaces) plutôt que des mocks quand c'est possible.
- Les ViewModels sont testés via l'`UiState` émis, pas via leurs méthodes privées.

**Livraison**
- Build et signature en CI (GitHub Actions) ; clé de signature d'upload stockée dans les secrets d'Environment, **Play App Signing** activé.
- Publication via **Fastlane** (ou Gradle Play Publisher) : piste interne → tests fermés → production en **déploiement progressif**.
- `versionCode` généré par la CI (GLB-006).
- Suivi des crashs et ANR (Firebase Crashlytics ou Sentry) ; le taux de sessions sans crash est surveillé à chaque release.
- Feature flags (Remote Config ou backend) pour désactiver une fonctionnalité sans republier.

## Alternatives envisagées

- **Espresso** : réservé à d'éventuelles vues XML existantes.
- **MockK partout** : utile ponctuellement, mais les fakes rendent les tests plus robustes.

## Conséquences

- ✅ Régressions détectées avant les stores, déploiement maîtrisé.
- ⚠️ Les tests UI instrumentés sont lents : les garder pour les parcours critiques.

## Mise en application

- CI : `ktlintCheck`, `detekt`, `lint`, tests unitaires et captures sur chaque PR.
- Tests instrumentés sur émulateur avant chaque release.
