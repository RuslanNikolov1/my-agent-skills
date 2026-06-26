# Skeleton primitives (SASS modules)

Pure CSS building blocks. No client JavaScript required.

---

## Shared shimmer keyframes

Add once per project (globals or `_skeleton.scss` partial):

```scss
@keyframes skeleton-shimmer {
  0% {
    background-position: -200% 0;
  }
  100% {
    background-position: 200% 0;
  }
}

@keyframes skeleton-pulse {
  0%,
  100% {
    opacity: 0.65;
  }
  50% {
    opacity: 1;
  }
}
```

---

## Shimmer mixin (editorial / oklch sites)

```scss
@mixin skeleton-shimmer(
  $base: var(--color-paper-3),
  $highlight: var(--color-paper-2)
) {
  background: linear-gradient(90deg, $base 25%, $highlight 50%, $base 75%);
  background-size: 200% 100%;
  animation: skeleton-shimmer 1.5s ease-in-out infinite;

  @media (prefers-reduced-motion: reduce) {
    animation: none;
    background: $base;
  }
}
```

## Shimmer mixin (globals.scss token sites)

```scss
@mixin skeleton-shimmer(
  $base: var(--color-surface-container),
  $highlight: var(--color-surface-low)
) {
  background: linear-gradient(90deg, $base 25%, $highlight 50%, $base 75%);
  background-size: 200% 100%;
  animation: skeleton-shimmer 1.5s ease-in-out infinite;

  @media (prefers-reduced-motion: reduce) {
    animation: none;
    background: $base;
  }
}
```

---

## Bar primitive

```scss
// Skeleton.module.scss
.bar {
  @include skeleton-shimmer;
  border-radius: 0.35rem;
}

.barWide {
  composes: bar;
  width: 100%;
  height: 1rem;
}

.barMedium {
  composes: bar;
  width: 70%;
  height: 1rem;
}

.barShort {
  composes: bar;
  width: 40%;
  height: 0.85rem;
}
```

> **Note:** `composes` is CSS-modules syntax — if the project avoids it, duplicate the mixin call per class (hairdresser-app style).

---

## Media block primitive

Always set explicit `aspect-ratio` matching the real image container:

```scss
.media {
  position: relative;
  overflow: hidden;
  aspect-ratio: 4 / 5;
  border-radius: var(--radius-panel);
  @include skeleton-shimmer;
}
```

Common ratios in Ruslan's repos:

| UI | aspect-ratio |
|----|--------------|
| Module card image | `4 / 5` |
| Hero image | `16 / 9` or `3 / 2` |
| Avatar | `1 / 1` (use `border-radius: 50%`) |
| Gallery thumb | `4 / 3` |
| Listing card image | `40%` width column or `16 / 10` |

---

## Optional base component (Style B)

Use only when 3+ skeletons share bars. **No Framer Motion** — static CSS animation.

```tsx
// src/components/skeleton/Skeleton.tsx
import styles from "./Skeleton.module.scss";

interface SkeletonProps {
  className?: string;
  variant?: "bar" | "media" | "circle";
}

export function Skeleton({ className = "", variant = "bar" }: SkeletonProps) {
  return (
    <div
      className={`${styles[variant]} ${className}`.trim()}
      aria-hidden="true"
    />
  );
}
```

```scss
// Skeleton.module.scss
@import "../../styles/skeleton"; // mixin partial

.bar {
  @include skeleton-shimmer;
  border-radius: 0.35rem;
}

.media {
  @include skeleton-shimmer;
  border-radius: var(--radius-panel, 0.75rem);
}

.circle {
  @include skeleton-shimmer;
  border-radius: 50%;
}
```

---

## Staggered shimmer (optional polish)

CSS only — nth-child delays, not JS:

```scss
.cardSkeleton {
  @include skeleton-shimmer;
  animation-delay: calc(var(--index, 0) * 80ms);
}
```

```tsx
{Array.from({ length: 3 }).map((_, i) => (
  <div
    key={i}
    className={styles.cardSkeleton}
    style={{ "--index": i } as React.CSSProperties}
    aria-hidden="true"
  />
))}
```

---

## Pulse vs shimmer

| Animation | Use when |
|-----------|----------|
| **shimmer** | Default — text bars, images, cards |
| **pulse** | Subtle whole-card breathe (real-estate `skeletonCard`) — use sparingly |
| **none** | `prefers-reduced-motion: reduce` always |

Do not combine pulse on the parent and shimmer on every child — pick one level.
