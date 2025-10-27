import type { Metadata } from 'next';
import type { ReactElement } from 'react';
import LoginView from './login-view';

export const metadata: Metadata = {
  title: 'Sign in — Easy Invoice GM7',
  description: 'Access your Easy Invoice GM7 workspace to create invoices, manage clients, and review payment activity.',
};

export default function LoginPage(): ReactElement {
  return <LoginView />;
}
