export const getWelcomeEmailHtml = (name: string): string => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0;padding:0;background-color:#FDF2F4;font-family:'Segoe UI',Roboto,Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#FDF2F4;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="480" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(216,64,91,0.08);">
          <tr>
            <td style="background:linear-gradient(135deg,#FF8989,#D8405B);padding:40px;text-align:center;">
              <h1 style="margin:0;color:#ffffff;font-size:32px;font-weight:700;letter-spacing:-0.5px;">🌙 Lunara</h1>
              <p style="margin:12px 0 0;color:rgba(255,255,255,0.9);font-size:16px;">Your Cycle, Your Power</p>
            </td>
          </tr>
          <tr>
            <td style="padding:48px 40px;">
              <h2 style="margin:0 0 16px;color:#3E2723;font-size:24px;font-weight:600;">Welcome, ${name || 'Friend'}! 💖</h2>
              <p style="margin:0 0 24px;color:#8D6E63;font-size:16px;line-height:1.6;">We are absolutely thrilled to have you join the Lunara community.</p>
              <p style="margin:0 0 32px;color:#8D6E63;font-size:16px;line-height:1.6;">Lunara is your beautifully designed, private space to track your cycle, understand your body, and embrace your wellness journey.</p>
              
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center">
                    <a href="lunara://" style="display:inline-block;background:linear-gradient(135deg,#FF8989,#D8405B);color:#ffffff;text-decoration:none;padding:16px 40px;border-radius:12px;font-size:16px;font-weight:600;letter-spacing:0.3px;box-shadow:0 4px 12px rgba(216,64,91,0.2);">Open Lunara Now</a>
                  </td>
                </tr>
              </table>
              <p style="margin:32px 0 0;color:#BDBDBD;font-size:14px;line-height:1.6;text-align:center;">If you have any questions, just reply to this email. We're here for you!</p>
            </td>
          </tr>
          <tr>
            <td style="background:#FFF9FA;padding:24px;text-align:center;border-top:1px solid #FDF2F4;">
              <p style="margin:0;color:#A1887F;font-size:13px;">© ${new Date().getFullYear()} Lunara · Made with 💖</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
`;

export const getPasswordResetEmailHtml = (resetUrl: string): string => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0;padding:0;background-color:#FDF2F4;font-family:'Segoe UI',Roboto,Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#FDF2F4;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="480" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(216,64,91,0.08);">
          <tr>
            <td style="background:linear-gradient(135deg,#FF8989,#D8405B);padding:32px 40px;text-align:center;">
              <h1 style="margin:0;color:#ffffff;font-size:28px;font-weight:700;letter-spacing:-0.5px;">🌙 Lunara</h1>
              <p style="margin:8px 0 0;color:rgba(255,255,255,0.9);font-size:14px;">Your Cycle, Your Power</p>
            </td>
          </tr>
          <tr>
            <td style="padding:40px;">
              <h2 style="margin:0 0 8px;color:#3E2723;font-size:22px;font-weight:600;">Reset Your Password 🔐</h2>
              <p style="margin:0 0 24px;color:#8D6E63;font-size:15px;line-height:1.6;">We received a request to reset your password. Click the button below to choose a new one securely.</p>
              
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center">
                    <a href="${resetUrl}" style="display:inline-block;background:linear-gradient(135deg,#FF8989,#D8405B);color:#ffffff;text-decoration:none;padding:14px 36px;border-radius:12px;font-size:16px;font-weight:600;letter-spacing:0.3px;">Reset Password</a>
                  </td>
                </tr>
              </table>
              <p style="margin:28px 0 0;color:#BDBDBD;font-size:12px;line-height:1.6;text-align:center;">If you didn't request a password reset, you can safely ignore this email. Your password will remain unchanged.</p>
            </td>
          </tr>
          <tr>
            <td style="background:#FFF9FA;padding:20px;text-align:center;border-top:1px solid #FDF2F4;">
              <p style="margin:0;color:#A1887F;font-size:12px;">© ${new Date().getFullYear()} Lunara · Made with 💖</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
`;
