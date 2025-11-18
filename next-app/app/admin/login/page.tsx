import type { Metadata } from 'next';
import LoginView from '../../login/login-view';

export const metadata: Metadata = {
  title: 'Admin Sign In — Easy Invoice GM7',
  description: 'Access the Easy Invoice GM7 admin console to manage users, billing workspaces, and compliance records.',
};

export default function AdminLoginPage() {
  return <LoginView mode="admin" requireRole="admin" />;
}
