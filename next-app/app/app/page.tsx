'use client';

import { useMemo, useState } from 'react';
import Link from 'next/link';

const DEFAULT_FLUTTER_URL = '/flutter/index.html';

export default function FlutterShellPage() {
  const flutterUrl = useMemo(() => {
    const raw = process.env.NEXT_PUBLIC_FLUTTER_APP_URL ?? DEFAULT_FLUTTER_URL;
    const trimmed = raw.trim();
    if (!trimmed) {
      return DEFAULT_FLUTTER_URL;
    }
    return trimmed.endsWith('/') && !trimmed.endsWith('.html') ? `${trimmed}index.html` : trimmed;
  }, []);
  const [loadError, setLoadError] = useState(false);

  return (
    <div className="app-shell">
      <div className="app-shell__inner">
        <header className="app-shell__header">
          <div>
            <p className="app-shell__eyebrow">Embedded preview</p>
            <h1>Invoice Atlas workspace</h1>
            <p>
              The Flutter experience loads inside this frame so you can keep the marketing site and the product in one place. Use the
              button on the right to pop the workspace into a dedicated tab whenever you need more room.
            </p>
          </div>
          <div className="app-shell__actions">
            <Link prefetch={false} href={flutterUrl} target="_blank" rel="noreferrer" className="button button--primary">
              Open full app
            </Link>
            <Link prefetch={false} href="/" className="button button--ghost">
              Back to marketing site
            </Link>
          </div>
        </header>
        <div className="app-shell__frame">
          {loadError ? (
            <div className="app-shell__error">
              <h2>We couldn&apos;t load the Flutter workspace.</h2>
              <p>
                Double-check the deployed web build URL or run <code>flutter build web --base-href /flutter/</code> to refresh the static
                files inside <code>public/flutter</code>.
              </p>
              <Link prefetch={false} href={flutterUrl} target="_blank" rel="noreferrer" className="button button--primary">
                Try opening in a new tab
              </Link>
            </div>
          ) : (
            <iframe
              src={flutterUrl}
              title="Invoice Atlas web workspace"
              onError={() => setLoadError(true)}
              allow="clipboard-write"
              className="app-shell__iframe"
            />
          )}
        </div>
      </div>
    </div>
  );
}
