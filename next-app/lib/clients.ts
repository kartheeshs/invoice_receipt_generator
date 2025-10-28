export type ClientDirectoryEntry = {
  name: string;
  email: string;
  address: string;
  notes?: string;
};

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
