import ManageUsersView from './manage-users-view';

export const metadata = {
  title: 'Admin Management — Easy Invoice GM7',
  description:
    'Review workspace members, adjust roles, and invite administrators through the Easy Invoice GM7 admin area.',
};

export default function AdminLandingPage() {
  return <ManageUsersView />;
}
