import cron from 'node-cron';
import { query } from './index';
import { sendEmail } from './sendEmail/sendEmail';

console.log('🚀 Cron job service started...');

/**
 * 🕒 Job: ตรวจรอบการออมทุกวันตอนเที่ยงคืน
 * - หักเงินจาก wallet ตาม contribution_amount
 * - อัปเดต saving_goals.current_amount
 * - อัปเดต totalSavingOut ใน wallet
 * - คำนวณวันถัดไปตาม frequency
 */
cron.schedule('*/1 * * * *', async () => { // '*/1 * * * *' for testing every minute for production use '0 0 * * *'
  console.log('⏰ Running auto saving deduction job...');

  try {
    const goals: any[] = await query(`
      SELECT g.goal_id, g.user_id, g.wallet_id, g.goal_name,
             g.contribution_amount, g.frequency,
             g.current_amount, g.target_amount,
             w.balance AS wallet_balance
      FROM saving_goals g
      JOIN wallet w ON g.wallet_id = w.wallet_id
      WHERE g.status = 'active'
    `);

    if (goals.length === 0) {
      console.log('ℹ️ No active saving goals found.');
      return;
    }

    for (const goal of goals) {
      const {
        goal_id,
        wallet_id,
        goal_name,
        contribution_amount,
        wallet_balance,
        frequency,
        current_amount,
        target_amount
      } = goal;

      // ✅ ตรวจรอบตาม frequency
      const now = new Date();
      let shouldDeduct = false;

      switch (frequency) {
        case 'daily': shouldDeduct = true; break;
        case 'weekly': shouldDeduct = now.getDay() === 1; break; // ทุกวันจันทร์
        case 'monthly': shouldDeduct = now.getDate() === 1; break; // ทุกวันที่ 1
        case 'one-time': shouldDeduct = true; break;
      }

      if (!shouldDeduct) continue;

      const balanceNum = parseFloat(wallet_balance);
      const contributionNum = parseFloat(contribution_amount);

      // ❌ เงินไม่พอ
      if (balanceNum < contributionNum) {
        console.warn(`⚠️ Wallet ${wallet_id} ไม่มีเงินพอหัก ${contributionNum}`);
        continue;
      }

      // ✅ หัก wallet
      await query(
        `UPDATE wallet 
         SET balance = balance - ?,
             updated_at = NOW()
         WHERE wallet_id = ?`,
        [contribution_amount, wallet_id]
      );

      // ✅ เพิ่มยอดใน saving goal
      const newAmount = parseFloat(current_amount) + parseFloat(contribution_amount);
      const newStatus = newAmount >= target_amount ? 'completed' : 'active';

      // ✅ กำหนดวันถัดไป
      let nextDate: Date | null = null;
      if (frequency === 'daily') nextDate = new Date(Date.now() + 24 * 60 * 60 * 1000);
      else if (frequency === 'weekly') nextDate = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
      else if (frequency === 'monthly') nextDate = new Date(new Date().setMonth(new Date().getMonth() + 1));

      // ✅ อัปเดต goal
      await query(
        `UPDATE saving_goals 
         SET current_amount = ?, 
             status = ?, 
             next_deduction_date = ?, 
             completed_at = CASE WHEN ? = 'completed' THEN NOW() ELSE completed_at END,
             updated_at = NOW()
         WHERE goal_id = ?`,
        [newAmount, newStatus, nextDate, newStatus, goal_id]
      );

      await query(
        `INSERT INTO saving_transactions 
        (user_id, wallet_id, goal_id, amount, status, transaction_date) 
        VALUES (?, ?, ?, ?, 'completed', NOW())`,
        [goal.user_id, wallet_id, goal_id, contribution_amount]
      );

      await query(
        `INSERT INTO notifications 
          (user_id, type, title, message, reference_type, reference_id)
        VALUES (?, ?, ?, ?, ?, ?)`,
        [
          goal.user_id,
          'success',
          'หักเงินออมอัตโนมัติสำเร็จ',
          `ระบบได้หักเงิน ${contributionNum.toFixed(2)} บาท
          เข้าสู่เป้าหมาย "${goal.goal_name}" แล้ว ✅`,
          'goal',
          goal.goal_id
        ]
      );

      // ✅ (Option) ดึง email ของผู้ใช้แล้วส่งอีเมล
      const [user]: any = await query('SELECT email FROM users WHERE user_id = ?', [goal.user_id]);
      if (user?.email) {
        await sendEmail(
          user.email,
          '📉 หักเงินออมอัตโนมัติสำเร็จ',
          `<h3>📉 หักเงินออมอัตโนมัติสำเร็จ</h3>
          <p>ระบบได้หักเงินจำนวน ${contributionNum.toFixed(2)} บาท
          เข้าสู่เป้าหมาย "${goal.goal_name}" แล้วเรียบร้อย ✅</p>`
        );
      }

    console.log(`✅ Goal "${goal_name}" updated (+${contribution_amount}), wallet_id=${wallet_id}`);
    }
    console.log('✅ Cron job finished successfully.');
  } catch (err) {
    console.error('❌ Cron job error:', err);
  }
});