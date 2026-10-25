# AND-003 : Injection de dépendances et modularisation Gradle

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : android
- **Auteurs** : Mo, Claude

## Contexte

Une app qui grandit dans un seul module Gradle compile de plus en plus lentement et laisse toutes les classes dépendre de toutes les autres. Sans injection de dépendances, le code est difficile à tester.

## Décision

**Injection de dépendances**
- **Hilt** pour l'injection de dépendances.
- Injection par constructeur partout où c'est possible. Pas de service locator ni de singletons statiques maison.
- Les interfaces de repository sont injectées, ce qui permet de fournir des implémentations de test (fakes).

**Modularisation progressive**
- Démarrer avec `:app` + `:core:*` minimal. Découper en modules **feature** dès qu'il y a plusieurs fonctionnalités indépendantes ou que le build ralentit.
- Structure cible :
```
:app                      # point d'entrée, navigation globale, DI racine
:feature:<nom>            # écrans + ViewModels d'une fonctionnalité
:core:data                # repositories
:core:network             # client HTTP, API générée
:core:database           # Room
:core:designsystem        # thème, composants UI partagés
:core:model               # modèles du domaine
:core:testing             # fakes et utilitaires de test
```
- Un module `:feature` NE DÉPEND PAS d'un autre module `:feature`. La navigation entre features passe par `:app`.
- **Convention plugins** Gradle (`build-logic/`) pour factoriser la configuration commune des modules.
- Visibilité `internal` par défaut dans les modules.

## Alternatives envisagées

- **Koin** : plus simple à mettre en place, mais résolution à l'exécution (erreurs détectées tard) ; Hilt vérifie le graphe à la compilation.
- **Injection manuelle** : viable pour une petite app, verbeuse ensuite.
- **Modularisation complète dès le jour 1** : coûteuse avant d'avoir des frontières stables.

## Conséquences

- ✅ Builds incrémentaux plus rapides, frontières explicites, tests faciles.
- ⚠️ Hilt ajoute du temps de génération de code ; KSP DOIT être utilisé (pas kapt).

## Mise en application

- Plugin de vérification des dépendances entre modules (ex. `dependency-analysis-gradle-plugin`) en CI.
