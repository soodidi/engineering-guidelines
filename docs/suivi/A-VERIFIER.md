# À vérifier à la main

Tout ce qui ne se teste pas automatiquement : sur un vrai appareil, en staging avec de vrais services, ou avant la mise en ligne d'un projet. La liste se remplit au fur et à mesure du chantier ; l'utilisateur la déroule **d'un coup**, au lancement de l'app jetable (tâche D de `PLAN-SUITE.md`).

Règles :

- Chaque tâche qui laisse un point non vérifiable automatiquement l'ajoute ici, dans la bonne section, avec sa source (PR ou ADR).
- Une case cochée qui révèle un problème devient une issue ou une tâche dans `PLAN-SUITE.md` ; noter le lien à côté de la case.
- Document temporaire, comme le reste de `docs/suivi/` : ce qui doit rester (procédure de recette, par exemple) part dans la checklist « nouveau projet » à la fin du chantier.

## 1. Sur un vrai appareil

| ✓ | Quoi | Attendu | Source |
|---|------|---------|--------|
| [ ] | iPhone : ouvrir le web, toucher un champ (connexion, inscription, notes, « Mon compte ») | Pas de zoom automatique à la saisie | FE-008, boilerplates #31 |
| [ ] | iOS : parcours connexion, inscription, mot de passe oublié avec **VoiceOver** | Tout est annoncé et atteignable, l'ordre de lecture est logique | B1, boilerplates #23 |
| [ ] | iOS : mêmes écrans en **grande police** (taille de texte maximale) | Rien de tronqué ni de superposé | B1 |
| [ ] | Android : mêmes parcours avec **TalkBack** et en grande police | Idem | B1, boilerplates #18, #19 |
| [ ] | Web, page « Mon compte » : au **clavier** seul puis au **lecteur d'écran** | Export et suppression utilisables sans souris, erreurs annoncées | GLB-013, boilerplates #32 |
| [ ] | Web en **mode sombre** : pages légales, « Mon compte » (bouton de suppression) | Contrastes lisibles, bordure rouge visible | FE-005, boilerplates #27, #32 |
| [ ] | Android : `./gradlew connectedDebugAndroidTest` sur émulateur ou appareil (jamais lancé : ni émulateur sur le poste, ni job en CI) | Tous les tests UI passent, dont `AccountScreenTest`, `NoteDetailScreenTest` et `NotesScreenTest` | boilerplates #33, #37 |
| [ ] | Android, détail d'une note : TalkBack, grande police, puis mode avion | « Connexion impossible » annoncé, « Réessayer » recharge la note ; titre lu comme un en-tête | BE-010, boilerplates #37 |
| [ ] | Android, build release (R8) installé : ouvrir une note, pivoter, puis « Ne pas conserver les activités » | Aucun plantage (« Serializer for class … not found ») ; la note se recharge | boilerplates #37 |
| [ ] | Android, « Mon compte » avec **TalkBack** et en **grande police** | Case annoncée comme case à cocher, erreurs lues, rien de tronqué ; barre des notes lisible | GLB-013, boilerplates #33 |
| [ ] | Android, « Mon compte » : liens « Politique de confidentialité » et « Exporter depuis le site web » (en debug : `adb reverse tcp:5173 tcp:5173`) | La page web s'ouvre dans le navigateur | boilerplates #33 |
| [ ] | iOS, « Mon compte » avec **VoiceOver** et la plus grande police, sur iPhone SE | Interrupteur annoncé, erreurs lues ; le message « compte supprimé » est lu une fois à la connexion, sans être coupé | GLB-013, boilerplates #34 |
| [ ] | iOS : pendant la suppression, échappement VoiceOver (Z à deux doigts) et ⌘[ sur iPad | On ne revient pas aux notes | boilerplates #34 |
| [ ] | iOS : liens « Politique de confidentialité » et « Exporter depuis le site web » | Safari s'ouvre sur la bonne page ; l'écran est intact au retour | boilerplates #34 |
| [ ] | Web, page « Administration » : au clavier, au lecteur d'écran, en mode sombre | Confirmation atteinte au clavier, focus rendu après « Confirmer » / « Annuler », « Modification enregistrée. » annoncé | BE-010, boilerplates #36 |
| [ ] | Web sur Safari (macOS ou iOS) : « Télécharger mes données » | Le fichier `export-AAAA-MM-JJ.json` est bien téléchargé | boilerplates #32 |

## 2. En staging : infra et déploiement

| ✓ | Quoi | Attendu | Source |
|---|------|---------|--------|
| [ ] | **Chaîne `X-Forwarded-For`** (prioritaire) : se connecter, puis regarder `sessions.ip_address` | La vraie IP du client, pas celle d'un proxy ; sinon ajuster `TRUST_PROXY_HOPS` | BE-006, boilerplates #14 |
| [ ] | `tofu apply` de staging (lancé par l'utilisateur) | Pas d'erreur ; noter si le `dns_stage` d'Edge Services exige le CNAME avant l'apply | OPS-003, boilerplates #17 |
| [ ] | DNS : CNAME du front et de l'API | Les deux domaines répondent en HTTPS | OPS-005 |
| [ ] | Cookie de session entre `app.` et `api.` (même site) | Connexion web qui tient après rechargement | BE-006 |
| [ ] | Droits réels de l'utilisateur PostgreSQL `app` | Les migrations passent au démarrage ; pas de droit superflu | BE-003, boilerplates #17 |
| [ ] | Migrations au démarrage sous verrou : déployer deux fois de suite | Une seule instance migre ; pas d'erreur dans les logs | OPS-004 |
| [ ] | Commande et champs de la CLI `scw` dans le workflow de déploiement | Le déploiement passe sans retouche | boilerplates #17 |
| [ ] | Bucket policy du front et clé `deploy-web` | Le déploiement du web écrit dans le bucket | boilerplates #17 |
| [ ] | Accès direct à une route du front : `curl -sI https://<web>/legal/privacy`, `/account`, `/admin` et `/notes/<uuid>` | `text/html` ; noter le statut (404 aujourd'hui) et le `cache-control`. Ces URL sont aussi les liens des apps et de la fiche Play : un 404 pourrait être refusé par Google | devops, boilerplates #27, #32, #33 |
| [ ] | Onglet resté ouvert pendant un déploiement, puis ouvrir « Mon compte » ou les pages légales | Noter si la page plante (anciens fichiers JS supprimés) ; sinon garder une version de plus | devops, boilerplates #32 |
| [ ] | Quotas Scaleway TEM | Les e-mails partent ; noter la limite d'envoi | BE-009 |

## 3. En staging : parcours de l'app

| ✓ | Quoi | Attendu | Source |
|---|------|---------|--------|
| [ ] | Inscription, e-mail de confirmation reçu, clic, connexion | Le lien mène sur l'app connectée | BE-006, BE-009 |
| [ ] | Mot de passe oublié | E-mail reçu, lien valable une heure, nouveau mot de passe accepté | BE-006 |
| [ ] | Erreur volontaire (web et API) | Elle remonte dans Sentry avec une stack trace lisible (source maps) | FE-009, BE-007 |
| [ ] | « Mon compte » : exporter mes données | Le fichier contient le compte, les sessions et les notes, sans token ni hachage | GLB-013, boilerplates #24, #32 |
| [ ] | Supprimer mon compte avec un **mauvais** mot de passe, 6 fois de suite | « Mot de passe incorrect. », puis « Trop de tentatives » au 6ᵉ essai | GLB-013, boilerplates #24 |
| [ ] | Supprimer mon compte avec le bon mot de passe | Retour à l'accueil avec le message ; la reconnexion échoue ; plus aucune ligne en base pour ce compte | GLB-013 |
| [ ] | App iOS : supprimer le compte avec un mauvais puis le bon mot de passe ; verrouiller l'iPhone pendant l'envoi | Comme Android ; noter ce qui se passe si la réponse se perd (erreur réseau, puis retour à la connexion sans message) | GLB-013, boilerplates #34 |
| [ ] | App Android : supprimer le compte avec un mauvais puis le bon mot de passe | « Mot de passe incorrect. », puis retour à la connexion avec « Votre compte et vos données ont été supprimés. » ; la reconnexion échoue | GLB-013, boilerplates #33 |
| [ ] | Premier administrateur : inscription confirmée, puis `user:promote` (procédure de staging à décider, voir `HANDOFF.md`) | `GET /v1/admin/stats` répond 200 à l'admin, 403 à un compte ordinaire | BE-010, boilerplates #35 |
| [ ] | Web déployé contre `api.` : sur `/admin`, suspendre, réactiver, changer un rôle | Aucune erreur CORS ni « Invalid origin » ; un compte ordinaire voit « Accès refusé » | BE-010, boilerplates #36 |
| [ ] | App Android contre le staging : note supprimée depuis le web, puis ouverte ; session révoquée pendant l'ouverture d'une note | « Note introuvable » ; retour à la connexion sans écran d'erreur | BE-010, boilerplates #37 |
| [ ] | Bannir un compte depuis l'admin, puis tenter de se connecter avec ce compte | Session coupée tout de suite ; connexion refusée (`BANNED_USER`) | BE-010, boilerplates #35 |
| [ ] | Le web sur un téléphone (Android et iPhone) : toutes les pages | Aucun défilement horizontal, boutons faciles à toucher | FE-008, boilerplates #31 |

## 4. En staging : données personnelles et observabilité

| ✓ | Quoi | Attendu | Source |
|---|------|---------|--------|
| [ ] | Une ligne de log d'API dans Cockpit | `req` = id, méthode, URL (token masqué) ; `res` = statut ; ni IP ni navigateur | GLB-013, boilerplates #25 |
| [ ] | Un événement Sentry de l'API (erreur et trace) | Ni user-agent, ni IP, ni en-têtes hors `content-type`/`content-length`, ni token | GLB-013, boilerplates #25 |
| [ ] | Logs au démarrage de l'API | La ligne « Expired auth data purged » apparaît | GLB-013, boilerplates #25 |
| [ ] | Rétention des logs Cockpit (console Scaleway) | Noter la valeur ; la reporter dans `legal-info.ts` (`logRetentionDays`), puis la fixer dans l'infra par un ADR (OPS-007) | boilerplates #27 |
| [ ] | Rétention des événements Sentry (selon l'offre) | Noter la valeur ; la reporter dans `legal-info.ts` (`errorRetentionDays`) | boilerplates #27 |
| [ ] | Région de l'organisation Sentry | UE ; sinon corriger la politique de confidentialité | GLB-013 |

## 5. Avant la mise en ligne d'un vrai projet

| ✓ | Quoi | Attendu | Source |
|---|------|---------|--------|
| [ ] | `web/src/features/legal/legal-info.ts` | Plus aucun champ entre crochets ; date au format AAAA-MM-JJ | GLB-013, checklist « nouveau projet » |
| [ ] | Textes de `web/src/features/legal/content/` relus | Données, sous-traitants et durées conformes à ce que l'app fait vraiment | GLB-013 |
| [ ] | Production : `min_scale >= 1` pour l'API | La purge quotidienne tourne | boilerplates #25 |
| [ ] | Play Console (fiche et Data safety) | URL de la politique de confidentialité et URL de suppression du compte (`<web_origin>/account`) renseignées | GLB-013, boilerplates #33 |
| [ ] | `res/values/legal.xml` (Android) et `App/LegalInfo.swift` (iOS) | Même durée des sauvegardes que `legal-info.ts` et l'infra de production | boilerplates #33, #34 |
| [ ] | App Store Connect | URL de la politique de confidentialité ; notes de revue avec le chemin de la suppression et un compte de démonstration dédié ; App Privacy (e-mail, nom, notes, liés à l'utilisateur, sans suivi) | GLB-013, boilerplates #34 |
| [ ] | Checklist « nouveau projet » | Toutes les cases des briques utilisées sont cochées | `docs/checklist-nouveau-projet.md` |
