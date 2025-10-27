# Invoice Atlas web workspace

This project contains the marketing site and client-side workspace for Invoice Atlas, rebuilt entirely with Next.js. The `/app` route mirrors the original Flutter UI: a sidebar with dashboard, invoices, templates, clients, and settings links; an invoice editor with live preview; recent activity; and supporting sections for templates and client insights.

## Development

```bash
cd next-app
npm install
npm run dev
```

The dev server runs at `http://localhost:3000`. The marketing site is rendered on the index route, while `/app` loads the interactive invoice workspace.

## Environment variables

Create a `.env.local` file if you want to connect to Firebase:

```env
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your-project-id
NEXT_PUBLIC_FIREBASE_WEB_API_KEY=your-web-api-key
```

When the keys are omitted the workspace falls back to bundled sample data so the UI remains functional offline.

## Scripts

- `npm run dev` – start the Next.js development server
- `npm run build` – create a production build
- `npm run export` – run `next export` against the previous build
- `npm run build:static` – build and export into `out/` for Firebase Hosting
- `npm run lint` – run ESLint

## Deployment

1. Generate a static export:
   ```bash
   npm run build:static
   ```
2. Deploy the `out/` directory. For Firebase Hosting this repository already points `firebase.json` to `next-app/out`.

## Project structure

- `app/` – App Router routes and shared UI
- `lib/` – invoice utilities, Firebase helpers, and sample data
- `public/` – static assets (logos, favicons, etc.)
- `app/app/page.tsx` – main workspace view
- `app/privacy-policy/page.tsx` – privacy policy page styled with the shared design system

## UI notes

- The sidebar replicates the Flutter layout but uses semantic HTML and CSS utilities
- PDF downloads rely on `window.print()` so they work without extra binaries in the browser
- All sections are responsive down to small screens, stacking the sidebar above the content when the viewport narrows
