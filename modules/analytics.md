# Module : mesure d'audience

- **Statut** : Proposé
- **ADR impactés** : GLB-013, FE-008, FE-009, AND-004, IOS-004

## Quand l'utiliser

On veut savoir quelles pages sont vues, d'où viennent les visiteurs et si un parcours aboutit (inscription, achat). **Pas par défaut** : tant qu'il n'y a pas de question précise à laquelle répondre, ne rien mesurer. GLB-013 impose un ADR pour tout traceur.

S'en passer pour les chiffres que l'API connaît déjà (comptes créés, notes, abonnements) : une requête SQL ou une route d'administration suffit, sans sous-traitant.

## Recommandation

**Plausible** (offre hébergée), sur le web.

Pourquoi :

- **sans cookie** ni identifiant persistant : les visiteurs sont comptés avec un hachage de l'IP et du navigateur, renouvelé chaque jour, que Plausible ne stocke pas ;
- société et hébergement dans l'UE, code ouvert ;
- script léger (environ 1 Ko), sans effet notable sur les performances (FE-008) ;
- tableau de bord simple, événements personnalisés et objectifs suffisants pour ces apps.

**Consentement** : un outil peut se passer de consentement en France s'il remplit les conditions de l'exemption de la CNIL (mesure d'audience pour le seul compte de l'éditeur, données anonymes et agrégées, pas de suivi entre sites…). Depuis 2026, la CNIL **ne publie plus de liste** d'outils exemptés : c'est à l'éditeur de vérifier, avec la grille d'auto-évaluation de la CNIL, que l'outil et **sa configuration** remplissent ces conditions. Au premier usage : faire cette vérification, la garder dans le repo du projet, et ne pas ajouter de bandeau tant qu'elle tient.

## Alternatives

- **Umami** : code ouvert, sans cookie. Il tourne sur PostgreSQL, ce qui permet de l'**auto-héberger** sur Scaleway (un Serverless Container et une base) sans sous-traitant ; offre hébergée disponible aussi. À préférer si on refuse tout sous-traitant pour la mesure.
- **Pirsch** : société et hébergement en Allemagne, sans cookie, intégration possible côté serveur (aucun script chez le visiteur).
- **PostHog** (région UE) : analyse produit (entonnoirs, rétention, rejeu de sessions, feature flags). Beaucoup plus riche, mais il suit l'utilisateur : **consentement obligatoire**, donc bandeau. Seulement si l'analyse produit est le besoin.
- **Plausible auto-hébergé** : il demande ClickHouse, trop lourd pour l'infra serverless de ces apps.

## Intégration par brique

**Web**

- Script chargé **en production seulement** (variable `VITE_ANALYTICS_DOMAIN` vide ailleurs), avec `defer`.
- Pages vues : le script suit la navigation de l'historique, donc les changements de route de TanStack Router.
- **URL avec identifiants** : `/notes/<uuid>` doit remonter comme `/notes/:id` (option d'URL personnalisée de Plausible) ; aucun identifiant, e-mail ou jeton dans une URL mesurée.
- Événements personnalisés (`plausible('Signup')`) derrière une petite fonction `track()` de `src/lib/`, sans donnée personnelle dans les propriétés.
- Pages privées (`/account`, `/admin`) : ne pas les mesurer, ou seulement leur chemin.
- Si une politique de sécurité du contenu (CSP) est en place : autoriser le domaine du script dans `script-src` et `connect-src`.
- Optionnel : servir le script et l'envoi depuis le domaine de l'app (proxy), pour éviter les bloqueurs ; c'est un choix, pas une obligation.

**Android / iOS**

- Pas de SDK par défaut. Si le besoin existe : appeler l'API d'événements de Plausible (ou d'Umami) depuis l'app, sans identifiant d'appareil, et le déclarer dans les fiches des stores (« Données d'utilisation » dans Data safety, App Privacy).

**API, infra**

- Rien pour Plausible. Umami auto-hébergé : un conteneur et une base de plus dans OpenTofu, en dehors de la base de l'app.

## Comptes et secrets (checklist du projet)

- [ ] Compte Plausible, site déclaré avec le domaine de production ; pas de site pour le staging (ou un site à part).
- [ ] Vérification de l'exemption de la CNIL faite et rangée dans le repo du projet.
- [ ] Politique de confidentialité : outil, finalité, absence de cookie, durée de conservation, moyen de s'y opposer.

## Données personnelles (GLB-013)

- Rien n'est relié au compte : l'export et l'effacement ne changent pas.
- Plausible est un sous-traitant : l'ajouter à la liste de la politique de confidentialité.
- L'adresse IP transite par Plausible pour le comptage : la mentionner, même si elle n'est pas stockée.

## Pièges

- **Identifiants dans les URL** : ils transforment une mesure anonyme en suivi de ressources.
- **Mesure en dev ou en staging** : fausse les chiffres ; script désactivé hors production.
- **Événement avec un e-mail ou un id utilisateur** en propriété : interdit.
- **Bandeau ajouté « au cas où »** : inutile si l'exemption tient, et il dégrade l'expérience ; à l'inverse, un outil qui suit l'utilisateur sans bandeau est en infraction.

## Tests à écrire

- Unitaire : `track()` ne fait rien hors production ; l'URL envoyée remplace les identifiants (`/notes/:id`).
- E2E : en build de production simulé, une navigation déclenche une page vue (requête interceptée) ; aucune requête de mesure sur `/account` et `/admin`.
- Revue : aucune propriété d'événement ne contient de donnée personnelle (agent `security`).
