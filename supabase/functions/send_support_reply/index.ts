import "@supabase/functions-js/edge-runtime.d.ts";
import { getSupportReplyEmailHtml } from "../_shared/templates.ts";
// @ts-ignore
import nodemailer from "npm:nodemailer";

declare const Deno: any;

const smtpUser = Deno.env.get('SMTP_USER') || 'lunarahealthtracker@gmail.com';
const smtpPass = Deno.env.get('SMTP_PASS') || 'xuskyrfzptsyjqvg';

interface SupportTicketRecord {
  id: string;
  created_at: string;
  user_id: string | null;
  email: string;
  category: string;
  message: string;
  ai_reply: string | null;
  status: string;
}

interface WebhookPayload {
  type: 'INSERT' | 'UPDATE' | 'DELETE';
  table: string;
  record: SupportTicketRecord;
  old_record?: SupportTicketRecord;
  schema: 'public';
}

Deno.serve(async (req: Request) => {
  try {
    const payload: WebhookPayload = await req.json();

    // We only trigger when a status becomes 'replied' or 'replied_by_ai'
    const newRecord = payload.record;
    const oldRecord = payload.old_record;

    const isInsertReplied = payload.type === 'INSERT' && 
      (newRecord.status === 'replied_by_ai' || newRecord.status === 'replied');

    const isUpdateReplied = payload.type === 'UPDATE' && 
      (newRecord.status === 'replied_by_ai' || newRecord.status === 'replied') &&
      (oldRecord?.status !== 'replied_by_ai' && oldRecord?.status !== 'replied');

    if (!isInsertReplied && !isUpdateReplied) {
      return new Response(JSON.stringify({ message: 'No action needed: Status is not replied, or email was already sent.' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const email = newRecord.email;
    const message = newRecord.message;
    const aiReply = newRecord.ai_reply;

    if (!email) {
      return new Response(JSON.stringify({ message: 'No email address on record.' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    if (!aiReply) {
      return new Response(JSON.stringify({ message: 'No reply content to send.' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const html = getSupportReplyEmailHtml(message, aiReply);

    // Create a transporter using Gmail SMTP credentials
    const transporter = nodemailer.createTransport({
      host: 'smtp.gmail.com',
      port: 587,
      secure: false, // true for 465, false for other ports
      auth: {
        user: smtpUser,
        pass: smtpPass,
      },
    });

    console.log(`Sending email via Gmail SMTP to ${email}...`);

    const info = await transporter.sendMail({
      from: `"Lunara Support" <${smtpUser}>`,
      to: email,
      subject: `[Lunara Support] Reply to your support ticket`,
      html: html,
    });

    console.log('Email sent successfully:', info.messageId);

    // ─── SMS NOTIFICATION FOR HIGH PRIORITY PREMIUM USERS ───
    const isHighPriority = message.includes('[PRIORITY: HIGH]');
    const phoneMatch = message.match(/\[USER_PHONE:\s*([^\]]+)\]/);
    const phone = phoneMatch ? phoneMatch[1] : null;

    if (isHighPriority && phone && isUpdateReplied && newRecord.status === 'replied') {
      const brevoApiKey = Deno.env.get('BREVO_API_KEY');
      if (brevoApiKey) {
        try {
          console.log(`Sending SMS to high priority user at ${phone}...`);
          const smsResponse = await fetch('https://api.brevo.com/v3/transactionalSMS/sms', {
            method: 'POST',
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'api-key': brevoApiKey,
            },
            body: JSON.stringify({
              type: 'transactional',
              sender: 'Lunara', 
              recipient: phone, 
              content: `Lunara Support: We have replied to your high priority ticket. Please check your email for the detailed response.`,
            })
          });

          if (!smsResponse.ok) {
            console.error('Brevo SMS Error:', await smsResponse.text());
          } else {
            console.log('SMS sent successfully');
          }
        } catch (smsError) {
          console.error('Failed to send SMS:', smsError);
        }
      } else {
         console.warn('BREVO_API_KEY is not set, skipping SMS');
      }
    }

    return new Response(JSON.stringify({ message: 'Email sent successfully', messageId: info.messageId }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error);
    console.error('send_support_reply failed:', message);
    return new Response(JSON.stringify({ error: message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});
