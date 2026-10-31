# Module : temps réel (SSE, WebSocket)

- **Statut** : Proposé
- **ADR impactés** : BE-002, BE-004, BE-005, BE-006, BE-007, BE-008, GLB-013, OPS-003, OPS-004, OPS-005, FE-002, FE-004, AND-004, IOS-004

## Quand l'utiliser

L'écran doit se mettre à jour **sans que l'utilisateur recharge** : notification dans l'app, état d'un traitement long, édition à plusieurs, messagerie, présence.

S'en passer quand une mise à jour au retour sur l'écran suffit (TanStack Query recharge au focus), ou quand une requête répétée toutes les 30 à 60 secondes convient : c'est plus simple à déployer et à tester. Hors de l'app, c'est le module [notifications push](notifications-push.md).

## Recommandation

**Commencer par Server-Sent Events (SSE)**, passer à **WebSocket** seulement pour un vrai besoin bidirectionnel.

| Besoin | Choix |
|---|---|
| Le serveur prévient le client (notification, avancement, « la liste a changé ») | **SSE** |
| Échanges fréquents dans les deux sens (chat avec indicateur de saisie, édition à plusieurs, jeu) | **WebSocket** |

Pourquoi SSE d'abord : c'est du HTTP ordinaire. L'authentification (cookie sur le web, `Bearer` sur mobile), les guards globaux, le CORS et les logs fonctionnent comme pour le reste de l'API. Le client envoie ses actions par les routes REST habituelles, validées et protégées comme les autres.

**Le message temps réel signale, l'API reste la source** : un événement dit « la note 42 a changé », le client recharge par la route REST (ou met à jour son cache TanStack Query). On évite ainsi un second contrat de données, et les droits d'accès restent vérifiés au même endroit. **Après chaque (re)connexion, le client resynchronise par REST** : rien n'est rejoué (l'API ne garde pas d'historique, donc `Last-Event-ID` ne sert à rien).

**Plusieurs instances** : un conteneur ne voit que ses propres connexions. Un événement produit sur une instance doit atteindre les clients connectés aux autres : **PostgreSQL `LISTEN` / `NOTIFY`** suffit pour ces apps (aucune infra en plus, message de moins de 8 000 octets, d'où « signaler, pas transporter ») ; **Redis pub/sub** (Managed Redis Scaleway) au-delà, par un ADR (un secret généré par OpenTofu et un coût fixe en plus).

## Alternatives

- **Socket.IO** : salles et reconnexion prêtes, mais protocole propre qui impose sa bibliothèque à chaque client (web, Android, iOS). Écarté.
- **Service managé** (Ably, Pusher, Centrifugo hébergé) : passe à l'échelle sans effort, mais sous-traitant de plus et données hors de l'infra (GLB-013).
- **Requête répétée** : voir « Quand l'utiliser ».

## Intégration par brique

**API**

- **SSE** : route `GET /v1/events` protégée comme les autres, réponse `text/event-stream` (`@Sse()` de NestJS), un commentaire de maintien toutes les 15 à 30 secondes. CORS avec `credentials` déjà configuré pour le web.
- **WebSocket** : `@nestjs/websockets` avec l'adaptateur `ws` (`@nestjs/platform-ws`), pas Socket.IO. Les guards globaux ne s'exécutent que sur les **messages**, pas à l'ouverture, et sans en-têtes HTTP : `AuthGuard` refuserait tout, et `CsrfGuard` comme `ThrottlerGuard` doivent laisser passer ce qui n'est pas du HTTP. La passerelle est donc `@Public()` **et** authentifie elle-même dans `handleConnection` :
  - session lue avec `getSession` (cookie sur le web, `Authorization: Bearer` sur mobile) ; sans session, connexion fermée. **Jamais de jeton dans l'URL** : il finirait dans les logs ;
  - **`Origin`** suit la règle de `CsrfGuard` : s'il est présent, il doit être dans la liste des origines du web (sinon une page tierce ouvre une connexion avec le cookie de l'utilisateur) ; s'il est absent (OkHttp, `URLSessionWebSocketTask`), seul un `Bearer` est accepté ;
  - `maxPayload` de 16 à 64 Kio (100 Mio par défaut dans `ws`), débit de messages limité, chaque message validé avec un schéma Zod (BE-005) ;
  - nombre de connexions plafonné par utilisateur et par IP.
- Dans les deux cas : **revérifier la session** à intervalle régulier (quelques minutes, intervalle injecté pour les tests) avec `getSession` et `disableRefresh: true` (sinon le contrôle prolonge la session), et fermer la connexion d'une session révoquée ou d'un compte banni ; ne diffuser à un utilisateur que les événements de **ses** ressources, destinataires calculés au moment de l'envoi.
- Module `realtime` qui expose `publish(userId, event)` aux autres modules (par son `index.ts`, BE-002) :
  - `pg_notify` sur un **canal fixe**, avec un message paramétré (jamais de nom de canal construit par concaténation), envoyé **dans la transaction de l'écriture** : il ne part qu'au commit ;
  - message validé avec Zod à la réception, sans donnée personnelle (un type et un id de ressource) ;
  - connexion `LISTEN` **dédiée** (hors du pool), même `DATABASE_URL` et même TLS, avec `keepAlive` et un ping régulier ; à la reconnexion (bascule de la base, coupure silencieuse), dire aux clients de resynchroniser. Budget : taille du pool + 1 connexion par instance.
- **Arrêt** (à chaque déploiement) : fermer les flux SSE et les WebSocket, puis `UNLISTEN`, avant de fermer le pool ; sinon `app.close()` attend des flux qui ne finissent jamais.

**Web**

- SSE : `EventSource` avec `withCredentials: true` ; chaque événement validé avec Zod (FE-002), puis `queryClient.invalidateQueries` sur la bonne clé (FE-004). Un `EventSource` qui reçoit un 401 ne se reconnecte pas : vérifier la session et revenir à la connexion. Fermer la connexion à la déconnexion.
- WebSocket : reconnexion avec délai croissant et aléa ; resynchroniser par REST après chaque reconnexion (comme en SSE).

**Android / iOS**

- Connexion ouverte seulement au premier plan (cycle de vie de l'écran ou de l'app) ; en arrière-plan, ce sont les notifications push qui prennent le relais.
- Android : OkHttp (`okhttp-sse` ou `WebSocket`), avec un `readTimeout` plus long que l'intervalle de maintien (10 s par défaut, plus court que le battement).
- iOS : `URLSession.bytes(for:)` pour SSE, en découpant soi-même les événements sur les lignes vides (vérifier que `lines` ne les supprime pas) ; `URLSessionWebSocketTask` pour WebSocket.

**Infra (Scaleway Serverless Containers)**

- Les WebSockets sont acceptés sur les domaines personnalisés des conteneurs depuis août 2025 ; à vérifier en staging au premier usage.
- Une connexion longue est une requête en cours : elle est coupée au **délai maximal de requête** du conteneur. Le module `app-service` le fixe **en dur à 60 secondes** (`timeout = 60`) : l'exposer en variable et le monter (900 à 3 600 s, plafond actuel de Scaleway). Ce délai vaut aussi pour les requêtes REST. Le client doit se reconnecter de toute façon.
- Chaque connexion ouverte occupe une place de concurrence (80 au plus par instance) : capacité = 80 × `max_scale`, partagée avec le REST. Le staging ne descend plus à zéro tant qu'un onglet reste ouvert. `max_concurrency` est déprécié au profit de `scaling_option` dans le provider : vérifier avec la version épinglée. Au-delà de quelques dizaines de connexions, un conteneur dédié au temps réel.
- Edge Services ne sert que le front : rien à régler côté API (NestJS pose déjà `X-Accel-Buffering: no` sur les flux SSE).

## Comptes et secrets (checklist du projet)

Aucun compte ni secret (Redis managé seulement au-delà de `LISTEN` / `NOTIFY`). À reporter dans l'issue « Mise en route » :

- [ ] Délai maximal de requête du conteneur de l'API relevé dans OpenTofu, et plan relu.

## Données personnelles (GLB-013)

- Aucune donnée nouvelle si le message ne fait que signaler ; ne rien journaliser du contenu des messages (BE-007).
- Messagerie : les messages sont des données personnelles du module qui les stocke, avec leur `UserDataContributor`.

## Pièges

- **Connexion WebSocket non authentifiée** : guards globaux qui ne voient que les messages, `@Public()` sans contrôle dans `handleConnection`.
- **Origine non vérifiée** à l'ouverture d'un WebSocket (détournement de connexion entre sites).
- **Session révoquée** qui garde sa connexion ouverte pendant des heures ; contrôle périodique qui prolonge la session.
- **Événement diffusé à tous** au lieu des seuls ayants droit.
- **Jeton dans l'URL** de connexion.
- **Délai de requête à 60 s** : connexions coupées chaque minute.
- **Pas de resynchronisation** après une coupure (SSE comme WebSocket) : l'écran affiche un état faux.
- **Connexion `LISTEN` tombée en silence** : plus aucun événement, sans erreur.
- **Tests instables** : attendre un événement précis avec un délai maximal, jamais une pause fixe.

## Tests à écrire

Niveau e2e : API réelle et PostgreSQL en Testcontainers (BE-008). `app.inject()` ne sait pas tenir un flux : lancer l'app sur un port libre (`app.listen(0)`) et utiliser un vrai client SSE ou WebSocket.

- Un client reçoit l'événement de sa ressource, pas celui d'un autre utilisateur ; connexion sans session → 401 (SSE) ou fermée (WebSocket) ; WebSocket avec une `Origin` inconnue → refusé ; sans `Origin` et sans `Bearer` → refusé.
- CORS avec credentials sur `/v1/events` depuis l'origine du web.
- Session révoquée ou compte banni → connexion fermée au contrôle suivant (intervalle réduit en test).
- `NOTIFY` dans une transaction annulée → aucun événement.
- Deux instances de l'app de test sur la même base : un événement publié sur l'une arrive au client connecté à l'autre.
- Message WebSocket invalide ou trop gros → rejeté sans fermer le serveur ; connexions au-delà du plafond → refusées.
- Arrêt de l'app avec des flux ouverts → `app.close()` se termine.
- Web : à un événement reçu, la bonne requête est invalidée (MSW et un faux `EventSource`) ; resynchronisation après reconnexion ; `EventSource` fermé à la déconnexion.
- Mobile : connexion fermée au passage en arrière-plan, rouverte au retour avec resynchronisation.
- À la main en staging (`A-VERIFIER.md`) : connexion à travers le domaine personnalisé, qui tient plus de 60 s ; coupure au délai maximal, puis reconnexion.
