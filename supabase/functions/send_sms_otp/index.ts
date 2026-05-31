import "@supabase/functions-js/edge-runtime.d.ts";
import { Webhook } from "standardwebhooks";

const brevoApiKey = Deno.env.get('BREVO_API_KEY');
// Set this secret if you want to verify the webhook signature
const hookSecret = Deno.env.get('SEND_SMS_HOOK_SECRET');

interface WebhookPayload {
  user: {
    id: string;
    phone: string;
  };
  sms_data: {
    token: string;
    token_hash: string;
  };
}

Deno.serve(async (req: Request) => {
  try {
    if (req.method !== 'POST') {
      return new Response('not allowed', { status: 400 });
    }

    const payloadText = await req.text();
    const headers = Object.fromEntries(req.headers);
    let payload: WebhookPayload;
    
    // Use standardwebhooks to verify the webhook payload if secret is set
    if (!hookSecret) {
      console.warn("SEND_SMS_HOOK_SECRET is not set, bypassing webhook signature verification for development.");
      payload = JSON.parse(payloadText) as WebhookPayload;
    } else {
      const wh = new Webhook(hookSecret.replace('v1,whsec_', ''));
      try {
        payload = wh.verify(payloadText, headers) as WebhookPayload;
      } catch (err: unknown) {
        throw new Error(`Webhook signature verification failed: ${err instanceof Error ? err.message : String(err)}`);
      }
    }

    const phone = payload.user?.phone;
    const token = payload.sms_data?.token;

    if (!phone || !token) {
      return new Response(JSON.stringify({ message: 'No phone number or token provided' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    if (!brevoApiKey) {
      throw new Error('BREVO_API_KEY is not set');
    }

    const response = await fetch('https://api.brevo.com/v3/transactionalSMS/sms', {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'api-key': brevoApiKey,
      },
      body: JSON.stringify({
        type: 'transactional',
        sender: 'Lunara', // Maximum 11 characters, alphanumeric
        recipient: phone, // Must be in E.164 format with country code (e.g. +1234567890)
        content: `Your Lunara verification code is: ${token}`,
      })
    });

    if (!response.ok) {
      const errorData = await response.text();
      console.error('Brevo API Error:', errorData);
      throw new Error(`Brevo SMS API Error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();

    return new Response(JSON.stringify(data), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error);
    console.error('send_sms_otp failed:', message);
    return new Response(JSON.stringify({ error: message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});
