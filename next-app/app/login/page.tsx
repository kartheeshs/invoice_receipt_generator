import Link from 'next/link';

export const metadata = {
  title: 'Sign in — Invoice Atlas',
  description: 'Access your Invoice Atlas workspace to create invoices, manage clients, and review payment activity.',
};

export default function LoginPage() {
  return (
    <div className="auth-page">
      <div className="auth-hero">
        <div className="container">
          <span className="badge">Welcome back</span>
          <h1>Sign in to Invoice Atlas</h1>
          <p>Enter your workspace email address to continue where you left off.</p>
        </div>
      </div>

      <div className="auth-body">
        <div className="container auth-layout">
          <section className="auth-card">
            <form className="auth-form" aria-label="Member sign in">
              <div className="auth-form__field">
                <label htmlFor="email">Email</label>
                <input id="email" name="email" type="email" placeholder="you@company.com" required />
              </div>
              <div className="auth-form__field auth-form__field--split">
                <div>
                  <label htmlFor="password">Password</label>
                  <input id="password" name="password" type="password" placeholder="••••••••" required />
                </div>
                <div className="auth-form__inline">
                  <input id="remember" name="remember" type="checkbox" />
                  <label htmlFor="remember">Stay signed in</label>
                </div>
              </div>
              <button type="submit" className="button button--primary auth-form__submit">
                Continue
              </button>
              <div className="auth-form__links">
                <Link href="/reset" prefetch={false}>
                  Forgot password?
                </Link>
                <Link href="/signup" prefetch={false}>
                  Create an account
                </Link>
              </div>
              <p className="auth-form__hint">
                Administrators manage workspace access inside the{' '}
                <Link href="/admin/console" prefetch={false}>
                  admin console
                </Link>
                .
              </p>
            </form>
          </section>

          <aside className="auth-aside">
            <article className="auth-insight">
              <h2>Everything from the dashboard, now in the browser</h2>
              <ul>
                <li>Create invoices with a template gallery that mirrors the Flutter experience.</li>
                <li>Track payment status, reminders, and outstanding balances in one place.</li>
                <li>Switch between dashboard, invoice editor, templates, and client directories from the sidebar menu.</li>
              </ul>
              <Link className="button button--ghost" href="/app" prefetch={false}>
                Explore the workspace
              </Link>
            </article>
          </aside>
        </div>
      </div>
    </div>
  );
}
