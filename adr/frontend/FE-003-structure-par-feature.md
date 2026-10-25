# FE-003 : Organisation du code par feature

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : frontend
- **Auteurs** : Mo, Claude

## Contexte

Le rangement par type (`components/`, `hooks/`, `services/`) éparpille une même fonctionnalité dans tout le projet. Modifier « la facturation » oblige à toucher cinq dossiers, et les dépendances entre fonctionnalités deviennent invisibles.

## Décision

```
src/
├── app/                 # bootstrap : providers, router, layout racine
├── features/
│   └── invoices/
│       ├── api/         # appels API + hooks TanStack Query
│       ├── components/  # composants propres à la feature
│       ├── hooks/
│       ├── schemas/     # schémas Zod
│       ├── routes/      # pages / écrans de la feature
│       ├── utils/
│       └── index.ts     # API publique de la feature
├── components/ui/       # composants génériques (design system)
├── lib/                 # clients configurés : http, query client, i18n
├── hooks/               # hooks génériques sans métier
└── utils/               # fonctions pures génériques
```

**Règles**
- Une feature N'importe PAS les fichiers internes d'une autre feature. Elle passe par son `index.ts`.
- Les dépendances vont dans un seul sens : `app` → `features` → `components/ui`, `lib`, `hooks`, `utils`. Les dossiers partagés n'importent jamais une feature.
- Un composant n'est déplacé dans `components/ui` que lorsqu'il est utilisé par **au moins deux features** et ne contient pas de logique métier.
- Pas de sous-dossier vide « au cas où » : on crée `hooks/` le jour où il y a un hook.
- Les tests sont à côté du fichier testé : `InvoiceTable.tsx` + `InvoiceTable.test.tsx`.

## Alternatives envisagées

- **Rangement par type** : simple au début, ingérable au-delà de quelques écrans.
- **Feature-Sliced Design complet** : très cadré, mais vocabulaire et couches (entities, widgets, processes) lourds pour nos tailles de projet.

## Conséquences

- ✅ Une feature se comprend, se modifie et se supprime en un seul endroit.
- ✅ Les frontières sont vérifiables automatiquement.
- ⚠️ Arbitrages réguliers sur ce qui est « partagé ».

## Mise en application

- `eslint-plugin-boundaries` ou règle `no-restricted-imports` pour interdire les imports internes entre features.
