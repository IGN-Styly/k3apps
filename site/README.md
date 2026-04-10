# k3apps Site

This app is the static package index published from the root of the `gh-pages` branch.

## Commands

```sh
pnpm install
pnpm run dev
pnpm run check
pnpm run build
pnpm run build:pages
```

`build:pages` sets `BASE_PATH=/k3apps` so the output matches GitHub Pages hosting.

## Package Data

`pnpm run generate:packages` reads `../packages/*/.SRCINFO` and writes a static search index to `src/lib/generated/package-index.json`.
