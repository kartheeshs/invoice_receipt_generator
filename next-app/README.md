# Easy Invoice GM7 web workspace

This project contains the marketing site and client-side workspace for Easy Invoice GM7, rebuilt entirely with Next.js. The `/app` route mirrors the original Flutter UI: a top navigation bar with dashboard, invoices, templates, clients, activity, and settings links; an invoice editor with live preview; recent activity; and supporting sections for templates and client insights.

## Development

```bash
cd next-app
npm install
npm run dev
```

The dev server runs at `http://localhost:3000`. The marketing site is rendered on the index route, while `/app` loads the interactive invoice workspace.

## Environment variables

Create a `.env.local` file (or copy `.env.example`) if you want to connect to Firebase:

```env
NEXT_PUBLIC_FIREBASE_API_KEY=AIzaSyC9yXs3QnOfRyLyN74QyilSfeKL-fVUxAQ
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=invoice-receipt-generator-g7.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=invoice-receipt-generator-g7
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=invoice-receipt-generator-g7.firebasestorage.app
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=798489264335
NEXT_PUBLIC_FIREBASE_APP_ID=1:798489264335:web:b1bc7f6fe8dc5e68de37ba
NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID=G-TKYV2VSPMZ
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

- The top navigation replicates the Flutter layout but uses semantic HTML and CSS utilities
- PDF downloads rely on `window.print()` so they work without extra binaries in the browser
- All sections are responsive down to small screens, collapsing the navigation into a horizontal scrollable list when the viewport narrows
