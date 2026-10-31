# Module : notifications push

- **Statut** : Proposé
- **ADR impactés** : BE-002, BE-004, BE-006, BE-007, BE-008, BE-009, GLB-005, GLB-013, OPS-006, AND-002, AND-004, IOS-002, IOS-004

## Quand l'utiliser

L'app mobile doit prévenir l'utilisateur **hors de l'app** : rappel, nouveau message, changement d'état qu'il attend. S'en passer quand un e-mail suffit (événement rare, non urgent), ou quand l'information n'est utile que dans l'app (afficher au prochain chargement). Jamais de message promotionnel sans accord explicite de l'utilisateur (règles d'Apple et de Google).

Hors périmètre : Web Push (VAPID). Possible plus tard ; sur iPhone, il ne fonctionne que pour une app web ajoutée à l'écran d'accueil.

## Recommandation

- **iOS : APNs en direct**, authentifié par **jeton** (clé `.p8`, JWT ES256), en HTTP/2. Pas de SDK Firebase dans l'app iOS : c'est la voie native recommandée par Apple, sans dépendance ni sous-traitant de plus, et `UserNotifications` couvre tout le besoin.
- **Android : Firebase Cloud Messaging**, API HTTP v1. C'est le seul transport push des appareils Google Play.
- **API** : un module `notifications` qui garde les appareils et les préférences, et envoie par une interface `PushSender` à deux implémentations (`ApnsSender`, `FcmSender`), plus une doublure `InMemoryPushSender` pour les tests. Chaque appareil est **lié à la session** qui l'a enregistré : une session révoquée ailleurs (réinitialisation du mot de passe, bannissement, expiration) n'est plus notifiée, même si la déconnexion n'a jamais atteint l'API.

Bonnes pratiques iOS suivies :

- **demander l'autorisation en contexte**, au moment où l'utilisateur comprend le bénéfice (après avoir créé son premier rappel, par exemple), jamais au premier lancement ; l'**autorisation provisoire** (`.provisional`, notifications discrètes sans question) est une bonne entrée en matière ;
- appeler `registerForRemoteNotifications()` à **chaque lancement** (le jeton peut changer) et envoyer le jeton à l'API **après chaque connexion et à chaque lancement** : l'API sait ainsi quel compte et quelle session l'utilisent, et que l'appareil est actif ;
- en-têtes APNs : `apns-push-type` (`alert`), `apns-topic` (bundle id), `apns-priority` (10 pour une alerte, 5 sinon), `apns-expiration`, `apns-collapse-id` pour remplacer une notification périmée ; dans le dictionnaire `aps` : `thread-id` pour regrouper, `interruption-level` (`time-sensitive` demande une capacité dédiée) ;
- **pas de contenu sensible dans la notification** : elle s'affiche sur l'écran verrouillé. Texte générique, ou extension Notification Service qui va chercher le contenu après réception ;
- toucher une notification ouvre la bonne route (`Route` de l'app, IOS-002) ;
- ne pas compter sur les notifications silencieuses (`content-available`) pour synchroniser : iOS les limite et peut les ignorer.

## Alternatives

- **FCM pour les deux plateformes** : une seule intégration côté API. Mais le SDK Firebase dans l'app iOS (poids, collecte de Google, sous-traitant de plus) et une couche de plus entre l'API et APNs. Écarté.
- **Service tiers** (OneSignal…) : campagnes et segmentation, inutiles ici, et un sous-traitant de plus.

## Intégration par brique

**API** (module `notifications`)

- Table `push_devices` : `id`, `user_id`, `session_id`, `platform` (`ios`, `android`), `token` (unique), `apns_environment` (`sandbox`, `production`), `locale`, `registered_at`, `last_seen_at`. Au plus une dizaine d'appareils par compte : au-delà, le plus ancien est retiré.
- `POST /v1/push/devices` (jeton, plateforme, environnement, langue dans le corps) : enregistre l'appareil pour l'utilisateur **et la session** de la requête, met à jour `last_seen_at`, renvoie son `id`. Un jeton déjà connu pour un autre compte **passe** au compte actuel (même appareil, autre session). Risque accepté : quelqu'un qui connaîtrait le jeton d'un autre appareil pourrait le rattacher à son compte ; un jeton ne circule pas hors de l'appareil et de l'API.
- `DELETE /v1/push/devices/:id` : appelé à la déconnexion, **avant** la révocation de la session ; seul le propriétaire peut supprimer son appareil (404 sinon). **Jamais de jeton dans une URL** : l'API journalise les URL (BE-007).
- Envoi seulement aux appareils dont la session est encore active, vérifiée par l'`index.ts` du module `auth` (BE-002).
- Table `notification_preferences` (`user_id`, `category`, `enabled`) et routes de lecture et de modification ; chaque envoi la respecte.
- Contrat `PushSender` : `send(devices, notification)` renvoie **un résultat par appareil** (`sent`, `invalid-token`, `retry`, `config-error`), que le module applique :
  - APNs `410 Unregistered` → supprimer l'appareil si son jeton a été enregistré avant l'horodatage de la réponse ; `400 BadDeviceToken` isolé → supprimer ; `DeviceTokenNotForTopic`, ou une vague de `BadDeviceToken` → erreur de configuration : **alerter sans supprimer** ;
  - FCM `UNREGISTERED` → supprimer ; `INVALID_ARGUMENT` → alerter sans supprimer ;
  - `429` et `5xx` → nouvel essai avec délai croissant, en respectant `Retry-After`.
- Envoi après la validation de la transaction qui le déclenche. Au-delà de quelques envois par requête, une file de tâches : ADR à écrire.
- Texte construit par l'API dans la langue de l'appareil (`locale`), à partir des mêmes textes pour les deux plateformes.
- APNs : client HTTP/2 natif de Node, JWT signé avec `jose`, **gardé en cache** et renouvelé entre 20 et 60 minutes (un JWT par requête donne `429 TooManyProviderTokenUpdates`). FCM : API HTTP v1 avec un jeton OAuth du compte de service (`google-auth-library`), sans le SDK `firebase-admin` complet.
- Configuration : `env.ts` exige les variables APNs et FCM en production (démarrage refusé sinon, GLB-005) ; en développement, sans elles, un `PushSender` qui journalise « notification non envoyée » sans jeton ; en test, `InMemoryPushSender` remplace le provider, comme `InMemoryMailer`.
- Variables dans `env.ts` et `.env.example` : `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_TOPIC` ; secrets : `APNS_KEY` et `FCM_SERVICE_ACCOUNT`, **encodés en base64** (ce sont des fichiers sur plusieurs lignes).
- Purge propre au module (voir « Purges » dans le [README du catalogue](README.md#purges)) : appareils dont la session n'existe plus, ou sans activité depuis plusieurs mois.

**Android**

- `firebase-messaging` (BoM Firebase) et plugin Gradle `com.google.gms.google-services`.
- `google-services.json` est ignoré par git (GLB-005) : la CI le reçoit d'un secret d'Environment GitHub (en base64), écrit avant le build.
- Permission `POST_NOTIFICATIONS` (Android 13 et plus), demandée en contexte comme sur iOS.
- Canaux de notification par catégorie, créés au démarrage ; `onNewToken` et chaque connexion envoient le jeton à l'API.
- Écran verrouillé : `VISIBILITY_PRIVATE` avec une version publique sans contenu.
- À la déconnexion : suppression côté API, puis `FirebaseMessaging.deleteToken()`.
- Toucher la notification ouvre la bonne destination de navigation (AND-002).

**iOS**

- Capacité « Push Notifications » (droit `aps-environment`), `UNUserNotificationCenterDelegate` pour l'affichage au premier plan et le toucher.
- L'environnement APNs dépend du **profil de provisioning** : profil de développement → sandbox ; distribution (TestFlight, App Store) → production. L'app envoie son environnement avec le jeton.
- `APIClient` gagne les méthodes `post` (avec corps JSON) et `delete` nécessaires.

**Web**

- Préférences de notification dans « Mon compte », si l'utilisateur a aussi l'app mobile.

**Infra**

- Secrets saisis à la main : recette « Secrets saisis à la main » du [README du catalogue](README.md#secrets-saisis-à-la-main).

## Comptes et secrets (checklist du projet)

À reporter dans l'issue « Mise en route » du projet (section Mobile) :

- [ ] Apple : clé APNs `.p8` **par environnement de l'API**, limitée à l'app si Apple le permet (clés par app et par environnement annoncées en 2025, à vérifier) ; `APNS_KEY` (base64) saisi dans Secret Manager, `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_TOPIC`. La clé n'expire pas mais se révoque : la ranger dans le gestionnaire de mots de passe, la renouveler une fois par an (OPS-006). Ajouter `*.p8` au `.gitignore`.
- [ ] Firebase : projet créé, app Android déclarée ; `google-services.json` en secret d'Environment GitHub ; **un compte de service par environnement**, avec le seul rôle d'envoi FCM ; `FCM_SERVICE_ACCOUNT` (base64) saisi dans Secret Manager ; rotation annuelle de la clé.
- [ ] Fiches des stores : déclarer les identifiants d'appareil (Data safety, App Privacy).

## Données personnelles (GLB-013)

- Un jeton d'appareil est une donnée personnelle : `NotificationsUserData` exporte les appareils (plateforme, dates) et les préférences, et efface tout avec le compte.
- Apple et Google sont déjà listés comme sous-traitants des apps mobiles ; préciser l'usage push dans la politique.
- Pas de donnée personnelle dans le contenu de la notification (logs des services push, écran verrouillé).

## Pièges

- **Jeton envoyé seulement s'il change** : après une déconnexion puis une connexion avec le même jeton, le nouveau compte ne reçoit rien, et `last_seen_at` ne bouge plus.
- **Appareil d'une session révoquée** encore notifié (téléphone volé, mot de passe réinitialisé) : d'où le lien avec la session.
- **Mauvais environnement APNs** : un jeton sandbox envoyé en production répond `BadDeviceToken`. Garder l'environnement avec le jeton.
- **Erreur de configuration prise pour des jetons invalides** : une mauvaise clé ou un mauvais topic ferait supprimer tous les appareils.
- **Autorisation demandée au lancement** : refus fréquent et définitif (l'utilisateur doit passer par les Réglages).
- **Logs** : ne journaliser ni les jetons (ni le chemin des requêtes APNs, `/3/device/<jeton>`), ni le contenu des notifications (BE-007).
- **Clé APNs révoquée** : tous les envois échouent ; alerte Sentry sur les erreurs d'authentification APNs et FCM.

## Tests à écrire

API, niveau e2e (PostgreSQL en Testcontainers, `InMemoryPushSender`) :

- chaque route sans session → 401 ; suppression de l'appareil d'un autre → 404 ;
- enregistrement, puis reconnexion avec le même jeton sur un autre compte → l'appareil passe au nouveau compte et à sa session ;
- session révoquée (déconnexion ailleurs, réinitialisation du mot de passe, bannissement) → plus aucun envoi à cet appareil ;
- envoi seulement à l'utilisateur ciblé ; rien si la transaction qui le déclenche échoue ; préférence désactivée → aucun envoi ;
- résultats de la doublure : `invalid-token` → appareil supprimé ; `config-error` → appareil gardé et alerte ; `retry` → nouvel essai ;
- purge : appareils sans session ou inactifs supprimés, appareils actifs gardés ;
- export et effacement avec le compte ;
- aucun jeton dans les logs de requête ;
- démarrage refusé en production sans les variables APNs et FCM.

API, niveau unitaire :

- correspondance des réponses APNs et FCM vers `sent`, `invalid-token`, `retry`, `config-error` (dont l'horodatage d'un `410`) ;
- JWT APNs : réutilisé avant 20 minutes, renouvelé avant 60 (horloge injectée) ;
- requêtes construites (en-têtes, dictionnaire `aps`, environnement) ; adaptateurs testés contre un serveur HTTP/2 local, car nock et MSW n'interceptent pas `node:http2`.

Apps :

- iOS : `xcrun simctl push` avec un fichier `.apns` pour l'affichage et l'ouverture de la bonne route ; test du ViewModel qui renvoie le jeton après chaque connexion.
- Android : test unitaire de l'envoi du jeton (`onNewToken`, connexion) ; test UI de l'ouverture de la destination depuis une intention de notification.
- À la main (`A-VERIFIER.md`) : réception sur un vrai iPhone (TestFlight, APNs production) et un vrai Android ; plus rien après la déconnexion ni après une réinitialisation du mot de passe faite depuis le web ; mode Ne pas déranger ; écran verrouillé sans contenu.
