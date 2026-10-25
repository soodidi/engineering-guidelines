# Guide iOS

Stack : **Swift 6 + SwiftUI + Observation + async/await + SPM + swift-openapi-generator + SwiftData**.
S'applique en plus du [guide global](../global/README.md).

## Règles en bref

**Socle**
- Swift 6 (concurrence stricte), SwiftUI, async/await, `@Observable` (pas d'`ObservableObject`) ; cible iOS courant − 1 ; `#Preview`, Dynamic Type, mode sombre, VoiceOver. → [IOS-001](IOS-001-swift-swiftui.md)

**Architecture**
- MVVM : un ViewModel `@Observable @MainActor` par écran, repositories derrière des protocoles injectés par constructeur ; navigation par `NavigationStack` + routes typées ; packages SPM locaux `Features/*` et `Core/*`. → [IOS-002](IOS-002-architecture-mvvm-observable.md)
- SPM uniquement, `Package.resolved` commité, SDK tiers isolés derrière un protocole, Privacy Manifest à jour. → [IOS-003](IOS-003-dependances-spm.md)

**Données et sécurité**
- URLSession + client généré depuis OpenAPI ; SwiftData (GRDB sur ADR) ; tokens dans le Keychain ; ATS strict ; `Logger` avec données privées ; aucun secret dans le binaire. → [IOS-004](IOS-004-reseau-donnees-et-securite.md)

**Qualité et livraison**
- SwiftLint + SwiftFormat ; Swift Testing + fakes ; snapshots ; XCUITest pour les parcours critiques ; Fastlane sur GitHub Actions macOS ; TestFlight puis publication progressive. → [IOS-005](IOS-005-qualite-et-tests-ios.md)

## Index

| ADR | Titre | Statut |
|-----|-------|--------|
| [IOS-001](IOS-001-swift-swiftui.md) | Swift 6 et SwiftUI | Proposé |
| [IOS-002](IOS-002-architecture-mvvm-observable.md) | Architecture MVVM et modules SPM | Proposé |
| [IOS-003](IOS-003-dependances-spm.md) | Dépendances avec SPM | Proposé |
| [IOS-004](IOS-004-reseau-donnees-et-securite.md) | Réseau, données, sécurité | Proposé |
| [IOS-005](IOS-005-qualite-et-tests-ios.md) | Qualité, tests, livraison | Proposé |
