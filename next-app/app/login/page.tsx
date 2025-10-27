import type { Metadata } from 'next';
import type { ReactElement } from 'react';
import LoginView from './login-view';

export const metadata: Metadata = {
  title: 'Sign in — Invoice Atlas',
  description: 'Access your Invoice Atlas workspace to create invoices, manage clients, and review payment activity.',
};

export default function LoginPage(): ReactElement {
  return <LoginView />;
}
