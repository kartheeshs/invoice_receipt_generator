const API_BASE = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:3001';

async function post<T>(url: string, body: Record<string, unknown>): Promise<T> {
  const response = await fetch(`${API_BASE}${url}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(body)
  });

  if (!response.ok) {
    throw new Error(`API request failed: ${response.status}`);
  }

  return response.json() as Promise<T>;
}

export function createCheckoutSession(userId: string, email?: string | null) {
  return post<{ url: string }>('/billing/create-checkout-session', {
    userId,
    email: email ?? undefined
  });
}

export function createCustomerPortal(userId: string) {
  return post<{ url: string }>('/billing/customer-portal', {
    userId
  });
}
