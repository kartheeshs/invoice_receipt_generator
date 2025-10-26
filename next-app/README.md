# Invoice Atlas marketing site

This Next.js application provides a search-friendly marketing layer for the Invoice Atlas platform. The Flutter web
client is served beneath the `/app` path so marketing pages remain SEO-friendly while the interactive experience runs
unchanged.

## Development

```
cd next-app
pnpm install # or npm install / yarn install
pnpm dev
```

The development server will be available at `http://localhost:3000`.

## Deploying the Flutter web build

1. Build the Flutter web client using a base href that matches the `/app` prefix:
   ```
   flutter build web --base-href /app/
   ```
2. Copy the contents of `web/build/web` into `next-app/public/flutter-app`.
3. Deploy the Next.js site (for example with Vercel or Firebase Hosting). Requests to `/app` will automatically serve
the Flutter application, while `/` and other marketing routes remain statically generated.

## Available scripts

- `pnpm dev` – start the Next.js dev server.
- `pnpm build` – create an optimized production build.
- `pnpm start` – run the built app in production mode.
- `pnpm lint` – run ESLint checks.

## Directory structure

- `app/` – App Router routes and shared UI components.
- `public/` – Static assets and the Flutter build output (`public/flutter-app`).
- `app/privacy-policy` – SEO-friendly privacy policy page reflecting platform commitments.

## SEO benefits

- Marketing pages render on the server, delivering meaningful HTML to search engines.
- Canonical navigation keeps `/app` reserved for the interactive Flutter experience without compromising discoverability.

