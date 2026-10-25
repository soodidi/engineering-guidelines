# FE-006 : Formulaires et validation

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : frontend
- **Auteurs** : Mo, Claude

## Contexte

Les formulaires concentrent beaucoup de bugs : validations dupliquées entre front et back, messages incohérents, re-renders coûteux, accessibilité négligée.

## Décision

- Formulaires gérés avec **React Hook Form** + **Zod** (`@hookform/resolvers/zod`).
- Un schéma Zod par formulaire, dans `features/x/schemas/`. Le type TypeScript est **dérivé** du schéma (`z.infer`), jamais écrit à la main en double.
- Quand le backend publie un contrat OpenAPI (BE-004), les schémas de requête/réponse DEVRAIENT être générés depuis ce contrat, puis complétés côté front si besoin (messages, règles d'UX).
- La validation front sert à l'**expérience utilisateur**. Le backend revalide toujours (BE-005).
- Les erreurs renvoyées par l'API (format Problem Details, BE-004) DOIVENT être mappées sur les champs concernés via `setError`.
- Validation au `blur` puis au `change` après la première erreur (mode `onTouched`).

**Accessibilité des formulaires**
- Chaque champ a un `<label>` associé.
- Les erreurs sont liées au champ (`aria-describedby`) et le champ porte `aria-invalid`.
- À la soumission en erreur, le focus va sur le premier champ invalide.
- Le bouton de soumission est désactivé et indique le chargement pendant l'envoi ; on évite les doubles soumissions.

## Alternatives envisagées

- **Formik** : plus de re-renders, maintenance moins active.
- **TanStack Form** : prometteur, très bien typé ; écosystème plus jeune. À réévaluer.
- **Formulaires non contrôlés sans librairie** : viable pour 1-2 champs, ingérable au-delà.

## Conséquences

- ✅ Une seule source de vérité par formulaire (le schéma).
- ✅ Formulaires performants et accessibles par défaut.
- ⚠️ Discipline nécessaire pour la génération depuis OpenAPI.

## Mise en application

- Composants de champ partagés dans `components/ui/form` qui appliquent label, erreur et attributs ARIA automatiquement.
- Revue de code.
