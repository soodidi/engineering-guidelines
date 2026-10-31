# Module : upload de fichiers

- **Statut** : Proposé
- **ADR impactés** : BE-002, BE-005, BE-006, BE-007, BE-008, GLB-013, OPS-001, OPS-003, OPS-005, OPS-006, OPS-007, FE-008, FE-009, AND-004, IOS-004

## Quand l'utiliser

L'utilisateur envoie des images, des documents ou des pièces jointes que l'app garde. S'en passer quand une URL externe suffit, ou quand le fichier n'a pas besoin d'être conservé (traité puis jeté : le passer directement dans le corps d'une requête à l'API, avec une limite de taille).

## Recommandation

**Object Storage Scaleway**, bucket **privé**, **POST présigné** vers une zone d'arrivée, puis **copie par l'API** vers l'emplacement définitif :

1. le client demande l'autorisation d'envoyer (`POST /v1/files/uploads` avec nom, type, taille) ;
2. l'API vérifie le type, la taille et le quota (envois en attente compris), crée une ligne `files` au statut `pending`, et renvoie un **POST présigné** valable **deux minutes**, avec des conditions strictes : clé exacte sous `incoming/<userId>/<uuid>`, `Content-Type` exact, `content-length-range` ;
3. le client envoie le fichier **directement au bucket** ;
4. le client confirme (`POST /v1/files/:id/complete`). L'API lit l'objet d'arrivée (taille, premiers octets pour le vrai type), puis écrit le fichier définitif sous `files/<userId>/<uuid>`, une clé qu'aucune signature donnée au client ne permet d'écrire : **copie** côté bucket pour un document, **image réencodée** (ce qui retire les métadonnées EXIF) pour une image, avec `size` mis à jour. L'objet d'arrivée est supprimé. La ligne passe à `ready` (ou `quarantined`, voir l'antivirus). En cas d'écart, l'objet est supprimé et la confirmation refusée ;
5. lecture : l'API vérifie l'appartenance, puis renvoie une **URL GET présignée** courte (5 minutes) qui fixe le type et `Content-Disposition` (`ResponseContentType`, `ResponseContentDisposition`, nom de fichier encodé).

Pourquoi :

- l'API ne reçoit pas les octets à l'envoi, et le bucket reste privé. Elle ne lit l'objet qu'à la confirmation : quelques octets pour un document, l'image entière pour la réencoder (d'où une taille maximale plus basse pour les images que pour les documents) ;
- la copie vers une clé que le client ne peut pas signer empêche de **remplacer un fichier après sa vérification** (un POST présigné reste valable quelques minutes) ;
- chaque lecture passe par la vérification d'appartenance (BE-006).

## Alternatives

- **Envoi par l'API** (multipart vers NestJS, qui écrit dans le bucket) : plus simple à valider, acceptable pour de petits fichiers (moins de 5 Mo) et peu de trafic ; consomme la mémoire et la durée de requête du conteneur.
- **PUT présigné** au lieu du POST : il signe le `Content-Type` et une taille exacte, mais pas un intervalle de tailles ; moins souple, à écarter.
- **Service tiers d'images** (transformation, CDN) : utile pour beaucoup d'images publiques ; c'est un sous-traitant de plus (GLB-013).

## Intégration par brique

**API** (module `files`, BE-002)

- Table `files` : `id`, `user_id`, `key`, `content_type`, `size`, `original_name` (nettoyé, pour l'affichage), `status` (`pending`, `quarantined`, `ready`), `created_at`. La **clé est générée par l'API**, jamais construite avec le nom envoyé par le client.
- Signature avec `@aws-sdk/client-s3` et `@aws-sdk/s3-presigned-post` (API S3 de Scaleway, signature v4). Chaque champ du formulaire doit avoir sa condition dans la politique.
- Liste blanche de types par usage (ex. `image/jpeg`, `image/png`, `image/webp`, `application/pdf`), contrôlée sur le type déclaré à la demande, puis sur les premiers octets à la confirmation (le `Content-Type` déclaré peut mentir). Réencodage des images avec `sharp`, dans la limite de taille fixée.
- Limite de débit sur `POST /v1/files/uploads` ; quota par utilisateur qui compte aussi les envois `pending`.
- `index.ts` expose `attach(fileId, userId)` aux autres modules : il vérifie que le fichier appartient à l'utilisateur et qu'il est `ready`. Un module ne référence jamais un `fileId` sans passer par là (sinon IDOR).
- **Purge propre au module** (BE-002 : pas dans celle du module `auth`), sur le même modèle que `ExpiredAuthDataPurge` : lignes `pending` de plus de 24 h et leurs objets. Elle tourne au démarrage puis toutes les 24 h : en staging (mise à zéro des instances), elle ne tourne qu'aux démarrages.
- Variables dans `env.ts`, `.env.example` et `compose.yaml` : `S3_ENDPOINT`, `S3_REGION`, `S3_BUCKET` ; secrets : `S3_ACCESS_KEY`, `S3_SECRET_KEY`.

**Web**

- `<input type="file" accept="…">`, contrôle de taille avant l'envoi (confort seulement : l'API et le bucket font foi).
- `FormData` avec les champs renvoyés par l'API, **le fichier en dernier** (exigence S3), puis la confirmation. Progression avec `XMLHttpRequest`.
- Politique de sécurité du contenu, si elle existe : domaine du bucket dans `connect-src` (envoi) et `img-src` (affichage).
- Sentry : retirer la chaîne de requête des URL du bucket dans les fils d'Ariane (`beforeBreadcrumb`) ; une URL présignée donne l'accès au fichier.

**Android**

- Photo Picker (`PickVisualMedia`) : aucune permission de stockage à demander.
- Envoi multipart avec OkHttp ; gros fichiers ou envoi en arrière-plan : WorkManager.

**iOS**

- `PhotosPicker` ; envoi avec `URLSession` (`upload(for:fromFile:)`), en session d'arrière-plan pour les gros fichiers.

**Infra**

- `scaleway_object_bucket` privé par environnement, dans la région de l'app.
- **Bucket policy** (`scaleway_object_bucket_policy`) qui ne cite que l'application IAM de l'API de **cet** environnement et celles de la CI infra (`ci`, `ci-plan`), sur le modèle de `modules/static-site`. Indispensable : chez Scaleway, les droits IAM Object Storage valent pour **tout le projet**, pas pour un bucket ; sans policy, la clé de l'API de staging lit les fichiers de production et le bucket du state, et la clé `deploy-web` aussi.
- **Une clé par environnement**, créée dans `envs/iam` (module `api-key` avec `for_each` sur `staging` et `production`, comme le module `smtp`), droits limités à la lecture, l'écriture et la suppression d'objets ; chaque environnement lit **sa** clé avec `terraform_remote_state` et la passe en `secret_environment_variables` (OPS-006, comme `SMTP_URL`). Ré-appliquer `envs/iam` à la main ; rotation : `tofu apply -replace` sur la clé dans `envs/iam`, puis ré-appliquer l'environnement.
- CORS : origines de `var.web_origin` (une liste séparée par des virgules : la découper), méthode `POST` (et `GET` si le web lit les fichiers avec `fetch`).
- Cycle de vie : abandon des envois multipart incomplets ; expiration des objets de `incoming/` après un jour (rattrape les envois jamais confirmés, y compris après la suppression d'un compte).
- **Production** : versioning activé (OPS-007), avec `noncurrent_version_expiration` égale à la durée des sauvegardes annoncée dans la politique de confidentialité (sinon un fichier effacé survit pour toujours dans ses versions).
- En local : un émulateur S3 dans `compose.yaml` et dans Testcontainers, qui **applique les conditions du POST** (sinon les tests ne prouvent rien). MinIO le fait, mais son édition communautaire est en maintenance : vérifier la licence et l'état de l'image au moment de l'ajouter. `forcePathStyle` en local seulement, et une URL signée pour `localhost` (joignable par le navigateur), pas pour le nom du service dans compose.

## Comptes et secrets (checklist du projet)

À reporter dans l'issue « Mise en route » du projet :

- [ ] `envs/iam` ré-appliqué à la main pour créer la clé Object Storage de l'API (rien à saisir : OpenTofu la passe au conteneur).
- [ ] Plan OpenTofu relu avant l'`apply` : bucket privé, policy limitée à l'API et à la CI, CORS, cycle de vie, versioning en production.
- [ ] Section Légal : durée de conservation des versions du bucket reportée dans la politique de confidentialité.

## Données personnelles (GLB-013)

- Un fichier envoyé par l'utilisateur est une donnée personnelle, couverte par `FilesUserData` (`@ContributesUserData()`).
- **Effacement** : le contrat n'a qu'`erase(userId, tx)`, appelé avant la suppression du compte (puis une seconde fois après). `erase` supprime d'abord les objets de `files/<userId>/` et `incoming/<userId>/`, puis les lignes dans la transaction. Si le bucket ne répond pas, `erase` échoue : la transaction est annulée, le compte reste, et l'utilisateur réessaie. Si la transaction échoue après la suppression des objets, la ligne reste sans objet (son lien de lecture échoue côté bucket) jusqu'à la tentative suivante, qui la supprime : la suppression S3 est idempotente.
- **Export** : métadonnées de chaque fichier et lien de téléchargement présigné valable 24 heures. Une archive complète (zip) se décide au premier usage, si les fichiers sont nombreux.
- Photos : le réencodage à la confirmation retire les métadonnées EXIF (position GPS, appareil).
- Versions du bucket en production : leur durée de vie est écrite dans la politique de confidentialité.

## Pièges

- **Remplacement après vérification** : sans copie vers une clé que seul l'API écrit, un second envoi sur la même clé contourne le contrôle du type et l'antivirus.
- **SVG et HTML** : servis tels quels, ils exécutent du JavaScript. Les refuser, ou les servir en `Content-Disposition: attachment` depuis le domaine du bucket, jamais depuis celui de l'app.
- **Ordre et conditions du POST présigné** : le fichier en dernier champ ; une condition pour chaque champ, sinon Scaleway refuse.
- **Taille** : le POST présigné plafonne à 5 Go ; au-delà, upload multipart présigné (rarement utile pour ces apps).
- **Bucket sans policy** : la clé d'un environnement atteint tous les buckets du projet.
- **Antivirus** : nécessaire dès qu'un fichier envoyé par un utilisateur est ouvert par un autre (partage, admin). ClamAV dans un Serverless Job déclenché à la confirmation : fichier `quarantined` jusqu'au résultat. Le Job demande une clé avec les droits Jobs et un cache de la base de signatures (les miroirs officiels limitent le débit).
- **Logs et Sentry** : ne jamais journaliser une URL présignée (BE-007).

## Tests à écrire

Niveau intégration : API réelle, PostgreSQL et émulateur S3 en Testcontainers (BE-008).

- Accès : chaque route sans session → 401.
- Demande d'envoi : type ou taille hors liste → 400 ; quota atteint (envois en attente compris) → refus ; la politique signée contient la clé exacte, le `Content-Type` et le `content-length-range`.
- Envoi trop gros ou sous une autre clé → refusé par le bucket (émulateur).
- Confirmation : objet absent, taille ou type réel différent, SVG ou HTML déguisé en image → refus et objet supprimé ; fichier d'un autre utilisateur → 404 ; après confirmation, l'objet final est sous `files/` et l'objet d'arrivée a disparu ; image réencodée sans EXIF.
- Lecture : URL présignée seulement pour le propriétaire (404 sinon), avec le type et `Content-Disposition` fixés.
- `attach` : fichier d'un autre utilisateur, `pending` ou `quarantined` refusé ; un fichier `quarantined` n'est jamais servi en lecture.
- POST présigné rejoué après la confirmation : le fichier définitif ne change pas (il est sous `files/`, que la signature ne couvre pas).
- Export : les fichiers de l'utilisateur, et seulement les siens.
- Effacement du compte : plus aucune ligne ni aucun objet sous les préfixes de l'utilisateur ; bucket indisponible → suppression du compte refusée, compte intact.
- Purge : une ligne `pending` ancienne et son objet disparaissent.
- Revue (agent `security`) : aucune URL présignée dans les logs ni dans Sentry.
- Web : E2E du parcours d'envoi avec MSW (demande, envoi, confirmation, erreur de taille).
- En staging, à la main (`A-VERIFIER.md`) : envoi réel par POST présigné, envoi trop gros refusé par le bucket, lecture d'un objet sans signature → 403, CORS refusé depuis une autre origine, suppression d'un compte qui vide ses préfixes.
