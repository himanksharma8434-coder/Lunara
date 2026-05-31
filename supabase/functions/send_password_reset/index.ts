import "@supabase/functions-js/edge-runtime.d.ts";
import { getPasswordResetEmailHtml } from "../_shared/templates.ts";

declare const Deno: any;

interface WebhookPayload {
  user: {
    email: string;
  };
  email_data: {
    token_hash: string;
    redirect_to: string;
    token: string;
  };
}

Deno.serve(async (req: Request) => {
  try {
    if (req.method !== 'POST') {
      return new Response('not allowed', { status: 400 });
    }

    const payloadText = await req.text();
    let payload: WebhookPayload;
    
    console.log('Parsing payload text...');
    payload = JSON.parse(payloadText) as WebhookPayload;

    const email = payload.user?.email;
    const token = payload.email_data?.token;

    if (!email || !token) {
      return new Response(JSON.stringify({ message: 'No email or token provided' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Construct the actual redirect URL based on app deep link
    const redirectUrl = `io.supabase.lunara://login-callback/#access_token=${token}&type=recovery`;
    const html = getPasswordResetEmailHtml(redirectUrl);

    console.log(`Sending email via Resend to ${email}...`);

    const resendApiKey = Deno.env.get('RESEND_API_KEY') || 're_Cptm7mib_5iyKMqyoF13qCigwMNowmvDq';

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${resendApiKey}`
      },
      body: JSON.stringify({
        from: 'lunarahealthtracker@gmail.com',
        to: email,
        subject: "Reset Password Request - Lunara 🌙",
        html: html,
      })
    });

    if (!res.ok) {
      const errText = await res.text();
      throw new Error(`Resend API error (${res.status}): ${errText}`);
    }

    const resData = await res.json();
    console.log("Email sent successfully via Resend!", resData);

    return new Response(JSON.stringify({ message: "Email sent successfully", data: resData }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error);
    console.error('send_password_reset failed:', message);
    return new Response(JSON.stringify({ error: message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});

