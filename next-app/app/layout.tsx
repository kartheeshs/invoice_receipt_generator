import type { Metadata } from 'next';
import Link from 'next/link';
import { Plus_Jakarta_Sans } from 'next/font/google';
import './globals.css';

const plusJakarta = Plus_Jakarta_Sans({
  subsets: ['latin'],
  variable: '--font-plus-jakarta',
});

export const metadata: Metadata = {
  title: 'Invoice Atlas — Global Invoicing Reinvented',
  description:
    'Generate polished invoices in minutes, collaborate with teams, and export high-fidelity PDFs that respect local business norms worldwide.',
  openGraph: {
    title: 'Invoice Atlas',
    description:
      'Generate polished invoices in minutes, collaborate with teams, and export high-fidelity PDFs that respect local business norms worldwide.',
    url: 'https://invoice-atlas.example.com',
    siteName: 'Invoice Atlas',
  },
  metadataBase: new URL('https://invoice-atlas.example.com'),
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={plusJakarta.variable}>
      <body>
        <header className="navbar">
          <div className="container navbar__inner">
            <Link href="/" className="navbar__brand" prefetch={false}>
              <span className="navbar__logo">IA</span>
              <span className="navbar__tagline">Invoice Atlas · Documents without detours</span>
            </Link>
            <nav className="navbar__links">
              <a href="#templates">Templates</a>
              <a href="#features">Features</a>
              <a href="#pricing">Pricing</a>
              <a href="/privacy-policy">Privacy</a>
              <Link href="/app" className="button button-primary navbar__cta" prefetch={false}>
                Launch app
              </Link>
            </nav>
          </div>
        </header>
        <main>{children}</main>
        <footer className="footer">
          <div className="container">
            <div className="footer__inner">
              <div>
                <h3>Invoice Atlas</h3>
                <p>
                  A refined invoicing workspace that blends a Next.js marketing story with a Flutter-powered editor so teams can learn,
                  launch, and collaborate without switching tabs.
                </p>
              </div>
              <div>
                <h3>Explore</h3>
                <ul className="list-reset" style={{ display: 'grid', gap: '0.6rem' }}>
                  <li>
                    <a href="#features">Features</a>
                  </li>
                  <li>
                    <a href="#pricing">Pricing</a>
                  </li>
                  <li>
                    <a href="/privacy-policy">Privacy &amp; Policy</a>
                  </li>
                </ul>
              </div>
              <div>
                <h3>Get help</h3>
                <ul className="list-reset" style={{ display: 'grid', gap: '0.6rem' }}>
                  <li>
                    <a href="mailto:support@invoice-atlas.example.com">support@invoice-atlas.example.com</a>
                  </li>
                  <li>
                    <a href="/admin">Admin console</a>
                  </li>
                  <li>
                    <a href="/app">Launch the app</a>
                  </li>
                </ul>
              </div>
            </div>
            <div className="footer__bottom">© {new Date().getFullYear()} Invoice Atlas. All rights reserved.</div>
          </div>
        </footer>
      </body>
    </html>
  );
}
