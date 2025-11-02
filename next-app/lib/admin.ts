export type AdminVital = {
  key: string;
  label: string;
  value: string;
  delta: string;
};

export type AdminHealthCheck = {
  key: string;
  name: string;
  status: 'Operational' | 'Degraded' | 'Maintenance';
  detail: string;
};

export type AdminSupportTicket = {
  contact: string;
  summary: string;
  updated: string;
};

export type AdminUserRole = 'owner' | 'admin' | 'member';
export type AdminUserStatus = 'active' | 'invited' | 'suspended';

export type AdminUser = {
  id: string;
  name: string;
  email: string;
  role: AdminUserRole;
  status: AdminUserStatus;
  lastActive: string;
  createdAt: string;
};

export const ADMIN_USERS_STORAGE_KEY = 'invoice-gm7-admin-users';

export function createAdminUserId(): string {
  if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) {
    return crypto.randomUUID();
  }
  return `admin-user-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

export const adminUsersSeed: AdminUser[] = [
  {
    id: 'admin-user-001',
    name: 'Elena Vasquez',
    email: 'elena@easyinvoicegm7.example.com',
    role: 'owner',
    status: 'active',
    lastActive: 'Active 3 minutes ago',
    createdAt: '2022-04-12T10:15:00.000Z',
  },
  {
    id: 'admin-user-002',
    name: 'Marcus Liu',
    email: 'marcus@easyinvoicegm7.example.com',
    role: 'admin',
    status: 'active',
    lastActive: 'Active 1 hour ago',
    createdAt: '2022-08-03T14:22:00.000Z',
  },
  {
    id: 'admin-user-003',
    name: 'Priya Natarajan',
    email: 'priya@easyinvoicegm7.example.com',
    role: 'admin',
    status: 'invited',
    lastActive: 'Invitation sent 2 days ago',
    createdAt: '2023-01-18T09:05:00.000Z',
  },
  {
    id: 'admin-user-004',
    name: 'Jonah Miller',
    email: 'jonah@easyinvoicegm7.example.com',
    role: 'member',
    status: 'active',
    lastActive: 'Active yesterday',
    createdAt: '2023-05-24T16:45:00.000Z',
  },
  {
    id: 'admin-user-005',
    name: 'Mina Kobayashi',
    email: 'mina@easyinvoicegm7.example.com',
    role: 'member',
    status: 'suspended',
    lastActive: 'Suspended 3 weeks ago',
    createdAt: '2023-09-01T11:10:00.000Z',
  },
  {
    id: 'admin-user-006',
    name: 'Omar Haddad',
    email: 'omar@easyinvoicegm7.example.com',
    role: 'member',
    status: 'active',
    lastActive: 'Active 5 hours ago',
    createdAt: '2024-02-14T08:40:00.000Z',
  },
];

export function loadAdminUsers(): AdminUser[] {
  if (typeof window === 'undefined') {
    return adminUsersSeed;
  }

  const raw = window.localStorage.getItem(ADMIN_USERS_STORAGE_KEY);
  if (!raw) {
    return adminUsersSeed;
  }

  try {
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) {
      return adminUsersSeed;
    }

    const valid = parsed
      .filter((entry) => typeof entry === 'object' && entry)
      .map((entry) => ({
        id: typeof entry.id === 'string' ? entry.id : createAdminUserId(),
        name: typeof entry.name === 'string' ? entry.name : '',
        email: typeof entry.email === 'string' ? entry.email : '',
        role: (entry.role as AdminUserRole) ?? 'member',
        status: (entry.status as AdminUserStatus) ?? 'active',
        lastActive:
          typeof entry.lastActive === 'string' && entry.lastActive
            ? entry.lastActive
            : 'Last active unknown',
        createdAt:
          typeof entry.createdAt === 'string' && entry.createdAt
            ? entry.createdAt
            : new Date().toISOString(),
      }))
      .filter((entry) => entry.name.trim().length > 0 && entry.email.trim().length > 0);

    return valid.length ? valid : adminUsersSeed;
  } catch {
    return adminUsersSeed;
  }
}

export function persistAdminUsers(users: AdminUser[]): void {
  if (typeof window === 'undefined') {
    return;
  }

  const payload = JSON.stringify(
    users.map((user) => ({
      ...user,
      createdAt: user.createdAt ?? new Date().toISOString(),
      lastActive: user.lastActive ?? 'Last active unknown',
    })),
  );
  window.localStorage.setItem(ADMIN_USERS_STORAGE_KEY, payload);
}

export const adminVitals: AdminVital[] = [
  { key: 'activeUsers', label: 'Active users', value: '128', delta: '+12.5% vs last week' },
  { key: 'pendingApprovals', label: 'Pending approvals', value: '6', delta: '-2 week over week' },
  { key: 'pdfRenders', label: 'PDF renders (24h)', value: '312', delta: '+48 in the last day' },
];

export const adminHealthChecks: AdminHealthCheck[] = [
  { key: 'firestore', name: 'Firestore connectivity', status: 'Operational', detail: 'Latency 82ms avg' },
  { key: 'pdfQueue', name: 'PDF rendering queue', status: 'Operational', detail: 'No backlog — 4 workers active' },
  { key: 'email', name: 'Email delivery', status: 'Degraded', detail: '1.2% soft bounce — monitoring' },
];

export const adminSupportQueue: AdminSupportTicket[] = [
  { contact: 'billing@lumina.ai', summary: 'Asked for bank transfer confirmation', updated: 'Updated 2h ago' },
  { contact: 'ops@northwind.co', summary: 'Automation rules review scheduled', updated: 'Due tomorrow' },
  { contact: 'finance@atlas.example', summary: 'Monthly reconciliation export generated', updated: 'Completed 6h ago' },
];
