import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import Stripe from 'stripe';
import dayjs from 'dayjs';
import { ensureUserDocument, storeStripeCustomerId, updateSubscriptionStatus, getUserByStripeCustomer } from './subscription.js';

const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
const stripeWebhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
const priceId = process.env.STRIPE_PRICE_ID;
const frontendUrl = process.env.FRONTEND_URL ?? 'http://localhost:5173';

if (!stripeSecretKey || !priceId) {
  throw new Error('Missing STRIPE_SECRET_KEY or STRIPE_PRICE_ID environment variables');
}

const stripe = new Stripe(stripeSecretKey, {
  apiVersion: '2024-06-20'
});

const app = express();

app.use(
  cors({
    origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : true
  })
);

const jsonMiddleware = express.json();
app.use((req, res, next) => {
  if (req.originalUrl.startsWith('/billing/webhook')) {
    next();
  } else {
    jsonMiddleware(req, res, next);
  }
});

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', time: dayjs().toISOString() });
});

async function getOrCreateCustomer(userId: string, email?: string | null) {
  const userRef = await ensureUserDocument(userId);
  const snapshot = await userRef.get();
  const data = snapshot.data() as { stripeCustomerId?: string } | undefined;
  if (data?.stripeCustomerId) {
    return data.stripeCustomerId;
  }

  const customer = await stripe.customers.create({
    email: email ?? undefined,
    metadata: { userId }
  });
  await storeStripeCustomerId(userId, customer.id);
  return customer.id;
}

app.post('/billing/create-checkout-session', async (req, res) => {
  try {
    const { userId, email } = req.body as { userId?: string; email?: string };
    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }
    const customerId = await getOrCreateCustomer(userId, email);
    const session = await stripe.checkout.sessions.create({
      mode: 'subscription',
      customer: customerId,
      line_items: [
        {
          price: priceId,
          quantity: 1
        }
      ],
      allow_promotion_codes: true,
      success_url: `${frontendUrl}/billing/success`,
      cancel_url: `${frontendUrl}/billing/canceled`,
      subscription_data: {
        metadata: { userId }
      },
      metadata: { userId }
    });

    res.json({ url: session.url });
  } catch (error) {
    console.error('Failed to create checkout session', error);
    res.status(500).json({ error: 'Failed to create checkout session' });
  }
});

app.post('/billing/customer-portal', async (req, res) => {
  try {
    const { userId } = req.body as { userId?: string };
    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }
    const userRef = await ensureUserDocument(userId);
    const snapshot = await userRef.get();
    const data = snapshot.data() as { stripeCustomerId?: string } | undefined;
    if (!data?.stripeCustomerId) {
      return res.status(400).json({ error: 'No Stripe customer for user' });
    }
    const session = await stripe.billingPortal.sessions.create({
      customer: data.stripeCustomerId,
      return_url: `${frontendUrl}/settings`
    });
    res.json({ url: session.url });
  } catch (error) {
    console.error('Failed to create customer portal session', error);
    res.status(500).json({ error: 'Failed to create customer portal session' });
  }
});

app.post(
  '/billing/webhook',
  express.raw({ type: 'application/json' }),
  async (req, res) => {
    if (!stripeWebhookSecret) {
      return res.status(400).send('Webhook secret not configured');
    }

    const signature = req.headers['stripe-signature'];
    let event: Stripe.Event;

    try {
      event = stripe.webhooks.constructEvent(req.body, signature as string, stripeWebhookSecret);
    } catch (err) {
      console.error('Webhook signature verification failed', err);
      return res.status(400).send(`Webhook Error: ${(err as Error).message}`);
    }

    try {
      switch (event.type) {
        case 'checkout.session.completed': {
          const session = event.data.object as Stripe.Checkout.Session;
          const userId = session.metadata?.userId;
          const customerId = session.customer?.toString();
          if (userId && customerId) {
            await storeStripeCustomerId(userId, customerId);
          }
          break;
        }
        case 'customer.subscription.created':
        case 'customer.subscription.updated': {
          const subscription = event.data.object as Stripe.Subscription;
          const customerId = subscription.customer?.toString();
          const periodEnd = subscription.current_period_end;
          let userId = subscription.metadata?.userId;
          if (!userId && typeof customerId === 'string') {
            const userDoc = await getUserByStripeCustomer(customerId);
            userId = userDoc?.id;
          }
          if (userId) {
            const active = subscription.status === 'active' || subscription.status === 'trialing';
            await updateSubscriptionStatus(userId, active, periodEnd);
          }
          break;
        }
        case 'customer.subscription.deleted': {
          const subscription = event.data.object as Stripe.Subscription;
          const customerId = subscription.customer?.toString();
          let userId = subscription.metadata?.userId;
          if (!userId && typeof customerId === 'string') {
            const userDoc = await getUserByStripeCustomer(customerId);
            userId = userDoc?.id;
          }
          if (userId) {
            await updateSubscriptionStatus(userId, false);
          }
          break;
        }
        default:
          break;
      }
      res.json({ received: true });
    } catch (error) {
      console.error('Error handling webhook event', error);
      res.status(500).send('Webhook handler error');
    }
  }
);

const port = Number(process.env.PORT ?? 3001);
app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
