# IOS-003 : Gestion des dépendances avec Swift Package Manager

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : ios
- **Auteurs** : Mo, Claude

## Contexte

Plusieurs gestionnaires de dépendances ont coexisté sur iOS. CocoaPods est entré en mode maintenance et son dépôt central de specs est en cours de passage en lecture seule ; SPM est intégré à Xcode et devenu le standard.

## Décision

- **Swift Package Manager uniquement**. Pas de CocoaPods ni de Carthage dans un nouveau projet.
- `Package.resolved` commité (GLB-008).
- Versions des dépendances contraintes par **version exacte ou `upToNextMinor`** pour les librairies structurantes.
- Les SDK tiers lourds (analytics, publicité…) sont isolés derrière un protocole dans un module dédié, pour pouvoir les remplacer ou les désactiver.
- Préférer les frameworks Apple quand ils couvrent le besoin (URLSession, SwiftData, Observation, Swift Testing) avant d'ajouter une dépendance.
- Chaque SDK tiers ajouté DOIT déclarer son **Privacy Manifest** ; l'app maintient le sien à jour (exigence App Store).

## Alternatives envisagées

- **CocoaPods** : en fin de vie.
- **Tuist** pour générer le projet : très utile sur de gros projets modulaires (moins de conflits sur `.xcodeproj`). À envisager par ADR quand la modularisation grandit.

## Conséquences

- ✅ Outil unique, intégré, maintenu par Apple.
- ⚠️ Quelques SDK anciens ne sont pas distribués en SPM : les éviter ou les encapsuler.

## Mise en application

- Revue de code sur `Package.swift` et le projet Xcode.
- Renovate configuré pour SPM (GLB-008).
