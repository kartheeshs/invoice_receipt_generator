import { NextRequest, NextResponse } from 'next/server';

export const runtime = 'nodejs';

const stripeSecretKey =
  process.env.STRIPE_SECRET_KEY ?? 'sk_test_51SMrPSRuLo7evHJI0rlQCC52vXJhmCnd2CQbEfCU6PhtPLdMBRgkvi4uaa5BFx8V3OXI75KBbxwRBXOkmVXTSiSd00tmb4ztX2';

if (!stripeSecretKey) {
  throw new Error('Stripe secret key is not configured. Set STRIPE_SECRET_KEY in your environment.');
}

const fallbackAmount = Number.parseInt(process.env.STRIPE_PRICE_AMOUNT ?? '1900', 10);
const fallbackCurrency = process.env.STRIPE_PRICE_CURRENCY ?? 'usd';
const allowedIntervals = new Set(['day', 'week', 'month', 'year']);
const envInterval = process.env.STRIPE_PRICE_INTERVAL ?? 'month';
const fallbackInterval = allowedIntervals.has(envInterval) ? envInterval : 'month';
const configuredPriceId = process.env.STRIPE_PRICE_ID;

function resolveOrigin(request: NextRequest): string {
  const originHeader = request.headers.get('origin');
  if (originHeader) {
    return originHeader;
  }
  if (process.env.NEXT_PUBLIC_APP_URL) {
    return process.env.NEXT_PUBLIC_APP_URL;
  }
  if (process.env.APP_URL) {
    return process.env.APP_URL;
  }
  return 'http://localhost:3000';
}

export async function POST(request: NextRequest) {
  try {
    const origin = resolveOrigin(request);
    const successUrl = `${origin.replace(/\/$/, '')}/app?subscription=success`;
    const cancelUrl = `${origin.replace(/\/$/, '')}/app?subscription=canceled`;

    const params = new URLSearchParams();
    params.append('mode', 'subscription');
    params.append('allow_promotion_codes', 'true');
    params.append('success_url', successUrl);
    params.append('cancel_url', cancelUrl);

    if (configuredPriceId) {
      params.append('line_items[0][price]', configuredPriceId);
      params.append('line_items[0][quantity]', '1');
    } else {
      const amount = Number.isFinite(fallbackAmount) ? fallbackAmount : 1900;
      params.append('line_items[0][price_data][currency]', fallbackCurrency);
      params.append('line_items[0][price_data][recurring][interval]', fallbackInterval);
      params.append('line_items[0][price_data][unit_amount]', amount.toString());
      params.append('line_items[0][price_data][product_data][name]', 'Easy Invoice GM7 Premium');
      params.append(
        'line_items[0][price_data][product_data][description]',
        'Unlimited template access and PDF downloads.',
      );
      params.append('line_items[0][quantity]', '1');
    }

    const response = await fetch('https://api.stripe.com/v1/checkout/sessions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${stripeSecretKey}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params,
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Failed to create Stripe checkout session', response.status, errorText);
      return NextResponse.json({ error: 'Unable to create checkout session' }, { status: 500 });
    }

    const payload = (await response.json()) as { id?: string; url?: string };
    if (!payload.id) {
      console.error('Stripe response missing session id', payload);
      return NextResponse.json({ error: 'Unable to create checkout session' }, { status: 500 });
    }

    return NextResponse.json({ sessionId: payload.id, url: payload.url });
  } catch (error) {
    console.error('Failed to create Stripe checkout session', error);
    return NextResponse.json({ error: 'Unable to create checkout session' }, { status: 500 });
  }
}
