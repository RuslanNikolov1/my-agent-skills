# Loading skeleton examples

Patterns from Ruslan's repos, adapted for current conventions.

---

## Example 1 · Module card grid (hairdresser-app / Sanity)

Mirrors `HomePage.module.scss` `.moduleGrid` + `.moduleCard` + `.moduleMedia` (4/5 aspect).

```tsx
// src/components/home-page/ModulesGridSkeleton.tsx
import styles from "./ModulesGridSkeleton.module.scss";

const PLACEHOLDER_COUNT = 3;

export function ModulesGridSkeleton() {
  return (
    <div
      className={styles.grid}
      role="status"
      aria-busy="true"
      aria-label="Зареждане на модулите"
    >
      {Array.from({ length: PLACEHOLDER_COUNT }).map((_, i) => (
        <article key={i} className={styles.card}>
          <div className={styles.media} aria-hidden="true" />
          <div className={styles.body}>
            <div className={styles.audience} aria-hidden="true" />
            <div className={styles.title} aria-hidden="true" />
            <div className={styles.metaRow} aria-hidden="true" />
            <div className={styles.metaRow} aria-hidden="true" />
            <div className={styles.link} aria-hidden="true" />
          </div>
        </article>
      ))}
    </div>
  );
}
```

```scss
// ModulesGridSkeleton.module.scss
@mixin shimmer {
  background: linear-gradient(
    90deg,
    var(--color-paper-3) 25%,
    var(--color-paper-2) 50%,
    var(--color-paper-3) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s ease-in-out infinite;

  @media (prefers-reduced-motion: reduce) {
    animation: none;
    background: var(--color-paper-3);
  }
}

@keyframes shimmer {
  0% { background-position: -200% 0; }
  100% { background-position: 200% 0; }
}

.grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: clamp(1.5rem, 3vw, 2.25rem);

  @media (max-width: 1023px) {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  @media (max-width: 639px) {
    grid-template-columns: 1fr;
  }
}

.card {
  min-width: 0;
  border-top: var(--rule-hair) solid var(--color-rule);
  padding-top: var(--space-md);
}

.media {
  aspect-ratio: 4 / 5;
  border-radius: var(--radius-panel);
  @include shimmer;
}

.body {
  display: grid;
  gap: var(--space-md);
  padding-top: var(--space-md);
}

.audience {
  width: 45%;
  height: 1rem;
  border-radius: 0.25rem;
  @include shimmer;
}

.title {
  width: 85%;
  height: clamp(1.7rem, 2.5vw, 2.25rem);
  border-radius: 0.35rem;
  @include shimmer;
}

.metaRow {
  width: 100%;
  height: 1rem;
  border-radius: 0.25rem;
  @include shimmer;
}

.link {
  width: 40%;
  height: 1rem;
  border-radius: 0.25rem;
  @include shimmer;
}
```

**Wire with Suspense:**

```tsx
<Suspense fallback={<ModulesGridSkeleton />}>
  <ModulesFromSanity />
</Suspense>
```

---

## Example 2 · Module detail route `loading.tsx`

```tsx
// src/app/(site)/modules/[slug]/loading.tsx
import { ModulePageSkeleton } from "@/components/module-page/ModulePageSkeleton";

export default function Loading() {
  return <ModulePageSkeleton />;
}
```

Skeleton sections to include (match `ModulePage.tsx`):

- Hero split layout (image + title/meta)
- Section heading bars × 4–5
- Gallery grid (only if typical module has gallery — use 2-col before/after shape)
- Sign-up form block (label + input rectangles)

---

## Example 3 · Favorites list (real-estate-app pattern)

Direct port of proven pattern — card row with image column + content bars.

```tsx
// FavoritesPageSkeleton.tsx
import styles from "./FavoritesPageSkeleton.module.scss";

export function FavoritesPageSkeleton() {
  return (
    <div
      className={styles.skeleton}
      role="status"
      aria-busy="true"
      aria-label="Loading favorites"
    >
      {[1, 2, 3, 4].map((i) => (
        <div key={i} className={styles.skeletonCard}>
          <div className={styles.skeletonImage} aria-hidden="true" />
          <div className={styles.skeletonContent}>
            <div className={styles.skeletonPrice} aria-hidden="true" />
            <div className={styles.skeletonTitle} aria-hidden="true" />
            <div className={styles.skeletonLocation} aria-hidden="true" />
            <div className={styles.skeletonDetails}>
              <div className={styles.skeletonDetail} aria-hidden="true" />
              <div className={styles.skeletonDetail} aria-hidden="true" />
              <div className={styles.skeletonDetail} aria-hidden="true" />
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
```

Use project `$breakpoint-sm` / `$breakpoint-md` variables for responsive column switch.

---

## Example 4 · Hero section (portfolio pattern, CSS-only)

Replace Framer Motion with CSS — same visual structure as `HeroSkeleton.tsx`.

```tsx
export function HeroSkeleton() {
  return (
    <section
      className={styles.heroSkeleton}
      role="status"
      aria-busy="true"
      aria-label="Loading hero section"
    >
      <div className={styles.heroContent}>
        <div className={`${styles.bar} ${styles.heroTitle}`} aria-hidden="true" />
        <div className={`${styles.bar} ${styles.heroSubtitle}`} aria-hidden="true" />
        <div className={`${styles.bar} ${styles.heroDescription}`} aria-hidden="true" />
        <div className={styles.heroCredentials}>
          <div className={styles.credentialSkeleton} aria-hidden="true">
            <div className={`${styles.bar} ${styles.credentialNumber}`} />
            <div className={`${styles.bar} ${styles.credentialLabel}`} />
          </div>
          <div className={styles.credentialSkeleton} aria-hidden="true">
            <div className={`${styles.bar} ${styles.credentialNumber}`} />
            <div className={`${styles.bar} ${styles.credentialLabel}`} />
          </div>
        </div>
      </div>
    </section>
  );
}
```

---

## Example 5 · Gallery skeleton (before/after grid)

Match `_gallery.scss` `.beforeAfterGrid` — 2 columns, centered, gap `5vw`:

```scss
.beforeAfterSkeleton {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 5vw;
  width: min(100%, 62rem);
  margin-inline: auto;

  @media (max-width: 767px) {
    grid-template-columns: 1fr;
  }
}

.beforeAfterCard {
  aspect-ratio: 4 / 5;
  border-radius: var(--radius-panel);
  @include shimmer;
}
```

Hide the decorative divider wave in skeleton — it is not a loading indicator.

---

## Example 6 · Form block skeleton (signup / contact)

Mirror input heights from the real form — typically `2.5rem` inputs, `6rem` textarea:

```scss
.formSkeleton {
  display: grid;
  gap: var(--space-lg);
  max-width: 32rem;
}

.fieldLabel {
  width: 30%;
  height: 0.85rem;
  @include shimmer;
}

.fieldInput {
  width: 100%;
  height: 2.75rem;
  border-radius: 0.5rem;
  @include shimmer;
}

.fieldTextarea {
  width: 100%;
  height: 6rem;
  border-radius: 0.5rem;
  @include shimmer;
}

.submit {
  width: 10rem;
  height: 2.75rem;
  border-radius: 0.5rem;
  @include shimmer;
}
```

---

## Migration note · portfolio-website

Existing `LoadingSkeleton.tsx` uses Framer Motion. When touching that repo:

1. Keep layout classes in `LoadingSkeleton.module.scss`
2. Replace `motion.div` with `<div aria-hidden="true">`
3. Move entrance opacity to CSS if needed — or drop it (skeleton appears instantly)

Do not migrate unless asked — document the preferred pattern for **new** work only.
