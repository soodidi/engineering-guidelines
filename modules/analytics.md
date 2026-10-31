# Module : mesure d'audience

- **Statut** : Proposé
- **ADR impactés** : GLB-013, OPS-001, OPS-004, FE-008, FE-009, AND-004, IOS-004

## Quand l'utiliser

On veut savoir quelles pages sont vues, d'où viennent les visiteurs et si un parcours aboutit (inscription, achat). **Pas par défaut** : tant qu'il n'y a pas de question précise à laquelle répondre, ne rien mesurer. GLB-013 impose un ADR pour tout traceur.

S'en passer pour les chiffres que l'API connaît déjà (comptes créés, notes, abonnements) : une requête SQL ou une route d'administration suffit, sans sous-traitant.

## Recommandation

**Plausible** (offre hébergée), sur le web.

Pourquoi :

- **sans cookie** ni identifiant persistant : un visiteur est compté par un hachage de l'IP, du navigateur et d'un sel renouvelé chaque jour ; Plausible conserve le hachage, jamais l'IP ni le sel ;
- société et hébergement dans l'UE, code ouvert ;
- script léger (environ 1 Ko), sans effet notable sur les performances (FE-008) ;
- tableau de bord simple, événements personnalisés et objectifs suffisants pour ces apps.

**Consentement** : en France, un outil peut se passer de consentement s'il remplit les conditions de l'exemption de la CNIL : mesure d'audience pour le seul compte de l'éditeur, données anonymes et agrégées, pas de suivi entre sites, **moyen de s'y opposer**… D'après nos recherches de 2026, la CNIL ne publie plus de liste d'outils exemptés (à confirmer sur [sa page consacrée à la mesure d'audience](https://www.cnil.fr/fr/solutions-pour-la-mesure-daudience) au premier usage) ; sa grille d'auto-évaluation s'adresse d'abord aux fournisseurs. Au premier usage : demander à Plausible son auto-évaluation, vérifier **notre configuration** contre les conditions, garder le résultat dans le repo du projet, et ne pas ajouter de bandeau tant qu'elle tient.

## Alternatives

- **Umami** : code ouvert, sans cookie, sur PostgreSQL ; offre hébergée ou **auto-hébergement** sur Scaleway, sans sous-traitant (voir Infra : plus de travail qu'il n'y paraît). À préférer si on refuse tout sous-traitant pour la mesure.
- **Pirsch** : société et hébergement en Allemagne, sans cookie, intégration possible côté serveur (aucun script chez le visiteur).
- **PostHog** (région UE) : analyse produit (entonnoirs, rétention, rejeu de sessions, feature flags). Beaucoup plus riche, mais il suit l'utilisateur : **consentement obligatoire**, donc bandeau. Seulement si l'analyse produit est le besoin.
- **Plausible auto-hébergé** : il demande ClickHouse, trop lourd pour l'infra serverless de ces apps.
- **Matomo** : écarté (choix de l'utilisateur, 2026-10-31) : interface et auto-hébergement (PHP, MySQL) lourds, hors de notre stack.

## Intégration par brique

**API**

- Rien.

**Web**

- Domaine mesuré dans la **configuration d'exécution** : champ `analyticsDomain` de `/config.json` (`configSchema` dans `src/lib/config.ts`), écrit par `deploy-environment.yml` depuis une variable d'Environment GitHub. Le web est construit une fois pour tous les environnements (OPS-004) : une variable `VITE_*` ne peut pas différer entre staging et production. Champ vide → aucun script chargé (dev, tests, staging).
- **Pages vues en mode manuel** : l'app envoie elle-même chaque page vue, avec le **motif de la route** TanStack Router (`/notes/$id`), jamais l'URL réelle ni la chaîne de requête. Sinon, Plausible reçoit les identifiants et les jetons (`/reset-password?token=…`, vérification d'e-mail).
- **Routes jamais mesurées** : authentification (connexion, inscription, mot de passe, vérification d'e-mail), `/account`, `/admin`.
- Événements personnalisés derrière une fonction `track()` de `src/lib/`, sans donnée personnelle dans les propriétés.
- **Opposition** : un interrupteur « Ne pas mesurer ma visite » sur la page de politique de confidentialité, qui pose le marqueur d'exclusion de Plausible dans le navigateur (`localStorage`).
- Si une politique de sécurité du contenu (CSP) est en place : domaine du script dans `script-src` et `connect-src`.
- Optionnel : servir le script et l'envoi depuis le domaine de l'app (proxy), pour éviter les bloqueurs.

**Android / iOS**

- Pas de SDK par défaut. Si le besoin existe : API d'événements de Plausible (ou d'Umami) depuis l'app, sans identifiant d'appareil, avec les mêmes motifs de route ; le déclarer dans les fiches des stores (« Données d'utilisation » dans Data safety, App Privacy).

**Infra**

- Rien pour Plausible, à part la variable d'Environment GitHub du domaine mesuré.
- Umami auto-hébergé, si retenu :
  - base et utilisateur **dédiés sur l'instance PostgreSQL existante** (une seconde instance managée coûterait autant que celle de l'app) ;
  - image recopiée dans le registre du projet (OPS-001), domaine dédié ;
  - `APP_SECRET` et `DATABASE_URL` en `secret_environment_variables` ;
  - le module `app-service` code ses sondes sur `/health/live` et `/health/ready`, alors qu'Umami répond sur `/api/heartbeat` : rendre les chemins configurables ;
  - changer le compte d'administration par défaut au premier démarrage.

## Comptes et secrets (checklist du projet)

À reporter dans l'issue « Mise en route » du projet :

- [ ] Compte Plausible, site déclaré avec le domaine de production ; variable d'Environment GitHub `production` pour `analyticsDomain`, vide en staging.
- [ ] Vérification de l'exemption de la CNIL faite et rangée dans le repo du projet.
- [ ] Section Légal : outil, finalité, absence de cookie, durée de conservation, moyen de s'opposer, Plausible dans les sous-traitants.

## Données personnelles (GLB-013)

- Rien n'est relié au compte : l'export et l'effacement ne changent pas.
- Plausible est un sous-traitant : l'ajouter à la liste de la politique de confidentialité.
- L'adresse IP transite par Plausible pour le comptage : la mentionner, même si elle n'est pas conservée.

## Pièges

- **URL réelles envoyées** : identifiants et jetons partent chez le sous-traitant ; seul le motif de route sort.
- **Mesure en dev ou en staging** : fausse les chiffres ; `analyticsDomain` vide hors production.
- **Événement avec un e-mail ou un id utilisateur** en propriété : interdit.
- **Pas de moyen d'opposition** : l'exemption de la CNIL tombe.
- **Bandeau ajouté « au cas où »** : inutile si l'exemption tient, et il dégrade l'expérience ; à l'inverse, un outil qui suit l'utilisateur sans bandeau est en infraction.

## Tests à écrire

- Unitaire : `track()` et l'envoi des pages vues ne font rien si `analyticsDomain` est vide ; la page vue envoyée est le motif de route (`/notes/$id`), sans chaîne de requête.
- E2E, avec un `config.json` qui active la mesure (requêtes interceptées) : une navigation déclenche une page vue ; aucune requête de mesure sur les routes d'authentification, `/account` et `/admin` ; après « Ne pas mesurer ma visite », plus aucune requête.
- Revue : aucune propriété d'événement ne contient de donnée personnelle (agent `security`).
- En production, à la main (`A-VERIFIER.md`), après le premier déploiement : une page vue arrive dans Plausible, avec le motif de route ; le staging n'envoie rien.
