# IOS-001 : Swift 6 et SwiftUI

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : ios
- **Auteurs** : Mo, Claude

## Contexte

Les apps mobiles sont développées en natif. Côté iOS, Apple fait évoluer SwiftUI et la concurrence structurée de Swift chaque année ; le mode de langage Swift 6 détecte les data races à la compilation.

## Décision

- Langage : **Swift** uniquement, en **mode de langage Swift 6** (vérification stricte de la concurrence). Pas de nouveau code Objective-C.
- UI : **SwiftUI**. UIKit uniquement via `UIViewRepresentable` / `UIViewControllerRepresentable` pour un besoin non couvert.
- Asynchrone : **async/await**, `Task`, acteurs. Pas de Combine ni de completion handlers dans le nouveau code (sauf API système qui l'impose).
- État observable : macro **`@Observable`** (framework Observation). Pas de `ObservableObject` / `@Published` dans le nouveau code.
- Cible de déploiement : **version majeure d'iOS courante − 1** (iOS 26 à l'automne 2026), réévaluée à chaque sortie d'iOS selon l'audience.
- Version de Xcode épinglée (`.xcode-version`), GLB-008.

**SwiftUI**
- Vues petites et composables ; une vue au-delà de ~150 lignes DEVRAIT être découpée.
- Les vues ne contiennent pas de logique métier ni d'appel réseau.
- Chaque vue réutilisable a une `#Preview` (cas nominal + cas limite).
- Couleurs, typographies et espacements via le design system de l'app ; support du mode sombre et de **Dynamic Type**.
- Accessibilité : libellés VoiceOver sur les éléments non textuels, cibles tactiles ≥ 44 pt.

## Alternatives envisagées

- **UIKit** : plus de contrôle fin, mais plus verbeux ; réservé aux cas non couverts par SwiftUI.
- **Mode Swift 5 sans concurrence stricte** : plus permissif, mais laisse passer des data races.

## Conséquences

- ✅ Code moderne, sûr vis-à-vis de la concurrence, aligné avec l'évolution d'Apple.
- ⚠️ La concurrence stricte demande un apprentissage (`Sendable`, `@MainActor`, isolation).

## Mise en application

- Réglages du projet / des packages : Swift 6 language mode.
- SwiftLint (IOS-005).
