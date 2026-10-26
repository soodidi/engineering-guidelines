# FE-004 : Gestion de l'état

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : frontend
- **Auteurs** : Mo, Claude

## Contexte

La plupart de l'« état global » d'une app est en réalité une **copie des données serveur**. La stocker dans un store global oblige à recoder cache, invalidation, chargement et erreurs. Il faut distinguer les types d'état et donner à chacun son outil.

## Décision

| Type d'état | Outil | Exemple |
|-------------|-------|---------|
| Données serveur | **TanStack Query** | liste de factures, profil utilisateur |
| État d'URL | Router (params, search params) | filtres, pagination, onglet actif |
| État de formulaire | React Hook Form (FE-006) | champs, erreurs |
| État local d'UI | `useState` / `useReducer` | modale ouverte, champ survolé |
| État client partagé | Context (rarement modifié) ou **Zustand** | thème, panier hors-ligne, préférences |

**Règles**

- Les données serveur NE DOIVENT PAS être copiées dans un store client ou un `useState`.
- Chaque feature expose ses requêtes via des hooks dans `features/x/api/` (`useInvoices()`, `useCreateInvoice()`), avec une **factory de query keys** par feature.
- Les mutations invalident précisément les query keys concernées.
- Un état qui doit survivre à un rechargement ou être partageable par lien DEVRAIT vivre dans l'URL.
- Context est réservé à des valeurs qui changent rarement (sinon re-render de tout l'arbre). Au-delà : Zustand, avec des sélecteurs.
- Pas de `useEffect` pour synchroniser deux états : dériver la valeur pendant le rendu.

## Alternatives envisagées

- **Redux Toolkit (+ RTK Query)** : solide mais plus verbeux ; RTK Query est un bon outil, mais TanStack Query est plus répandu hors Redux.
- **SWR** : plus léger, moins complet sur les mutations et le cache.
- **Jotai** : pertinent pour beaucoup de petits états atomiques interdépendants ; pas notre cas courant.

## Conséquences

- ✅ Cache, retries, états de chargement et refetch gérés sans code maison.
- ✅ Beaucoup moins d'état global.
- ⚠️ Il faut bien concevoir les query keys.

## Mise en application

- `@tanstack/eslint-plugin-query`.
- Revue de code : tout nouveau store global doit être justifié.
