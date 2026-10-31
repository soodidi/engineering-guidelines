# Module : paiement

- **Statut** : Proposé
- **ADR impactés** : BE-002, BE-004, BE-005, BE-006, BE-007, GLB-005, GLB-013, OPS-006, AND-004, IOS-004

## Quand l'utiliser

L'app vend un **produit numérique** : abonnement, achat unique, crédits. Hors de cette fiche, avec un ADR dédié : marketplace (argent reversé à des tiers, Stripe Connect), biens physiques ou services en personne.

## Recommandation

**Web : Stripe Managed Payments**, avec **Checkout** (page de paiement hébergée par Stripe) et **Billing** pour les abonnements, plus le **Customer Portal** (moyen de paiement, résiliation, factures).

Pourquoi :

- avec Managed Payments, **Stripe est le marchand officiel** : il collecte et déclare la TVA (et les taxes de plus de 80 pays), gère la fraude, les litiges et le support des transactions. Sans lui, une vente B2C dans l'UE impose de déclarer la TVA de chaque pays (guichet OSS), ce qui pèse lourd pour un développeur seul ;
- Checkout hébergé : aucune donnée de carte ne touche l'app (PCI DSS au plus bas niveau) ;
- outillage le plus complet (mode test, CLI, horloges de test pour les abonnements), et une sortie facile vers Stripe Payments si le projet grandit.

Coût : plus cher que Stripe Payments seul (commission de marchand officiel en plus). Vérifier le tarif, l'éligibilité du produit et du pays sur la doc Stripe au premier usage.

**Mobile : achat intégré des stores.** Un contenu numérique utilisé dans l'app doit être vendu par **StoreKit 2** (iOS, règle 3.1.1 d'Apple) et **Google Play Billing** (Android). Les exceptions (lien vers le web aux États-Unis, offres alternatives dans l'UE avec le DMA) dépendent du pays, évoluent vite et gardent une commission : les vérifier au premier usage. Côté serveur, **RevenueCat** valide les achats des deux stores, reçoit leurs notifications et unifie les droits avec Stripe ; c'est la pratique courante et cela évite d'écrire trois validations. Le faire soi-même (App Store Server API et notifications V2, Google Play Developer API et notifications en temps réel) seulement si on refuse un sous-traitant de plus.

## Alternatives

- **Stripe Payments + Stripe Tax** : moins cher, toutes les intégrations (Payment Element, factures). Mais l'app est le marchand : déclarations de TVA, litiges et factures à sa charge. À choisir pour un produit non éligible à Managed Payments, ou quand les volumes justifient de gérer la TVA.
- **Paddle** : marchand officiel éprouvé, moins souple que Stripe pour l'intégration.
- **Mollie** : prestataire européen, mais pas marchand officiel : même charge fiscale que Stripe Payments.
- **Plugin Stripe de Better Auth** (`@better-auth/stripe`) : crée le client Stripe à l'inscription et gère les abonnements ; à évaluer au premier usage (compatibilité avec Managed Payments, contrôle des webhooks).

## Intégration par brique

**API** (module `billing`)

- `POST /v1/billing/checkout` : crée une Checkout Session (client Stripe rattaché au compte, `client_reference_id` = id de l'utilisateur, prix lu côté serveur, jamais envoyé par le client) et renvoie son URL.
- `POST /v1/billing/portal` : session du Customer Portal pour l'utilisateur connecté.
- `POST /v1/billing/webhooks/stripe` : `@Public()`, **signature vérifiée sur le corps brut** (`rawBody: true` à la création de l'app NestJS), sans CSRF. Chaque événement est enregistré par son `id` (table `billing_events`, clé unique) : un événement rejoué n'est traité qu'une fois.
- Table `entitlements` (`user_id`, `product`, `source` : `stripe`, `app_store`, `play`, `status`, `current_period_end`) : **seule source de vérité** des droits. Les routes payantes la consultent ; les clients ne décident jamais seuls.
- Les événements arrivent dans le désordre et en double : à chaque événement d'abonnement, relire l'abonnement chez Stripe et écrire son état actuel plutôt que d'appliquer le contenu de l'événement.
- Mobile avec RevenueCat : webhook RevenueCat (secret partagé) qui met à jour `entitlements` de la même façon.

**Web**

- Bouton « S'abonner » → `POST /v1/billing/checkout` → redirection vers Stripe.
- Page de retour : **attendre le droit côté API** (requête répétée quelques secondes), ne jamais débloquer sur le seul retour de Checkout.
- « Gérer mon abonnement » dans « Mon compte » → Customer Portal.

**Android / iOS**

- Play Billing Library ou StoreKit 2 (via le SDK RevenueCat si retenu), identifiant de l'utilisateur de l'API transmis comme identifiant d'acheteur.
- Après un achat, l'app redemande ses droits à l'API ; bouton « Restaurer les achats » (exigé par Apple).

**Infra**

- Aucune ressource Scaleway. Secrets dans Secret Manager (OPS-006) ; l'URL du webhook est l'API publique de chaque environnement.

## Comptes et secrets (checklist du projet)

- [ ] Compte Stripe (entreprise vérifiée), Managed Payments activé, produits et prix créés en mode test puis en production.
- [ ] `STRIPE_SECRET_KEY` (clé **restreinte** aux ressources utilisées) et `STRIPE_WEBHOOK_SECRET`, par environnement ; staging en mode test.
- [ ] Endpoint de webhook déclaré dans Stripe pour chaque environnement, avec les seuls événements traités.
- [ ] Mobile : produits créés dans App Store Connect et Play Console ; contrat « Paid Apps » signé chez Apple ; compte RevenueCat et `REVENUECAT_WEBHOOK_SECRET` si retenu.
- [ ] Pages légales : prix TTC, conditions de vente, droit de rétractation (renonciation expresse pour un contenu numérique fourni immédiatement).

## Données personnelles (GLB-013)

- Stripe (et RevenueCat, Apple, Google) deviennent des sous-traitants ou des responsables de traitement : les lister dans la politique de confidentialité.
- L'app ne stocke ni numéro de carte ni adresse de facturation : seulement l'id client Stripe et les droits.
- Effacement du compte : résilier les abonnements actifs, puis effacer `entitlements` et `billing_events`. Les **pièces comptables** (factures) se gardent 10 ans (Code de commerce) : chez Stripe, marchand officiel, et pas dans la base de l'app. Le dire dans la politique.
- Export : droits et historique d'abonnement de l'utilisateur.

## Pièges

- **Corps brut** : un corps déjà parsé par Fastify fait échouer la vérification de signature.
- **Droits débloqués trop tôt** : sur l'URL de retour de Checkout ou sur un événement non vérifié.
- **Prix envoyé par le client** : toujours lire le prix côté serveur.
- **Remboursement, litige, échec de paiement** : ces événements doivent retirer le droit (`charge.refunded`, `invoice.payment_failed`, `customer.subscription.deleted`…).
- **Webhooks bloqués** par le rate limiting ou l'authentification : la route est publique et exemptée, sa signature fait office d'authentification.
- **Stores** : vendre sur le web un contenu utilisé dans l'app, avec un lien depuis l'app, est refusé hors des exceptions par pays.

## Tests à écrire

- Webhook : signature absente ou fausse → 400 ; même événement deux fois → un seul traitement ; événements dans le désordre → état final juste.
- Droits : route payante refusée (403) sans droit, ouverte avec ; droit retiré après remboursement ou résiliation.
- Checkout : prix et client fixés par le serveur ; portail d'un autre utilisateur impossible.
- Effacement du compte : abonnement résilié chez Stripe (doublure du client Stripe en test), lignes effacées.
- Staging, à la main (`A-VERIFIER.md`) : paiement par carte de test, renouvellement avec une horloge de test, résiliation par le portail.
