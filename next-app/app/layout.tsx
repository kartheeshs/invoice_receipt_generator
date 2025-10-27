import type { Metadata } from 'next';
import Link from 'next/link';
import { Plus_Jakarta_Sans } from 'next/font/google';
import './globals.css';

const plusJakarta = Plus_Jakarta_Sans({
  subsets: ['latin'],
  variable: '--font-sans',
});

export const metadata: Metadata = {
  title: 'Easy Invoice GM7 — Modern Invoice & Receipt Workspace',
  description:
    'Create polished invoices, switch between branded templates, and sync with Firebase in a single browser-first workspace.',
  openGraph: {
    title: 'Easy Invoice GM7',
    description:
      'Create polished invoices, switch between branded templates, and sync with Firebase in a single browser-first workspace.',
    url: 'https://easy-invoice-gm7.example.com',
    siteName: 'Easy Invoice GM7',
  },
  metadataBase: new URL('https://easy-invoice-gm7.example.com'),
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const year = new Date().getFullYear();
  return (
    <html lang="en" className={plusJakarta.variable}>
      <body>
        <div className="site-shell">
          <header className="site-header">
            <div className="container site-header__inner">
              <Link href="/" className="site-brand" prefetch={false}>
                <span className="site-brand__mark">
                  <img src="/easy-invoice-gm7-logo.svg" alt="Easy Invoice GM7" />
                </span>
                <span className="site-brand__meta">
                  <strong>Easy Invoice GM7</strong>
                  <span>Modern billing workspace</span>
                </span>
              </Link>
              <nav className="site-nav">
                <a href="#features">Features</a>
                <a href="#templates">Templates</a>
                <a href="#workflow">Workflow</a>
                <a href="#pricing">Pricing</a>
                <Link href="/privacy-policy" prefetch={false}>
                  Privacy
                </Link>
                <Link href="/login" prefetch={false}>
                  Sign in
                </Link>
                <Link href="/app" className="button button--primary" prefetch={false}>
                  Launch app
                </Link>
              </nav>
            </div>
          </header>
          <main>{children}</main>
          <footer className="site-footer">
            <div className="container site-footer__grid">
              <div>
                <h3>Easy Invoice GM7</h3>
                <p>
                  Create invoice and receipt PDFs that feel bespoke without fighting a designer. The marketing site and the workspace share a single design system.
                </p>
              </div>
              <div>
                <h3>Explore</h3>
                <ul>
                  <li>
                    <a href="#features">Feature tour</a>
                  </li>
                  <li>
                    <a href="#templates">Template gallery</a>
                  </li>
                  <li>
                    <a href="#pricing">Pricing</a>
                  </li>
                </ul>
              </div>
              <div>
                <h3>Company</h3>
                <ul>
                  <li>
                    <Link href="/privacy-policy" prefetch={false}>
                      Privacy policy
                    </Link>
                  </li>
                  <li>
                    <a href="mailto:support@easyinvoicegm7.example.com">support@easyinvoicegm7.example.com</a>
                  </li>
                  <li>
                    <Link href="/admin" prefetch={false}>
                      Admin console
                    </Link>
                  </li>
                </ul>
              </div>
            </div>
            <div className="site-footer__meta">© {year} Easy Invoice GM7. All rights reserved.</div>
          </footer>
        </div>
      </body>
    </html>
  );
}
