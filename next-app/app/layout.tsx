import type { Metadata } from 'next';
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
        <div className="navbar">
          <div className="navbar-inner">
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <div className="badge">Invoice Atlas</div>
              <span style={{ color: 'rgba(226,232,240,0.65)' }}>
                Intelligent invoicing for modern finance teams
              </span>
            </div>
            <nav className="nav-links">
              <a href="#templates">Templates</a>
              <a href="#workflow">Workflow</a>
              <a href="#pricing">Pricing</a>
              <a href="/privacy-policy">Privacy</a>
              <a className="button-secondary" href="/app" style={{ padding: '0.6rem 1.2rem' }}>
                Launch Web App
              </a>
            </nav>
          </div>
        </div>
        <main>{children}</main>
        <footer className="footer">
          <div className="footer-inner">
            <div>
              <h3>Invoice Atlas</h3>
              <p>
                Crafted for globally-minded finance teams who need to ship bilingual invoices, automate
                approvals, and maintain crystal-clear records.
              </p>
            </div>
            <div>
              <h3>Platform</h3>
              <ul className="list-reset" style={{ display: 'grid', gap: '0.5rem' }}>
                <li><a href="/app">Launch App</a></li>
                <li><a href="/app?view=create">Create Invoice</a></li>
                <li><a href="/app?view=templates">Template Gallery</a></li>
              </ul>
            </div>
            <div>
              <h3>Company</h3>
              <ul className="list-reset" style={{ display: 'grid', gap: '0.5rem' }}>
                <li><a href="#pricing">Pricing</a></li>
                <li><a href="/privacy-policy">Privacy &amp; Policy</a></li>
                <li><a href="mailto:support@invoice-atlas.example.com">Support</a></li>
              </ul>
            </div>
          </div>
          <div style={{ marginTop: '2.5rem', textAlign: 'center', color: 'rgba(148,163,184,0.6)' }}>
            © {new Date().getFullYear()} Invoice Atlas. All rights reserved.
          </div>
        </footer>
      </body>
    </html>
  );
}
