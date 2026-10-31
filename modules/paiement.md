# Module : paiement

- **Statut** : Proposé
- **ADR impactés** : BE-002, BE-004, BE-005, BE-006, BE-007, BE-008, GLB-005, GLB-013, OPS-006, AND-004, IOS-004

## Quand l'utiliser

L'app vend un **produit numérique** : abonnement, achat unique, crédits. Hors de cette fiche, avec un ADR dédié : marketplace (argent reversé à des tiers, Stripe Connect), biens physiques ou services en personne.

## Recommandation

**Web : Stripe Managed Payments**, avec **Checkout** (page de paiement hébergée par Stripe) et **Billing** pour les abonnements, plus le **Customer Portal** (moyen de paiement, résiliation, factures).

Pourquoi :

- avec Managed Payments, **Stripe est le marchand officiel** : il collecte et déclare les taxes des pays des acheteurs (TVA comprise, plus de 80 pays), gère la fraude, les litiges et le support des transactions. Sans lui, une vente B2C dans l'UE impose de déclarer la TVA de chaque pays (guichet OSS), ce qui pèse lourd pour un développeur seul ;
- Checkout hébergé : aucune donnée de carte ne touche l'app (PCI DSS au plus bas niveau) ;
- outillage le plus complet (mode test, CLI, horloges de test pour les abonnements), et une sortie facile vers Stripe Payments si le projet grandit.

Coût : plus cher que Stripe Payments seul (commission de marchand officiel en plus). Vérifier le tarif et l'éligibilité du produit et du pays sur la doc Stripe au premier usage.

**Mobile : achat intégré des stores.** Un contenu numérique utilisé dans l'app doit être vendu par **StoreKit 2** (iOS, règle 3.1.1 d'Apple) et **Google Play Billing** (Android). Les exceptions (lien vers le web aux États-Unis, offres alternatives dans l'UE avec le DMA) dépendent du pays et leurs conditions, commission comprise, changent souvent : les vérifier au premier usage. Côté serveur, **RevenueCat** valide les achats des deux stores, reçoit leurs notifications et unifie les droits avec Stripe : c'est la pratique courante, et cela évite d'écrire trois validations. Le faire soi-même (App Store Server API et notifications V2, Google Play Developer API et notifications en temps réel) seulement si on refuse un sous-traitant de plus.

## Alternatives

- **Stripe Payments + Stripe Tax** : moins cher, toutes les intégrations (Payment Element, factures). Mais l'app est le marchand : déclarations de TVA, litiges et factures à sa charge. À choisir pour un produit non éligible à Managed Payments, ou quand les volumes justifient de gérer la TVA.
- **Paddle** : marchand officiel éprouvé, moins souple que Stripe pour l'intégration.
- **Mollie** : prestataire européen, mais pas marchand officiel : même charge fiscale que Stripe Payments.
- **Plugin Stripe de Better Auth** (`@better-auth/stripe`) : crée le client Stripe à l'inscription et gère les abonnements ; à évaluer au premier usage (compatibilité avec Managed Payments, contrôle des webhooks).

## Intégration par brique

**API** (module `billing`)

- Tables : `billing_customers` (`user_id`, `stripe_customer_id`), `entitlements` (`user_id`, `product`, `source` : `stripe`, `app_store`, `play`, `status`, `current_period_end`), `billing_events` (`id` de l'événement, clé unique). `entitlements` est la **seule source de vérité** des droits : les clients ne décident jamais seuls.
- `POST /v1/billing/checkout` : crée une Checkout Session. Prix lu côté serveur (jamais envoyé par le client), client Stripe du compte, `client_reference_id` = id de l'utilisateur, `success_url` et `cancel_url` construites par le serveur depuis l'origine du web (pas de redirection ouverte). Abonnement déjà actif → **409**. En-tête `Idempotency-Key` accepté (BE-004) et clé d'idempotence passée à Stripe.
- `POST /v1/billing/portal` : session du Customer Portal pour l'utilisateur connecté, `return_url` fixée par le serveur.
- `POST /v1/billing/webhooks/stripe` : `@Public()` et `@SkipThrottle()`. Aucune exemption CSRF à écrire : `CsrfGuard` laisse passer une requête sans cookie. **Signature vérifiée sur le corps brut** : l'app est créée avec `bodyParser: false` et c'est `BetterAuthModule` qui installe les parseurs, donc `bodyParser: { rawBody: true }` dans son `useFactory` (`auth.module.ts`) ; `rawBody: true` dans `NestFactory.create` n'a aucun effet. Tolérance d'horodatage par défaut (300 s) contre le rejeu.
- Traitement d'un événement : **dans une même transaction**, enregistrer son `id` et écrire le droit. En cas d'échec, répondre 5xx pour que Stripe réessaie ; un `id` déjà enregistré → 200 sans rien refaire.
- Les événements arrivent dans le désordre et en double : relire l'objet chez Stripe (abonnement, session, paiement) et écrire son état actuel, plutôt que d'appliquer le contenu de l'événement.
- **Quel état ouvre le droit** :

  | Événement ou état | Droit |
  |---|---|
  | `checkout.session.completed` avec `payment_status = paid` (achat unique) | ouvert |
  | `checkout.session.async_payment_succeeded` | ouvert |
  | `checkout.session.completed` avec `payment_status = unpaid` (paiement différé) | rien, attendre |
  | abonnement `active` ou `trialing` | ouvert jusqu'à `current_period_end` |
  | abonnement `incomplete` | rien |
  | abonnement `past_due` | délai de grâce à fixer au premier usage, puis fermé |
  | abonnement `canceled`, `unpaid`, `incomplete_expired` | fermé |
  | `charge.refunded` (achat unique), `charge.dispute.created` | fermé (un remboursement ne change pas l'état d'un abonnement : le traiter à part) |

- Les routes payantes vérifient le droit **et** `current_period_end` : un webhook manqué ne laisse pas un droit ouvert indéfiniment. Resynchronisation quotidienne avec Stripe, alerte Sentry quand un webhook échoue.
- Crédits : décrément atomique (`UPDATE … SET balance = balance - n WHERE balance >= n`), jamais lire puis écrire.
- Ne jamais journaliser le corps d'un webhook (données personnelles, BE-007).
- Mobile avec RevenueCat : webhook `@Public()` dont l'en-tête `Authorization` est comparé **en temps constant** au secret ; l'événement sert de signal, l'API relit l'abonné par l'API REST de RevenueCat, puis écrit `entitlements` ; dédoublonnage par `id` d'événement. Comportement de restauration des achats (transfert entre comptes) fixé explicitement dans RevenueCat.
- Variables dans `env.ts` et `.env.example` : `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` (et `REVENUECAT_*` si retenu). En local, `stripe listen --forward-to localhost:3000/v1/billing/webhooks/stripe` donne un secret de webhook propre au poste.

**Web**

- Bouton « S'abonner » → `POST /v1/billing/checkout` → redirection vers Stripe.
- Page de retour : **attendre le droit côté API** (requête répétée quelques secondes), ne jamais débloquer sur le seul retour de Checkout.
- « Gérer mon abonnement » dans « Mon compte » → Customer Portal.

**Android / iOS**

- Play Billing Library ou StoreKit 2 (via le SDK RevenueCat si retenu). Identifiant de l'acheteur = id de l'utilisateur de l'API (un UUID, comme l'exige l'`appAccountToken` de StoreKit).
- Après un achat, l'app redemande ses droits à l'API ; bouton « Restaurer les achats » (exigé par Apple).
- Avant la suppression du compte, prévenir l'utilisateur qu'un abonnement des stores se résilie dans les réglages du store : l'app ne peut pas le faire.

**Infra**

- Secrets saisis à la main : recette « Secrets saisis à la main » du [README du catalogue](README.md#secrets-saisis-à-la-main). L'URL du webhook est l'API publique de chaque environnement.

## Comptes et secrets (checklist du projet)

À reporter dans l'issue « Mise en route » du projet :

- [ ] Compte Stripe (entreprise vérifiée), Managed Payments activé, produits et prix créés en mode test puis en production.
- [ ] `STRIPE_SECRET_KEY` : clé **restreinte** aux ressources utilisées, en mode test pour le staging et en mode live pour la production ; saisie dans Secret Manager (une par environnement) et rangée dans le gestionnaire de mots de passe.
- [ ] Endpoint de webhook déclaré dans Stripe pour chaque environnement, avec les seuls événements traités ; son `STRIPE_WEBHOOK_SECRET` saisi dans Secret Manager.
- [ ] Section Mobile : produits créés dans App Store Connect et Play Console ; contrat « Paid Apps » signé chez Apple ; compte RevenueCat et son secret de webhook dans Secret Manager si retenu.
- [ ] Section Légal : prix TTC, conditions de vente, droit de rétractation (renonciation expresse pour un contenu numérique fourni immédiatement), sous-traitants ajoutés.

## Données personnelles (GLB-013)

- Stripe (et RevenueCat, Apple, Google) deviennent des sous-traitants ou des responsables de traitement : les lister dans la politique de confidentialité.
- L'app ne stocke ni numéro de carte ni adresse de facturation : seulement l'id client Stripe et les droits.
- **Effacement du compte** : dans `erase(userId, tx)` du module, supprimer d'abord le client chez Stripe (`customers.del`, qui résilie ses abonnements ; à confirmer avec Managed Payments au premier usage), puis les lignes. Si Stripe ne répond pas, `erase` échoue et le compte reste : l'utilisateur réessaie. Les **pièces comptables** (factures) se gardent 10 ans (Code de commerce) : chez Stripe, marchand officiel, pas dans la base de l'app. Le dire dans la politique.
- Export : droits et historique d'abonnement de l'utilisateur.

## Pièges

- **Corps brut** mal branché : la signature échoue toujours (voir l'API).
- **Droits débloqués trop tôt** : sur l'URL de retour de Checkout, un paiement différé, un abonnement `incomplete`.
- **Événement marqué traité avant d'être appliqué** : la nouvelle tentative de Stripe est ignorée, un remboursement se perd.
- **Prix ou URL de retour envoyés par le client** : toujours fixés côté serveur.
- **Second abonnement** pour le même produit.
- **Stores** : vendre sur le web un contenu utilisé dans l'app, avec un lien depuis l'app, est refusé hors des exceptions par pays.

## Tests à écrire

Niveau e2e : API réelle et PostgreSQL en Testcontainers (BE-008), client Stripe remplacé par une doublure à la frontière.

- Routes `checkout` et `portal` sans session → 401 ; le portail ouvert est toujours celui du compte de la session.
- Webhook : un événement **correctement signé** envoyé par `app.inject()` → 200 et traité (prouve que le corps brut est bien branché) ; signature absente ou fausse → 400 ; même événement deux fois → un seul traitement ; échec du traitement → 5xx et rien d'enregistré ; webhook sans session et sans en-tête `Origin` → accepté ; pas limité par le rate limiting global.
- Table des états : chaque ligne du tableau ci-dessus ouvre ou ferme le droit comme prévu, y compris `invoice.payment_failed` puis `past_due`, et le remboursement d'un achat unique.
- Droits : route payante refusée (403) sans droit, ouverte avec ; refusée après `current_period_end`.
- Checkout : prix et URL de retour fixés par le serveur ; second abonnement → 409.
- RevenueCat : en-tête faux → 401 ; événement rejoué → un seul traitement ; droit écrit d'après l'abonné relu.
- Crédits : deux décréments simultanés ne passent pas sous zéro.
- Effacement du compte : client supprimé chez Stripe (doublure), lignes effacées ; Stripe indisponible → compte intact.
- En staging, à la main (`A-VERIFIER.md`) : paiement par carte de test, paiement refusé, renouvellement avec une horloge de test, résiliation par le portail.
