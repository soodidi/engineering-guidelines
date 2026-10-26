# IOS-005 : Qualité de code, tests et livraison iOS

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : ios
- **Auteurs** : Mo, Claude

## Contexte

Déclinaison iOS de GLB-004 et OPS-002. La revue App Store ajoute un délai : un bug publié reste plus longtemps chez les utilisateurs que sur le web.

## Décision

**Qualité statique**

- **SwiftLint** (règles d'analyse) et **SwiftFormat** (formatage), exécutés en local et en CI.
- Conventions Swift (API Design Guidelines d'Apple) : types en `UpperCamelCase`, le reste en `lowerCamelCase`, noms qui se lisent comme des phrases au point d'appel.
- Avertissements du compilateur traités comme des erreurs en CI.

**Tests**

| Niveau | Outil | Cible |
|--------|-------|-------|
| Unitaire | **Swift Testing** (`@Test`, `#expect`) | ViewModels, UseCases, repositories avec fakes |
| Captures d'écran | swift-snapshot-testing | design system, écrans principaux |
| UI | **XCUITest** | parcours critiques uniquement |

- Fakes (implémentations de test des protocoles) plutôt que mocks générés.
- Les ViewModels sont testés par leur état exposé après chaque action.
- Le temps et l'aléatoire sont injectés (`Clock`, générateurs) pour des tests déterministes.

**Livraison**

- Build, signature et publication automatisés avec **Fastlane** sur runners **macOS GitHub Actions** ; certificats et profils gérés par `fastlane match` (stockage chiffré) ou par la signature gérée via clé d'API App Store Connect.
- Parcours : TestFlight interne → TestFlight externe → App Store en **publication progressive** (phased release).
- `CFBundleVersion` généré par la CI (GLB-006).
- Suivi des crashs (Sentry ou Crashlytics) et des métriques Xcode Organizer à chaque release.
- Feature flags côté backend pour désactiver une fonctionnalité sans nouvelle soumission.

## Alternatives envisagées

- **XCTest pour les tests unitaires** : toujours supporté, mais Swift Testing est l'outil moderne recommandé par Apple ; XCTest reste utilisé pour XCUITest.
- **Xcode Cloud** : intégré à Apple, simple pour la signature ; GitHub Actions garde une CI unique pour tous les domaines (OPS-002). À réévaluer si les minutes macOS coûtent trop cher.

## Conséquences

- ✅ Qualité vérifiée automatiquement, publication maîtrisée.
- ⚠️ Les runners macOS sont plus chers et plus lents : limiter les jobs iOS aux PR qui touchent le code iOS.

## Mise en application

- CI : SwiftLint, SwiftFormat `--lint`, build, tests unitaires et captures sur chaque PR iOS.
- XCUITest avant chaque soumission.
