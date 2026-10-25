# Contribuer aux ADR

## Cycle de vie

```
Proposé ──► Accepté ──► Déprécié
               │
               └──► Remplacé par XXX-nnn
```

- **Proposé** : en discussion dans une PR.
- **Accepté** : la règle s'applique.
- **Déprécié** : la règle ne s'applique plus, sans remplaçant.
- **Remplacé par XXX-nnn** : un nouvel ADR prend le relais.

Un ADR accepté **ne se réécrit pas**. On corrige les fautes de frappe, on complète un lien, mais pour changer la décision on crée un nouvel ADR qui remplace l'ancien. L'historique du *pourquoi* reste ainsi lisible.

## Proposer un ADR

1. Copier [`adr/template.md`](adr/template.md) dans le dossier du domaine.
2. Prendre le numéro suivant du domaine : `FE-010-titre-court.md`.
3. Remplir toutes les sections, en particulier *Alternatives* et *Mise en application*.
4. Ajouter une ligne dans le `README.md` du domaine (statut `Proposé`).
5. Ouvrir une PR intitulée `adr(frontend): FE-010 titre court`.
6. Laisser au moins 3 jours ouvrés de commentaires (ou l'accord explicite du référent du domaine pour un sujet mineur).
7. À la fusion, passer le statut à `Accepté` dans l'ADR et dans le README du domaine.

## Référents

| Domaine  | Référent |
|----------|----------|
| Global   | Mo |
| Frontend | Mo |
| Backend  | à définir |
| DevOps   | à définir |
| Android  | à définir |
| iOS      | à définir |

## Quand écrire un ADR ?

Écrire un ADR quand la décision :
- est coûteuse à défaire (choix de framework, de base de données, d'architecture) ;
- concerne plusieurs personnes ou plusieurs repos ;
- a déjà été rediscutée deux fois en revue de code.

Pas besoin d'ADR pour une préférence de style que le linter tranche déjà.

## Règle d'or

Une règle sans **mise en application** (lint, check CI, template, test) finira oubliée. Si une règle ne peut être vérifiée qu'en revue humaine, l'ADR doit le dire.
