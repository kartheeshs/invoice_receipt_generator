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
              <span style={{ color: 'rgba(226, 232, 240, 0.75)', fontWeight: 500 }}>
                Design-led invoices, powered by Flutter
              </span>
            </div>
            <nav className="nav-links">
              <a href="#features">Features</a>
              <a href="#pricing">Pricing</a>
              <a href="/privacy-policy">Privacy</a>
              <a className="primary-button" href="/app">
                Launch app
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
                A refined invoicing workspace that blends a Next.js marketing story with a Flutter-powered editor so teams can
                learn, launch, and collaborate without switching tabs.
              </p>
            </div>
            <div>
              <h3>Explore</h3>
              <ul className="list-reset" style={{ display: 'grid', gap: '0.5rem' }}>
                <li><a href="#features">Features</a></li>
                <li><a href="#pricing">Pricing</a></li>
                <li><a href="/privacy-policy">Privacy &amp; Policy</a></li>
              </ul>
            </div>
            <div>
              <h3>Get help</h3>
              <ul className="list-reset" style={{ display: 'grid', gap: '0.5rem' }}>
                <li><a href="mailto:support@invoice-atlas.example.com">support@invoice-atlas.example.com</a></li>
                <li><a href="/admin">Admin console</a></li>
                <li><a href="/app">Launch the app</a></li>
              </ul>
            </div>
          </div>
          <div style={{ marginTop: '2.5rem', textAlign: 'center', color: '#94a3b8' }}>
            © {new Date().getFullYear()} Invoice Atlas. All rights reserved.
          </div>
        </footer>
      </body>
    </html>
  );
}
