# Module : client d'API généré depuis OpenAPI

- **Statut** : Proposé
- **ADR impactés** : BE-004, FE-002, FE-006, AND-004, IOS-004, OPS-002, GLB-008

## État actuel : écart avec les ADR

BE-004 recommande de générer les clients depuis la spec OpenAPI de l'API, et AND-004 et IOS-004 l'écrivent comme la règle de leur domaine. **Aucun boilerplate ne le fait** : le web appelle l'API avec `request()` et des schémas Zod, Android avec Retrofit et des DTO écrits à la main, iOS avec `APIClient`. L'API exporte bien sa spec (`npm run openapi`, artefact `openapi.json` en CI), mais le contrôle des changements cassants (`oasdiff`, BE-004) n'est pas branché.

Décision de l'utilisateur (2026-10-31) : on **ne tranche pas maintenant**. L'app jetable (tâche D du suivi) dira si les appels écrits à la main posent problème ; un ADR mettra ensuite AND-004 et IOS-004 d'accord avec la pratique (génération obligatoire, ou recommandée à partir d'une certaine taille d'API).

## Quand l'utiliser

- l'API dépasse une quinzaine de routes, ou change souvent ;
- un client a déjà eu un bug de contrat (champ renommé, type faux) que la compilation aurait vu ;
- plusieurs personnes travaillent sur l'API et les clients.

S'en passer tant que l'API est petite et stable : le code généré a un coût (outil à maintenir, code moins lisible, mises à jour du générateur).

## Recommandation

**Une spec versionnée, recopiée dans chaque client, et un générateur par plateforme.**

1. **API** : `openapi.json` produit en CI (déjà fait) et **contrôlé** : la CI échoue si la spec commitée diffère de celle générée, et `oasdiff breaking` compare avec `main` pour bloquer un changement cassant sur `/v1` (BE-004).
2. **Clients** : chaque repo client garde une **copie de la spec** (`api/openapi.json`), mise à jour par un script (`npm run api:pull` ou équivalent) qui la télécharge depuis une version publiée de l'API. La PR de mise à jour montre le diff du contrat ; le build reste reproductible et hors ligne.
3. **Générateurs** :
   - **Web** : `openapi-typescript` (types) + `openapi-fetch` (client typé de quelques Ko). FE-002 exige de valider les données externes : garder Zod à la frontière, au moins pour les réponses dont dépend la sécurité ou la navigation ; les types générés vérifient le contrat à la compilation, pas à l'exécution.
   - **Android** : plugin Gradle `org.openapi.generator`, générateur `kotlin`, bibliothèque `jvm-retrofit2`, sérialisation `kotlinx_serialization` ; code généré dans `build/`, jamais commité, branché dans `:core:network` (AND-004).
   - **iOS** : `swift-openapi-generator` en plugin de build SPM, avec `swift-openapi-urlsession` ; un middleware ajoute le `Bearer` et traite le 401 comme `APIClient` aujourd'hui (IOS-004).

## Alternatives

- **Appels écrits à la main** (état actuel) : lisibles, sans outil, suffisants pour une petite API ; rien n'avertit d'une divergence avant l'exécution.
- **Orval** (web) : génère aussi les hooks TanStack Query et des schémas Zod ; plus de code généré et plus de conventions imposées.
- **Spec publiée dans un paquet npm, Maven ou SPM** : plus propre pour beaucoup de clients, trop lourd pour un développeur seul.

## Intégration par brique

**API**

- Job CI : `npm run openapi`, puis `git diff --exit-code openapi.json`, puis `oasdiff breaking` contre la spec de `main`.
- Publier la spec avec chaque version (asset de release GitHub, GLB-006) pour que les clients la téléchargent à une version précise.

**Web, Android, iOS**

- Script de récupération de la spec, commande de génération lancée par `verify` (ou par le build).
- Remplacer les DTO et appels écrits à la main **feature par feature**, en commençant par `notes`.
- Les routes de Better Auth (`/v1/auth/*`) ne sont pas dans la spec NestJS : leurs appels restent écrits à la main (SDK web, `postRaw` iOS, appels d'auth Android).

## Comptes et secrets (checklist du projet)

- Aucun compte ; un jeton en lecture seule sur le repo de l'API seulement s'il est privé et que la CI d'un client télécharge la spec.

## Données personnelles (GLB-013)

- Sans effet.

## Pièges

- **Valeurs d'énumération nouvelles** : une app ancienne ne doit pas planter sur une valeur ajoutée par l'API. Kotlin : valeur par défaut ou `coerceInputValues` ; Swift : cas `undocumented` du générateur ; web : ne pas rendre l'énumération exhaustive côté affichage.
- **Champ optionnel ou `null`** : OpenAPI 3.1 et les générateurs ne les traitent pas tous pareil ; vérifier le code généré sur un exemple.
- **Problem Details** : décrire les réponses d'erreur dans la spec, sinon les clients générés les traitent comme des réponses inconnues.
- **Code généré modifié à la main** : interdit ; corriger la spec ou la configuration du générateur.
- **Mise à jour du générateur** : traiter comme une dépendance (GLB-008), avec relecture du diff généré.

## Tests à écrire

- API : la CI échoue si `openapi.json` n'est pas à jour, et sur un changement cassant détecté par `oasdiff`.
- Clients : la compilation contre la spec fait office de test de contrat ; les doublures de test (MSW sur le web, faux serveur sur mobile) utilisent les types générés.
- Un test par client qui décode une réponse contenant une valeur d'énumération inconnue sans planter.
