const nodemailer = require('nodemailer');

/**
 * Configure the email transporter using environment variables.
 */
const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST || 'smtp.gmail.com',
  port: process.env.EMAIL_PORT || 587,
  secure: process.env.EMAIL_PORT == 465,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

/**
 * Sends a welcome email after registration.
 * Note: Actual verification is now handled by Firebase Auth on the client.
 */
const sendWelcomeEmail = async (toEmail, userName) => {
  const mailOptions = {
    from: `"QuickChat Team" <${process.env.EMAIL_USER}>`,
    to: toEmail,
    subject: 'Welcome to QuickChat! 🚀',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 10px;">
        <div style="text-align: center; margin-bottom: 20px;">
          <h1 style="color: #008069; margin: 0;">QuickChat</h1>
        </div>
        <div style="background-color: #f9f9f9; padding: 30px; border-radius: 8px;">
          <h2 style="color: #333; margin-top: 0;">Hi ${userName},</h2>
          <p style="color: #555; font-size: 16px; line-height: 1.6;">
            Welcome to <strong>QuickChat</strong>! We're thrilled to have you part of our community. 
          </p>
          <div style="text-align: center; margin: 40px 0;">
            <p style="color: #555;">Please verify your email through the link sent by Firebase to start chatting.</p>
          </div>
        </div>
        <div style="text-align: center; margin-top: 20px; color: #888; font-size: 12px;">
          <p>&copy; 2026 QuickChat Inc. All rights reserved.</p>
        </div>
      </div>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log('Welcome email sent to:', toEmail);
  } catch (error) {
    console.error('Error sending welcome email:', error);
  }
};

module.exports = { sendWelcomeEmail };
