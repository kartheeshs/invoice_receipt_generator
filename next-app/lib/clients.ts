export type ClientDirectoryEntry = {
  name: string;
  email: string;
  address: string;
  notes?: string;
  phone?: string;
};

export type ManagedClient = {
  id: string;
  name: string;
  email: string;
  address: string;
  company?: string;
  phone?: string;
  notes?: string;
  createdAt: string;
  updatedAt: string;
};

export const CLIENT_STORAGE_KEY = 'invoice-gm7-clients';

export function createClientId(): string {
  if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) {
    return crypto.randomUUID();
  }
  return `client-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

export function loadManagedClients(): ManagedClient[] {
  if (typeof window === 'undefined') {
    return [];
  }

  const raw = window.localStorage.getItem(CLIENT_STORAGE_KEY);
  if (!raw) {
    return [];
  }

  try {
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) {
      return [];
    }

    return parsed
      .filter((entry) => typeof entry === 'object' && entry)
      .map((entry) => ({
        id: typeof entry.id === 'string' ? entry.id : createClientId(),
        name: typeof entry.name === 'string' ? entry.name : '',
        email: typeof entry.email === 'string' ? entry.email : '',
        address: typeof entry.address === 'string' ? entry.address : '',
        company: typeof entry.company === 'string' ? entry.company : undefined,
        phone: typeof entry.phone === 'string' ? entry.phone : undefined,
        notes: typeof entry.notes === 'string' ? entry.notes : undefined,
        createdAt:
          typeof entry.createdAt === 'string' && entry.createdAt
            ? entry.createdAt
            : new Date().toISOString(),
        updatedAt:
          typeof entry.updatedAt === 'string' && entry.updatedAt
            ? entry.updatedAt
            : new Date().toISOString(),
      }))
      .filter((entry) => entry.name.trim().length > 0);
  } catch {
    return [];
  }
}

export function persistManagedClients(clients: ManagedClient[]): void {
  if (typeof window === 'undefined') {
    return;
  }

  const payload = JSON.stringify(
    clients.map((client) => ({
      ...client,
      createdAt: client.createdAt ?? new Date().toISOString(),
      updatedAt: client.updatedAt ?? new Date().toISOString(),
    })),
  );

  window.localStorage.setItem(CLIENT_STORAGE_KEY, payload);
}

export const clientDirectory: ClientDirectoryEntry[] = [
  {
    name: 'Villa Contentezza',
    email: 'billing@villacontentezza.com',
    address: 'Via Tammaricella 128, Rome, Italy',
    notes: 'Boutique holiday rentals across Italy.',
  },
  {
    name: 'Thynk Unlimited',
    email: 'accounts@thynkunlimited.com',
    address: '123 Anywhere St, Any City, USA',
    notes: 'Creative technology studio for launch campaigns.',
  },
  {
    name: 'Ad4tech Material LLC',
    email: 'finance@ad4tech.example',
    address: '#34, Carr street, Alexander Road, Hong Kong',
    notes: 'Enterprise materials sourcing specialists.',
  },
  {
    name: 'Agoda Holdings',
    email: 'ap@agoda-holdings.com',
    address: 'Prudential Tower #19-08, Singapore 049712',
    notes: 'Global travel marketplace and hotel booking platform.',
  },
  {
    name: 'Yusaku Holdings',
    email: 'billing@yusaku-holdings.jp',
    address: '1-9-1 Marunouchi, Chiyoda City, Tokyo 100-0005',
    notes: 'Art advisory and investment collective.',
  },
  {
    name: 'Northwind Co.',
    email: 'billing@northwind.co',
    address: '400 Market Street, Portland, OR 97205',
    notes: 'Recurring analytics partnership.',
  },
  {
    name: 'Mosaic Systems',
    email: 'ap@mosaicsystems.dev',
    address: '18 Innovation Way, Austin, TX 73301',
    notes: 'Product design and implementation services.',
  },
  {
    name: 'Lumina Ventures',
    email: 'finance@luminaventures.ai',
    address: '600 Market Plaza, Suite 410, Seattle, WA 98101',
    notes: 'Growth equity investment firm.',
  },
];

export function matchClients(query: string): ClientDirectoryEntry[] {
  const trimmed = query.trim().toLowerCase();
  if (!trimmed) {
    return [];
  }

  return clientDirectory.filter((client) => {
    return (
      client.name.toLowerCase().includes(trimmed) ||
      client.email.toLowerCase().includes(trimmed)
    );
  });
}
