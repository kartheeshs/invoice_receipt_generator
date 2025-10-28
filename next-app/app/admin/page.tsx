import AdminLandingView from './admin-landing-view';

export const metadata = {
  title: 'Admin Access — Easy Invoice GM7',
  description:
    'Secure entry point for Easy Invoice GM7 administrators. Launch the dedicated admin console within the web application.',
};

export default function AdminLandingPage() {
  return <AdminLandingView />;
}
