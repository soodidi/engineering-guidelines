# Module : upload de fichiers

- **Statut** : Proposé
- **ADR impactés** : BE-002, BE-005, BE-006, BE-008, GLB-013, OPS-003, OPS-005, OPS-006, FE-008, AND-004, IOS-004

## Quand l'utiliser

L'utilisateur envoie des images, des documents ou des pièces jointes que l'app garde. S'en passer quand une URL externe suffit, ou quand le fichier n'a pas besoin d'être conservé (traité puis jeté : le passer directement dans le corps d'une requête à l'API, avec une limite de taille).

## Recommandation

**Object Storage Scaleway**, bucket **privé**, et **URL présignées** :

1. le client demande l'autorisation d'envoyer (`POST /v1/files/uploads` avec nom, type, taille) ;
2. l'API vérifie le type, la taille et le quota, crée une ligne `files` au statut `pending`, et renvoie un **POST présigné** valable quelques minutes, avec ses conditions : clé imposée, `content-length-range`, `Content-Type` ;
3. le client envoie le fichier **directement au bucket** : il ne passe pas par l'API ;
4. le client confirme (`POST /v1/files/:id/complete`) ; l'API relit l'objet (taille, premiers octets pour le vrai type), passe la ligne à `ready`, ou supprime l'objet et refuse ;
5. lecture : l'API vérifie l'appartenance, puis renvoie une **URL GET présignée** courte (5 minutes).

Pourquoi : l'API ne transporte pas les octets (pas de mémoire ni de délai de requête consommés sur Serverless Containers), le bucket reste privé, et chaque accès passe par la vérification d'appartenance (BE-006).

## Alternatives

- **Envoi par l'API** (multipart vers NestJS, puis l'API écrit dans le bucket) : plus simple à valider, acceptable pour de petits fichiers (moins de 5 Mo) et peu de trafic ; consomme la mémoire et la durée de requête du conteneur.
- **PUT présigné** au lieu du POST : plus simple côté client, mais n'impose pas de taille maximale : à écarter.
- **Service tiers d'images** (transformation, CDN) : utile pour beaucoup d'images publiques ; c'est un sous-traitant de plus (GLB-013).

## Intégration par brique

**API** (module `files`, BE-002)

- Table `files` : `id`, `user_id`, `key`, `content_type`, `size`, `status` (`pending`, `ready`), `created_at`. La **clé est générée par l'API** (`users/<userId>/<uuid>`), jamais construite avec le nom envoyé par le client ; le nom d'origine se garde à part, nettoyé, pour l'affichage.
- Signature avec `@aws-sdk/client-s3` et `@aws-sdk/s3-presigned-post` (API S3 de Scaleway, signature v4).
- Liste blanche de types par usage (ex. `image/jpeg`, `image/png`, `image/webp`, `application/pdf`), contrôlée à la demande **et** à la confirmation, sur les premiers octets du fichier (le `Content-Type` déclaré peut mentir).
- Purge des lignes `pending` de plus de 24 h et de leurs objets, avec la purge quotidienne existante.
- Les autres modules référencent un fichier par son `id` et passent par l'`index.ts` du module `files`.

**Web**

- `<input type="file" accept="…">`, contrôle de taille avant l'envoi (confort seulement : l'API et le bucket font foi).
- `FormData` avec les champs renvoyés par l'API, **le fichier en dernier** (exigence S3), puis la confirmation.
- Progression avec `XMLHttpRequest` (`fetch` n'expose pas la progression d'envoi).

**Android**

- Photo Picker (`PickVisualMedia`) : aucune permission de stockage à demander.
- Envoi multipart avec OkHttp ; gros fichiers ou envoi en arrière-plan : WorkManager.

**iOS**

- `PhotosPicker` ; envoi avec `URLSession` (`upload(for:fromFile:)`), en session d'arrière-plan pour les gros fichiers.

**Infra**

- `scaleway_object_bucket` privé, dans la région de l'app ; règle CORS limitée à l'origine du web (méthode `POST`) ; règle de cycle de vie qui abandonne les envois multipart incomplets.
- Clé API dédiée à l'API, limitée à l'Object Storage du projet (OPS-006), rangée dans Secret Manager.
- Variables : `S3_ENDPOINT`, `S3_REGION`, `S3_BUCKET`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`.
- En local : un émulateur S3 dans `compose.yaml` (MinIO, Garage ou s3mock : vérifier la licence et la maintenance de l'image au moment de l'ajouter), le même dans Testcontainers.

## Comptes et secrets (checklist du projet)

- [ ] Bucket créé par OpenTofu (staging, production), privé, CORS vérifié.
- [ ] Clé API Object Storage de l'API, par environnement, dans Secret Manager.
- [ ] Durée de conservation des sauvegardes ou des versions du bucket reportée dans la politique de confidentialité.

## Données personnelles (GLB-013)

- Un fichier envoyé par l'utilisateur est une donnée personnelle : `FilesUserData` (`@ContributesUserData()`) exporte les métadonnées et **efface les objets** puis les lignes avec le compte. Les objets se suppriment hors transaction : effacer les lignes dans `beforeDelete`, puis les objets du préfixe `users/<userId>/` dans `afterDelete`, avec reprise si le bucket ne répond pas.
- **Photos** : retirer les métadonnées EXIF (position GPS, appareil) avant de stocker, côté client ou dans un traitement de l'API.
- Si le versioning du bucket est activé, un objet supprimé survit dans ses versions : fixer leur durée de vie et l'écrire dans la politique.

## Pièges

- **SVG et HTML** : servis tels quels, ils exécutent du JavaScript. Les refuser, ou les servir en `Content-Disposition: attachment` depuis le domaine du bucket, jamais depuis celui de l'app.
- **Ordre des champs du POST présigné** : le fichier doit être le dernier champ, sinon S3 refuse.
- **Taille** : le POST présigné plafonne à 5 Go ; au-delà, upload multipart présigné (rarement utile pour ces apps).
- **Bucket public par erreur** : vérifier la policy dans le plan OpenTofu ; aucun objet ne doit répondre sans signature.
- **Antivirus** : nécessaire dès qu'un fichier envoyé par un utilisateur est ouvert par un autre (partage, admin). ClamAV dans un Serverless Job déclenché à la confirmation, fichier `quarantined` tant qu'il n'est pas analysé.
- **Logs** : ne jamais journaliser une URL présignée (elle donne l'accès).

## Tests à écrire

- Demande d'envoi : type ou taille hors liste refusés (400) ; la politique signée contient la clé, le `content-length-range` et le `Content-Type`.
- Confirmation : objet absent, taille ou type réel différent → refus et objet supprimé ; fichier d'un autre utilisateur → 404 (IDOR).
- Lecture : URL présignée seulement pour le propriétaire ; 404 sinon.
- Effacement du compte : plus aucune ligne ni aucun objet sous `users/<userId>/` (intégration, émulateur S3 en Testcontainers).
- Purge : une ligne `pending` ancienne et son objet disparaissent.
- Web : E2E du parcours d'envoi avec MSW (demande, envoi, confirmation, erreur de taille).
