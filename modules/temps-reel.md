# Module : temps réel (SSE, WebSocket)

- **Statut** : Proposé
- **ADR impactés** : BE-002, BE-004, BE-005, BE-006, BE-007, OPS-004, OPS-005, FE-004, AND-004, IOS-004

## Quand l'utiliser

L'écran doit se mettre à jour **sans que l'utilisateur recharge** : notification dans l'app, état d'un traitement long, édition à plusieurs, messagerie, présence.

S'en passer quand une mise à jour au retour sur l'écran suffit (TanStack Query recharge au focus), ou quand une requête répétée toutes les 30 à 60 secondes convient : c'est plus simple à déployer et à tester. Hors de l'app, c'est le module [notifications push](notifications-push.md).

## Recommandation

**Commencer par Server-Sent Events (SSE)**, passer à **WebSocket** seulement pour un vrai besoin bidirectionnel.

| Besoin | Choix |
|---|---|
| Le serveur prévient le client (notification, avancement, « la liste a changé ») | **SSE** |
| Échanges fréquents dans les deux sens (chat avec indicateur de saisie, édition à plusieurs, jeu) | **WebSocket** |

Pourquoi SSE d'abord : c'est du HTTP ordinaire. L'authentification (cookie sur le web, `Bearer` sur mobile), le CORS, les logs et le proxy fonctionnent comme pour le reste de l'API ; le navigateur se reconnecte seul (`EventSource`, `Last-Event-ID`). Le client envoie ses actions par les routes REST habituelles, validées et protégées comme les autres.

**Le message temps réel signale, l'API reste la source** : un événement dit « la note 42 a changé », le client recharge par la route REST (ou met à jour son cache TanStack Query). On évite ainsi un second contrat de données et les droits d'accès restent vérifiés au même endroit.

**Plusieurs instances** : un conteneur ne voit que ses propres connexions. Un événement produit sur une instance doit atteindre les clients connectés aux autres : **PostgreSQL `LISTEN` / `NOTIFY`** suffit pour ces apps (aucune infra en plus, message de 8 000 octets au plus, d'où « signaler, pas transporter ») ; **Redis pub/sub** (Managed Redis Scaleway) au-delà, par un ADR.

## Alternatives

- **Socket.IO** : salles et reconnexion prêtes, mais protocole propre qui impose sa bibliothèque à chaque client (web, Android, iOS). Écarté.
- **Service managé** (Ably, Pusher, Centrifugo hébergé) : passe à l'échelle sans effort, mais sous-traitant de plus et données hors de l'infra (GLB-013).
- **Requête répétée** : voir « Quand l'utiliser ».

## Intégration par brique

**API**

- **SSE** : route `GET /v1/events` protégée comme les autres, réponse `text/event-stream` (`@Sse()` de NestJS), un commentaire de maintien (`:`) toutes les 15 à 30 secondes, `id` d'événement pour la reprise.
- **WebSocket** : `@nestjs/websockets` avec l'adaptateur `ws` (`@nestjs/platform-ws`), pas Socket.IO. À l'ouverture :
  - vérifier l'**en-tête `Origin`** contre la liste des origines du web (sinon une page tierce ouvre une connexion avec le cookie de l'utilisateur) ;
  - authentifier : cookie de session sur le web, `Authorization: Bearer` sur mobile (OkHttp et `URLSessionWebSocketTask` savent l'envoyer). **Jamais de jeton dans l'URL** : il finirait dans les logs ;
  - valider chaque message reçu avec un schéma Zod (BE-005), limiter sa taille et son débit.
- Dans les deux cas : **revérifier la session** régulièrement (toutes les quelques minutes) et fermer la connexion d'une session révoquée ou d'un compte banni ; ne diffuser à un utilisateur que les événements de **ses** ressources.
- Une connexion `LISTEN` ne passe pas par le pool : connexion dédiée, reconnectée si elle tombe, et jamais de donnée personnelle dans le message `NOTIFY` (il signale un id de ressource).
- Un module `realtime` qui expose `publish(userId, event)` aux autres modules (par son `index.ts`, BE-002) et relaie par `LISTEN` / `NOTIFY` sur une connexion PostgreSQL dédiée.

**Web**

- SSE : `EventSource` avec `withCredentials: true` ; à chaque événement, `queryClient.invalidateQueries` sur la bonne clé (FE-004). Fermer la connexion à la déconnexion.
- WebSocket : reconnexion avec délai croissant et aléa ; resynchroniser par REST après chaque reconnexion (des événements ont pu être perdus).

**Android / iOS**

- Connexion ouverte seulement au premier plan (cycle de vie de l'écran ou de l'app) ; en arrière-plan, ce sont les notifications push qui prennent le relais.
- Android : OkHttp (`okhttp-sse` ou `WebSocket`) ; iOS : `URLSession.bytes(for:)` pour SSE, `URLSessionWebSocketTask` pour WebSocket.

**Infra (Scaleway Serverless Containers)**

- Les WebSockets sont acceptés sur les domaines personnalisés des conteneurs depuis 2025 ; à vérifier en staging au premier usage.
- Une connexion longue est une requête en cours : elle est coupée au **délai maximal de requête** du conteneur (réglable, jusqu'à 60 minutes d'après la doc actuelle). Le client doit se reconnecter de toute façon.
- Les connexions ouvertes comptent dans la concurrence du conteneur et l'empêchent de descendre à zéro : prévoir `min_scale` et `max_concurrency` en conséquence, et le coût qui va avec.
- Edge Services ou proxy : désactiver la mise en cache et la mise en mémoire tampon sur `/v1/events`.

## Comptes et secrets (checklist du projet)

- Aucun compte ni secret (Redis managé seulement au-delà de `LISTEN` / `NOTIFY`).

## Données personnelles (GLB-013)

- Aucune donnée nouvelle si le message ne fait que signaler ; ne rien journaliser du contenu des messages (BE-007).
- Messagerie : les messages sont des données personnelles du module qui les stocke, avec leur `UserDataContributor`.

## Pièges

- **Origine non vérifiée** à l'ouverture d'un WebSocket (détournement de connexion entre sites).
- **Session révoquée** qui garde sa connexion ouverte pendant des heures.
- **Événement diffusé à tous** au lieu des seuls ayants droit.
- **Jeton dans l'URL** de connexion.
- **Proxy qui met la réponse SSE en tampon** : rien n'arrive jusqu'à la fin de la connexion.
- **Pas de resynchronisation** après une coupure : l'écran affiche un état faux.
- **Tests instables** : attendre un événement précis avec un délai maximal, jamais une pause fixe.

## Tests à écrire

- E2E (API réelle, PostgreSQL en Testcontainers) : un client reçoit l'événement de sa ressource, pas celui d'un autre utilisateur ; connexion sans session → 401 ; WebSocket avec une `Origin` inconnue → refusé.
- Session révoquée ou compte banni → connexion fermée au contrôle suivant.
- Deux instances de l'app de test sur la même base : un événement publié sur l'une arrive au client connecté à l'autre (`LISTEN` / `NOTIFY`).
- Message WebSocket invalide ou trop gros → rejeté sans fermer le serveur.
- Web : à un événement reçu, la bonne requête est invalidée (MSW et un faux `EventSource`).
- À la main en staging (`A-VERIFIER.md`) : connexion à travers le domaine personnalisé et Edge Services, coupure au délai maximal, puis reconnexion.
