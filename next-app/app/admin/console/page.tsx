import AdminConsoleView from './console-view';

export const metadata = {
  title: 'Admin Console — Invoice Atlas',
  description:
    'Monitor workspace activity, infrastructure health, and support queues in the dedicated Invoice Atlas admin console.',
};

export default function AdminConsolePage() {
  return <AdminConsoleView />;
}
