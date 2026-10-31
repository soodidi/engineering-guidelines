# Module : notifications push

- **Statut** : Proposé
- **ADR impactés** : BE-002, BE-006, BE-007, BE-009, GLB-013, GLB-005, OPS-006, AND-002, AND-004, IOS-002, IOS-004

## Quand l'utiliser

L'app mobile doit prévenir l'utilisateur **hors de l'app** : rappel, nouveau message, changement d'état qu'il attend. S'en passer quand un e-mail suffit (événement rare, non urgent), ou quand l'information n'est utile que dans l'app (afficher au prochain chargement). Jamais de message promotionnel sans accord explicite de l'utilisateur (règles d'Apple et de Google).

Hors périmètre : Web Push (VAPID). Possible plus tard ; sur iPhone, il ne fonctionne que pour une app web ajoutée à l'écran d'accueil.

## Recommandation

- **iOS : APNs en direct**, authentifié par **jeton** (clé `.p8`, JWT ES256), en HTTP/2. Pas de SDK Firebase dans l'app iOS : c'est la voie native recommandée par Apple, sans dépendance ni sous-traitant de plus, et `UserNotifications` couvre tout le besoin.
- **Android : Firebase Cloud Messaging** (API HTTP v1). C'est le seul transport push des appareils Google Play.
- **API** : un module `notifications` qui garde les appareils et les préférences, et envoie par une interface `PushSender` (comme `Mailer`, BE-009) avec deux implémentations, `ApnsSender` et `FcmSender`, et une doublure `InMemoryPushSender` pour les tests.

Bonnes pratiques iOS suivies :

- **demander l'autorisation en contexte**, au moment où l'utilisateur comprend le bénéfice (après avoir créé son premier rappel, par exemple), jamais au premier lancement ; l'**autorisation provisoire** (`.provisional`, notifications discrètes sans question) est une bonne entrée en matière ;
- appeler `registerForRemoteNotifications()` à **chaque lancement** : le jeton peut changer (restauration, réinstallation) ; l'envoyer à l'API seulement s'il a changé ;
- en-têtes APNs explicites : `apns-push-type: alert`, `apns-topic` (bundle id), `apns-collapse-id` pour remplacer une notification périmée, `thread-id` pour les regrouper, `interruption-level` (`time-sensitive` demande une capacité dédiée) ;
- **pas de contenu sensible dans la notification** : elle s'affiche sur l'écran verrouillé. Texte générique, ou extension Notification Service qui va chercher le contenu après réception ;
- toucher une notification ouvre la bonne route (`Route` de l'app, IOS-002) ;
- ne pas compter sur les notifications silencieuses (`content-available`) pour synchroniser : iOS les limite et peut les ignorer.

## Alternatives

- **FCM pour les deux plateformes** : une seule intégration côté API. Mais le SDK Firebase dans l'app iOS (poids, collecte de Google, sous-traitant de plus) et une couche de plus entre l'API et APNs. Écarté.
- **Service tiers** (OneSignal…) : campagnes et segmentation, inutiles ici, et un sous-traitant de plus.

## Intégration par brique

**API** (module `notifications`)

- Table `push_devices` : `id`, `user_id`, `platform` (`ios`, `android`), `token` (unique), `apns_environment` (`sandbox`, `production`), `locale`, `last_seen_at`.
- `PUT /v1/push/devices` : enregistre ou met à jour le jeton de l'appareil pour l'utilisateur connecté. Un jeton déjà connu pour un autre compte **passe** au compte actuel (même appareil, autre session).
- `DELETE /v1/push/devices/:token` : appelé à la déconnexion, **avant** la révocation de la session ; seul le propriétaire peut supprimer son jeton (404 sinon).
- Table `notification_preferences` (`user_id`, `category`, `enabled`) et routes de lecture et de modification ; chaque envoi la respecte.
- Envoi après la validation de la transaction qui le déclenche. Erreurs : APNs `410 Unregistered` ou `400 BadDeviceToken`, FCM `UNREGISTERED` → **supprimer le jeton** ; `429` et `5xx` → nouvel essai avec délai croissant. Au-delà de quelques envois par requête, une file de tâches : ADR à écrire.
- Texte construit par l'API dans la langue de l'appareil (`locale`), à partir des mêmes textes pour les deux plateformes.
- APNs : client HTTP/2 natif de Node et JWT signé (bibliothèque `jose`), renouvelé avant 60 minutes ; FCM : `firebase-admin` ou l'API HTTP v1 avec le compte de service.
- Purge propre au module (voir « Purges » dans le [README du catalogue](README.md#purges)) : appareils sans activité depuis plusieurs mois.
- Variables dans `env.ts` et `.env.example` : `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_TOPIC` ; secrets : `APNS_KEY`, `FCM_SERVICE_ACCOUNT`. En local et en test, `InMemoryPushSender` : aucun secret nécessaire.

**Android**

- `firebase-messaging` (BoM Firebase), `google-services.json` du projet Firebase.
- Permission `POST_NOTIFICATIONS` (Android 13 et plus), demandée en contexte comme sur iOS.
- Canaux de notification par catégorie, créés au démarrage ; `onNewToken` envoie le nouveau jeton à l'API.
- Toucher la notification ouvre la bonne destination de navigation (AND-002).

**iOS**

- Capacité « Push Notifications » (droit `aps-environment`), `UNUserNotificationCenterDelegate` pour l'affichage au premier plan et le toucher.
- Un build Debug reçoit ses jetons d'APNs **sandbox**, un build Release ou TestFlight ceux de **production** : l'app envoie son environnement avec le jeton.

**Web**

- Préférences de notification dans « Mon compte », si l'utilisateur a aussi l'app mobile.

**Infra**

- Secrets saisis à la main : recette « Secrets saisis à la main » du [README du catalogue](README.md#secrets-saisis-à-la-main).

## Comptes et secrets (checklist du projet)

À reporter dans l'issue « Mise en route » du projet (section Mobile) :

- [ ] Apple : clé APNs (`.p8`) créée dans le compte développeur → `APNS_KEY` saisi dans Secret Manager (staging et production), `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_TOPIC` (bundle id). Une clé sert à toutes les apps de l'équipe : la ranger dans le gestionnaire de mots de passe.
- [ ] Firebase : projet créé, app Android déclarée, `google-services.json` dans l'app ; compte de service limité à l'envoi FCM → `FCM_SERVICE_ACCOUNT` (JSON) saisi dans Secret Manager.
- [ ] Fiches des stores : déclarer les identifiants d'appareil (Data safety, App Privacy).

## Données personnelles (GLB-013)

- Un jeton d'appareil est une donnée personnelle : `NotificationsUserData` exporte les appareils (plateforme, dates) et les préférences, et efface tout avec le compte.
- Apple et Google sont déjà listés comme sous-traitants des apps mobiles ; préciser l'usage push dans la politique.
- Pas de donnée personnelle dans le contenu de la notification (logs des services push, écran verrouillé).

## Pièges

- **Mauvais environnement APNs** : un jeton sandbox envoyé en production répond `BadDeviceToken`. Garder l'environnement avec le jeton.
- **Jeton qui reste après la déconnexion** : l'utilisateur suivant de l'appareil recevrait les notifications du précédent.
- **Autorisation demandée au lancement** : refus fréquent et définitif (l'utilisateur doit passer par les Réglages).
- **Logs** : ne journaliser ni les jetons ni le contenu des notifications (BE-007).
- **Clé APNs révoquée ou expirée** : tous les envois échouent ; alerte Sentry sur les erreurs d'authentification APNs.

## Tests à écrire

- API (e2e, PostgreSQL en Testcontainers, `InMemoryPushSender`) : chaque route sans session → 401 ; enregistrement et mise à jour d'un jeton ; jeton repris par un autre compte ; suppression du jeton d'un autre → 404 ; préférence désactivée → aucun envoi ; réponse « jeton invalide » de la doublure → jeton supprimé ; export et effacement avec le compte.
- API (unitaire) : construction de la requête APNs (en-têtes, JWT) et FCM à partir d'une notification.
- iOS : `xcrun simctl push` avec un fichier `.apns` pour vérifier l'affichage et l'ouverture de la bonne route ; tests du ViewModel qui n'envoie le jeton que s'il change.
- Android : test unitaire de `onNewToken` ; test UI de l'ouverture de la destination depuis une intention de notification.
- À la main (`A-VERIFIER.md`) : réception sur un vrai iPhone (TestFlight, APNs production) et un vrai Android, après déconnexion (plus rien), en mode Ne pas déranger.
