# Module : client d'API généré depuis OpenAPI

- **Statut** : Proposé
- **ADR impactés** : BE-004, FE-002, FE-006, AND-004, IOS-004, OPS-002, GLB-006, GLB-008

## État actuel : écart avec les ADR

- BE-004 recommande de générer les clients depuis la spec OpenAPI de l'API, et AND-004 et IOS-004 l'écrivent comme la règle de leur domaine. **Aucun boilerplate ne le fait** : le web appelle l'API avec `request()` et des schémas Zod, Android avec Retrofit et des DTO écrits à la main, iOS avec `APIClient`.
- L'API exporte sa spec (`npm run openapi`), mais seulement en artefact de CI : elle n'est pas commitée, le contrôle des changements cassants (`oasdiff`, BE-004) n'est pas branché, et l'API n'a pas de version publiée (pas de release, GLB-006).
- La spec produite est en **OpenAPI 3.0.0** (valeur par défaut de `@nestjs/swagger`), alors que BE-004 annonce 3.1.

Choix fait le 2026-10-31 : **ne pas trancher maintenant**. La première app réelle dira si les appels écrits à la main posent problème ; un ADR mettra ensuite AND-004 et IOS-004 d'accord avec la pratique (génération obligatoire, ou recommandée à partir d'une certaine taille d'API).

## Quand l'utiliser

- l'API dépasse une quinzaine de routes, ou change souvent ;
- un client a déjà eu un bug de contrat (champ renommé, type faux) que la compilation aurait vu ;
- plusieurs personnes travaillent sur l'API et les clients.

S'en passer tant que l'API est petite et stable : le code généré a un coût (outil à maintenir, code moins lisible, mises à jour du générateur).

## Recommandation

**Une spec commitée et contrôlée dans l'API, recopiée dans chaque client, et un générateur par plateforme.**

1. **API** : `openapi.json` **commité**, avec un `info.version` stable (la version du contrat, pas `APP_VERSION`, sinon chaque version changerait le fichier). La CI vérifie qu'il est à jour, et `oasdiff breaking --fail-on ERR` le compare à celui de `main` pour bloquer un changement cassant sur `/v1` (BE-004).
2. **Clients** : chaque repo client garde une **copie de la spec** (`api/openapi.json`), mise à jour par un script qui la télécharge depuis le repo de l'API **à un tag ou un SHA précis** (en attendant des releases, GLB-006). La PR de mise à jour montre le diff du contrat ; le build reste reproductible et hors ligne.
3. **Générateurs** :
   - **Web** : FE-002 impose de valider **toutes** les données externes avec Zod. Générer donc, avec les types, les **schémas Zod** des réponses depuis la spec (`@hey-api/openapi-ts` avec son extension Zod, ou Orval en mode `zod` : à choisir au premier usage), et valider chaque réponse dans le client. Des types seuls (`openapi-typescript`) ne suffisent pas : ils ne vérifient rien à l'exécution.
   - **Android** : plugin Gradle `org.openapi.generator`, générateur `kotlin`, bibliothèque `jvm-retrofit2`, sérialisation `kotlinx_serialization`, option `enumUnknownDefaultCase=true` ; code généré dans `build/`, jamais commité, branché dans le module réseau (`core/network`, AND-004).
   - **iOS** : `swift-openapi-generator` en plugin de build SPM (la spec et sa configuration sont dans le dossier de la cible), avec `swift-openapi-urlsession` ; un middleware ajoute le `Bearer` et traite le 401 comme `APIClient` aujourd'hui (IOS-004). Le build en ligne de commande demande `-skipPackagePluginValidation`.

## Alternatives

- **Appels écrits à la main** (état actuel) : lisibles, sans outil, suffisants pour une petite API ; rien n'avertit d'une divergence avant l'exécution.
- **Types seuls sur le web** (`openapi-typescript` + `openapi-fetch`) : très léger, mais contraire à FE-002 sans validation ajoutée, sauf ADR qui l'amende.
- **Spec publiée dans un paquet npm, Maven ou SPM** : plus propre pour beaucoup de clients, trop lourd pour un développeur seul.

## Intégration par brique

**API**

- `operationIdFactory` (`src/common/openapi.ts`) ne garde que le nom de la méthode (`list`, `get`…) : les noms entreront en collision dès qu'un deuxième module en reprend un. Préfixer par le contrôleur (`notesList`) avant de générer quoi que ce soit.
- Passer la spec en OpenAPI 3.1 (option de `@nestjs/swagger`) ou corriger BE-004 : à trancher dans l'ADR.
- Job CI : `npm run openapi`, `git diff --exit-code openapi.json`, puis `oasdiff breaking --fail-on ERR` contre la spec de `main` (récupérée avec `git show origin/main:openapi.json`, le checkout étant superficiel). Version d'`oasdiff` épinglée. Un changement cassant voulu passe par une nouvelle version de l'API (`/v2`, BE-004), pas par une désactivation du contrôle.
- Décrire les réponses d'erreur (Problem Details) dans la spec.

**Web, Android, iOS**

- Script de récupération de la spec, commande de génération lancée par `verify` (ou par le build).
- Remplacer les DTO et appels écrits à la main **feature par feature**, en commençant par `notes`.
- Les routes de Better Auth (`/v1/auth/*`) ne sont pas dans la spec NestJS : leurs appels restent écrits à la main (SDK web, `postRaw` iOS, appels d'auth Android).

## Comptes et secrets (checklist du projet)

- Aucun compte. Si le repo de l'API est privé et que la CI d'un client télécharge la spec : un jeton en lecture seule sur ce seul repo. Inutile si la spec copiée est commitée dans le client et mise à jour à la main par PR.

## Données personnelles (GLB-013)

- Sans effet.

## Pièges

- **Valeurs d'énumération nouvelles** : une app ancienne ne doit pas planter sur une valeur ajoutée par l'API. Kotlin : `enumUnknownDefaultCase=true` ; Swift : `swift-openapi-generator` rejette une valeur inconnue d'une énumération de chaînes, donc déclarer dans la spec une **énumération ouverte** (`anyOf` d'un `enum` et d'un `string`) pour toute valeur qui peut grandir ; web : `.catch()` sur le `z.enum`.
- **Champ optionnel ou `null`** : les générateurs ne les traitent pas tous pareil ; vérifier le code généré sur un exemple.
- **Problem Details absents de la spec** : les clients générés les traitent comme des réponses inconnues.
- **Code généré modifié à la main** : interdit ; corriger la spec ou la configuration du générateur.
- **Mise à jour du générateur** : traiter comme une dépendance (GLB-008), avec relecture du diff du code généré ; exclure les générateurs de la fusion automatique de Renovate.

## Tests à écrire

- API : la CI échoue si `openapi.json` n'est pas à jour, et sur un changement cassant détecté par `oasdiff`.
- Clients : la compilation contre la spec fait office de test de contrat ; les doublures de test (MSW sur le web, faux serveur sur mobile) utilisent les types générés.
- Un test par client qui décode une réponse contenant une valeur d'énumération inconnue sans planter.
- Un test par client qui décode une erreur Problem Details, et un test du traitement du 401 (session effacée, retour à la connexion).
