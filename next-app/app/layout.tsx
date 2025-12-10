import type { Metadata } from 'next';
import { Plus_Jakarta_Sans } from 'next/font/google';
import './globals.css';
import Providers from './providers';
import SiteHeader from './site-header';
import SiteFooter from './site-footer';

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
  return (
    <html lang="en" className={plusJakarta.variable}>
      <body>
        <Providers>
          <div className="site-shell">
            <SiteHeader />
            <main>{children}</main>
            <SiteFooter />
          </div>
        </Providers>
      </body>
    </html>
  );
}
