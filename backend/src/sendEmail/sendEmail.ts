import nodemailer from 'nodemailer';

export async function sendEmail(
  to: string,
  subject: string,
  text: string,
  html?: string
) {
  try {
    const transporter = nodemailer.createTransport({
      host: process.env.EMAIL_HOST,
      port: Number(process.env.EMAIL_PORT) || 587,
      secure: process.env.EMAIL_PORT === '465', // true ถ้าใช้ SSL (port 465)
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });

    const info = await transporter.sendMail({
      from: `"Money Lab" <${process.env.EMAIL_USER}>`, // ชื่อผู้ส่ง
      to,
      subject,
      text,
      html,
    });

    console.log('✅ Email sent:', info.messageId);
    return info; // เผื่อโค้ดอื่นจะใช้ messageId / response ต่อ
  } catch (err) {
    console.error('❌ Failed to send email:', err);
    throw err;
  }
}