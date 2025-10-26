import Link from 'next/link';

export const metadata = {
  title: 'Admin Access — Invoice Atlas',
  description:
    'Secure entry point for Invoice Atlas administrators. Launch the dedicated admin console within the web application.',
};

export default function AdminLandingPage() {
  return (
    <section className="section" style={{ padding: '6rem 0 4rem' }}>
      <div className="card" style={{ margin: '0 auto', maxWidth: '640px' }}>
        <span className="badge">Administrator sign-in</span>
        <h1 style={{ marginTop: '0.85rem' }}>Secure access required</h1>
        <p>
          Administrators manage workspaces, subscriptions, and compliance logs inside the dedicated console embedded in
          the Invoice Atlas web application. Launch the console below and sign in with your administrator credentials.
        </p>
        <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
          <Link className="button-primary" href="/app?view=admin">
            Open admin console
          </Link>
          <Link className="button-secondary" href="/">
            Return to marketing site
          </Link>
        </div>
        <small style={{ display: 'block', marginTop: '1.25rem' }}>
          Trouble accessing your account? Email <a href="mailto:admin@invoice-atlas.example.com">admin@invoice-atlas.example.com</a>.
        </small>
      </div>
    </section>
  );
}
