# BE-007 : Logs, traces et santé de l'application

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : backend
- **Auteurs** : Mo, Claude

## Contexte

En production, on ne peut pas mettre de point d'arrêt. Il faut pouvoir répondre rapidement à : *que s'est-il passé pour cette requête ? depuis quand ça ralentit ? est-ce que le service est en vie ?*

## Décision

**Logs**
- Logs **structurés en JSON** avec **pino** (intégré à Fastify), sur la sortie standard. Le collecte est faite par la plateforme (OPS-007).
- Chaque log porte : `level`, `time`, `msg`, `requestId` / `traceId`, `userId` si authentifié, module.
- Niveaux : `error` (action humaine nécessaire), `warn` (anormal mais géré), `info` (événements métier notables), `debug` (désactivé en production).
- On NE DOIT PAS logger : mots de passe, tokens, en-têtes `Authorization`/`Cookie`, numéros de carte, données personnelles sensibles. Masquage configuré via `redact`.
- Pas de `console.log` dans le code.

**Traçage**
- Un identifiant de requête est généré (ou repris de l'en-tête `traceparent`) et propagé dans les logs, les appels sortants et les réponses d'erreur (`traceId`, BE-004).
- Instrumentation **OpenTelemetry** (HTTP, PostgreSQL, Redis), export OTLP.

**Métriques**
- Métriques de base : latence et taux d'erreur par route, connexions à la base, taille des files.

**Santé**
- `GET /health/live` : le processus répond (pas de dépendance vérifiée).
- `GET /health/ready` : prêt à recevoir du trafic (base de données joignable, migrations à jour).
- Arrêt propre sur `SIGTERM` : on termine les requêtes en cours et on ferme les connexions (`enableShutdownHooks`).

**Erreurs**
- Les exceptions non gérées sont capturées par un outil de suivi d'erreurs (Sentry ou GlitchTip auto-hébergé), avec le `traceId`.

## Alternatives envisagées

- **Logs texte libres** : impossibles à requêter efficacement.
- **winston** : plus lent que pino, moins bien intégré à Fastify.

## Conséquences

- ✅ Diagnostic rapide en production, corrélation front ↔ back ↔ base.
- ⚠️ Volume de logs à surveiller (coût de stockage).

## Mise en application

- Logger pino configuré dans `common/`, règle ESLint `no-console`.
- Endpoints de santé utilisés par la plateforme (OPS-005).
