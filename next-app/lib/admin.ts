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
