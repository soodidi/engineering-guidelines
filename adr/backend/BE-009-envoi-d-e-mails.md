# BE-009 : Envoi d'e-mails transactionnels

- **Statut** : Proposé
- **Date** : 2026-10-27
- **Périmètre** : backend
- **Auteurs** : Mo, Claude
- **Liens** : BE-006, BE-007, OPS-004, OPS-006

## Contexte

L'authentification (BE-006) exige la vérification d'e-mail et le mot de passe oublié : sans envoi d'e-mails, elle ne fonctionne pas. Les premières apps serviront surtout à leur auteur, avec un petit volume. Certaines pourront ensuite s'ouvrir au public. Il faut donc un dispositif simple en développement et en staging, et propre en production : délivrabilité, secrets, confidentialité.

## Décision

**Fournisseur**

- La production DOIT utiliser **Scaleway Transactional Email (TEM)**. C'est le même fournisseur que l'hébergement (OPS-005) : pas de sous-traitant RGPD de plus, et la facturation est déjà en place. Le tarif est de 0,25 € pour 1 000 e-mails, avec 300 e-mails gratuits par mois et un quota par défaut de 10 000 par mois, relevable sur demande.
- L'envoi DOIT passer par **SMTP** (`nodemailer`), pas par l'API de Scaleway. Le même code sert alors partout, et changer de fournisseur ne demande que de changer la configuration.

**Module `mail`**

- Le code métier n'utilise que l'interface `Mailer` du module `mail`. Il ne connaît ni SMTP ni le fournisseur.
- Les gabarits sont des fonctions TypeScript qui renvoient un sujet, une version texte et une version HTML. Ils sont rédigés en français, et toute valeur insérée dans le HTML est échappée. Pas de moteur de gabarits.
- L'envoi DOIT se faire **hors de la requête HTTP**. La réponse de l'API ne dépend jamais de la réussite de l'envoi : sinon, on révélerait l'existence d'un compte (BE-006).
- En cas d'échec, l'envoi est retenté 3 fois avec un délai croissant. Un échec définitif est journalisé en erreur et remonte dans Sentry. À l'arrêt de l'application, les envois en cours sont attendus quelques secondes.
- Les logs NE DOIVENT contenir ni l'adresse du destinataire, ni le contenu, ni les liens. Les liens de vérification et de réinitialisation contiennent des tokens. On journalise le nom du gabarit et l'identifiant du message (BE-007).

**Environnements**

| Environnement | Serveur SMTP | Destinataires |
|---|---|---|
| Développement | **Mailpit** (`compose.yaml`), interface web sur `http://localhost:8025` | Tous : rien ne sort du poste |
| Tests | Faux `Mailer` en mémoire ; l'adaptateur SMTP est testé contre Mailpit (Testcontainers) | — |
| Staging | TEM | Seulement les adresses de `MAIL_ALLOWED_RECIPIENTS` ; les autres envois sont ignorés et journalisés |
| Production | TEM, TLS obligatoire | Tous |

**Production**

- Les e-mails partent d'un **sous-domaine dédié** (par exemple `mail.example.com`), pour protéger la réputation du domaine principal.
- Ce domaine DOIT avoir **SPF**, **DKIM** et **DMARC** publiés et vérifiés dans TEM avant le premier envoi. DMARC commence en `p=none`, puis passe en `p=quarantine` une fois les rapports propres.
- Identifiants SMTP : l'utilisateur est l'ID du projet Scaleway, et le mot de passe est la clé secrète d'une clé API limitée à l'envoi TEM. Ils DOIVENT être stockés dans Scaleway Secret Manager (OPS-006).
- La connexion SMTP DOIT être chiffrée (port 587 avec STARTTLS obligatoire, ou port 465).
- L'expéditeur est une adresse `noreply@` ; un `Reply-To` vers une boîte lue PEUT être ajouté.

**Quand faire évoluer**

- Le jour où une app publique envoie des e-mails qu'on ne peut pas perdre (factures, notifications contractuelles), les envois passent par une file persistante en PostgreSQL. Ce changement passe par un ADR.
- Si la délivrabilité de TEM devient insuffisante, on passe à Brevo par un changement de configuration SMTP. Ce changement passe aussi par un ADR, avec une mise à jour de la liste des sous-traitants.

## Alternatives envisagées

- **Brevo** : société française avec une bonne délivrabilité et des outils complets. Mais c'est un sous-traitant de plus, et l'offre gratuite plafonne le volume quotidien. Gardé comme solution de repli.
- **API REST de Scaleway** plutôt que SMTP : elle lie le code au fournisseur, et on ne peut pas tester le même chemin en local avec Mailpit.
- **File persistante dès maintenant** : plus robuste, mais excessive pour des apps personnelles. Un e-mail d'authentification perdu se renvoie d'un clic.

## Conséquences

- ✅ Un seul fournisseur pour l'hébergement et les e-mails, et un seul chemin de code de la machine locale à la production.
- ✅ Aucun e-mail réel en développement ; en staging, seulement vers des adresses autorisées.
- ⚠️ Un envoi en cours peut être perdu si l'instance s'arrête brutalement. C'est accepté tant qu'il ne s'agit que d'e-mails d'authentification.
- ⚠️ Les statistiques de délivrabilité de TEM sont plus simples que celles d'un spécialiste.

## Mise en application

- `npm run arch` : seul le module `mail` importe `nodemailer`.
- Tests unitaires des gabarits (texte, HTML échappé) et de la liste blanche de staging ; test d'intégration de l'adaptateur SMTP contre Mailpit.
- Checklist « nouveau projet » : sous-domaine d'envoi, SPF/DKIM/DMARC, clé API TEM, secrets `SMTP_URL` et `MAIL_FROM`.
- Revue de code : aucune adresse, aucun lien ni aucun contenu d'e-mail dans les logs.
