# Guide Android

Stack : **Kotlin + Jetpack Compose + Material 3 + Hilt + Retrofit + Room + coroutines/Flow**.
S'applique en plus du [guide global](../global/README.md).

## Règles en bref

**Socle**
- Kotlin uniquement, Compose uniquement, coroutines + Flow, Gradle KTS + version catalog ; `minSdk 26` par défaut ; composables stateless avec `@Preview` et `modifier` en paramètre. → [AND-001](AND-001-kotlin-compose.md)

**Architecture**
- MVVM + flux unidirectionnel : un ViewModel par écran exposant un seul `StateFlow<UiState>` ; repositories = source de vérité ; UseCase seulement si réutilisé ; Navigation Compose typée. → [AND-002](AND-002-architecture-udf-mvvm.md)
- Hilt (KSP) avec injection par constructeur ; modules `:feature:*` et `:core:*` ; une feature ne dépend jamais d'une autre ; `internal` par défaut. → [AND-003](AND-003-injection-et-modularisation.md)

**Données et sécurité**
- Retrofit + OkHttp + kotlinx.serialization, client généré depuis OpenAPI ; Room + DataStore ; tokens chiffrés via le Keystore ; aucun secret dans l'APK ; R8 en release ; HTTPS uniquement. → [AND-004](AND-004-reseau-donnees-et-securite.md)

**Qualité et livraison**
- ktlint + detekt + Android Lint ; JUnit + Turbine + fakes ; tests Compose et captures ; Fastlane, déploiement progressif sur le Play Store, suivi des crashs. → [AND-005](AND-005-qualite-et-tests-android.md)

## Index

| ADR | Titre | Statut |
|-----|-------|--------|
| [AND-001](AND-001-kotlin-compose.md) | Kotlin et Jetpack Compose | Proposé |
| [AND-002](AND-002-architecture-udf-mvvm.md) | Architecture MVVM / UDF | Proposé |
| [AND-003](AND-003-injection-et-modularisation.md) | Hilt et modularisation | Proposé |
| [AND-004](AND-004-reseau-donnees-et-securite.md) | Réseau, données, sécurité | Proposé |
| [AND-005](AND-005-qualite-et-tests-android.md) | Qualité, tests, livraison | Proposé |
