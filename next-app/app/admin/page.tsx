import Link from 'next/link';

export const metadata = {
  title: 'Admin Access — Invoice Atlas',
  description:
    'Secure entry point for Invoice Atlas administrators. Launch the dedicated admin console within the web application.',
};

export default function AdminLandingPage() {
  return (
    <section style={{ padding: '6rem 0 4rem' }}>
      <div className="container" style={{ display: 'flex', justifyContent: 'center' }}>
        <div
          className="template-card"
          style={{ maxWidth: '620px', padding: '2.25rem 2rem', boxShadow: 'var(--shadow-md)' }}
        >
          <span className="badge">Administrator sign-in</span>
          <h1 style={{ marginTop: '1rem' }}>Secure access required</h1>
          <p style={{ marginTop: '0.75rem', lineHeight: 1.7 }}>
            Administrators manage workspaces, subscriptions, and compliance logs inside the dedicated console embedded in the
            Invoice Atlas web application. Launch the console below and sign in with your administrator credentials.
          </p>
          <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap', marginTop: '1.75rem' }}>
            <Link className="button button--primary" href="/app?view=admin">
              Open admin console
            </Link>
            <Link className="button button--ghost" href="/">
              Return to marketing site
            </Link>
          </div>
          <small style={{ display: 'block', marginTop: '1.5rem', color: 'var(--text-muted)' }}>
            Trouble accessing your account? Email{' '}
            <a href="mailto:admin@invoice-atlas.example.com">admin@invoice-atlas.example.com</a>.
          </small>
        </div>
      </div>
    </section>
  );
}
