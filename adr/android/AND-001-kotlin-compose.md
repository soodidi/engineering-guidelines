# AND-001 : Kotlin et Jetpack Compose

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : android
- **Auteurs** : Mo, Claude

## Contexte

Les apps mobiles sont développées en natif (choix fait face à React Native) pour la performance, l'accès complet aux API de la plateforme et la qualité d'intégration. Côté Android, Google recommande Kotlin et Compose pour tout nouveau développement.

## Décision

- Langage : **Kotlin** uniquement. Pas de nouveau code Java.
- UI : **Jetpack Compose** uniquement, avec **Material 3** adapté au design du produit. Pas de nouvelles vues XML.
- Asynchrone : **coroutines + Flow**. Pas de RxJava, pas de callbacks imbriqués, pas de `GlobalScope`.
- Build : **Gradle Kotlin DSL** (`.kts`), **version catalog** (`gradle/libs.versions.toml`) pour toutes les dépendances.
- `minSdk` : **26** par défaut (à revoir selon l'audience du produit). `targetSdk` : niveau exigé par Google Play, mis à jour chaque année.
- `compileSdk` : dernière version stable.
- JDK épinglé (GLB-008).

**Compose**
- Composables sans état (*stateless*) par défaut : ils reçoivent l'état et émettent des événements (*state hoisting*). Seul l'écran de plus haut niveau est relié au ViewModel.
- Chaque composable public a un `@Preview` (cas nominal + au moins un cas limite : vide, erreur, texte long).
- Paramètre `modifier: Modifier = Modifier` en premier paramètre optionnel de tout composable d'UI réutilisable.
- Pas de logique métier ni d'appel réseau dans un composable.
- Thème, couleurs, typographie et espacements centralisés dans le thème de l'app ; pas de valeurs codées en dur.
- Mode sombre et tailles de police dynamiques supportés.

## Alternatives envisagées

- **React Native / Flutter** : rejetés au profit du natif (décision produit).
- **Vues XML** : maintenance seulement pour du code existant.
- **Kotlin Multiplatform pour partager la logique avec iOS** : intéressant à terme pour la couche données ; à réévaluer par un ADR dédié une fois les deux apps stabilisées.

## Conséquences

- ✅ Stack moderne et recommandée par Google, très demandée.
- ⚠️ Compose demande de bien comprendre la recomposition pour éviter les problèmes de performance.

## Mise en application

- Projet généré depuis un template avec ces réglages.
- Lint Compose (`compose-lint` / règles detekt Compose), AND-005.
