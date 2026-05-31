import "@supabase/functions-js/edge-runtime.d.ts";

import { getWelcomeEmailHtml } from "../_shared/templates.ts";

const brevoApiKey = Deno.env.get('BREVO_API_KEY');

interface UserRecord {
  uid: string
  email: string
  name: string
}

interface WebhookPayload {
  type: 'INSERT' | 'UPDATE' | 'DELETE'
  table: string
  record: UserRecord
  schema: 'public'
}

Deno.serve(async (req: Request) => {
  try {
    const payload: WebhookPayload = await req.json()

    // Only handle INSERTs (new users)
    if (payload.type !== 'INSERT') {
      return new Response(JSON.stringify({ message: 'Not an insert event' }), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const { email, name } = payload.record

    if (!email) {
      return new Response(JSON.stringify({ message: 'No email provided' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const html = getWelcomeEmailHtml(name);

    if (!brevoApiKey) {
      throw new Error('BREVO_API_KEY is not set');
    }

    // Add user to Brevo Contacts
    try {
      const contactResponse = await fetch('https://api.brevo.com/v3/contacts', {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'api-key': brevoApiKey,
        },
        body: JSON.stringify({
          email: email,
          attributes: name ? { FIRSTNAME: name } : undefined,
          updateEnabled: true
        })
      });

      if (!contactResponse.ok) {
        const contactError = await contactResponse.text();
        console.error('Brevo Add Contact Error:', contactError);
        // We don't throw here to ensure the welcome email still attempts to send
      } else {
        console.log(`Successfully added ${email} to Brevo contacts.`);
      }
    } catch (e) {
      console.error('Failed to add contact to Brevo:', e);
    }

    const response = await fetch('https://api.brevo.com/v3/smtp/email', {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'api-key': brevoApiKey,
      },
      body: JSON.stringify({
        sender: {
          name: 'Lunara',
          // Replace with your verified Brevo sender email
          email: 'himanksharma8434@gmail.com' 
        },
        to: [
          { email: email }
        ],
        subject: 'Welcome to Lunara! 🌙',
        htmlContent: html,
      })
    });

    if (!response.ok) {
      const errorData = await response.text();
      console.error('Brevo API Error:', errorData);
      throw new Error(`Brevo API Error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();

    return new Response(JSON.stringify(data), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error);
    console.error('send_welcome_email failed:', message);
    return new Response(JSON.stringify({ error: message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
