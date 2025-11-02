import cron from 'node-cron';
import { query } from './index';
import { sendEmail } from './sendEmail/sendEmail';
import { logActivity } from './services/log.service';

console.log('🚀 Cron job service started...');

cron.schedule('0 0 * * *', async () => { // '*/1 * * * *' for testing every minute for production use '0 0 * * *'
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
        AND (g.next_deduction_date IS NOT NULL AND g.next_deduction_date <= CURDATE())
    `);

    if (goals.length === 0) {
      console.log('No active saving goals due for deduction today.');
      return;
    }
    console.log(`Found ${goals.length} goals to process...`);

    for (const goal of goals) {
      const {
        goal_id,
        user_id,
        wallet_id,
        goal_name,
        contribution_amount,
        wallet_balance,
        frequency,
        current_amount,
        target_amount
      } = goal;

      const balanceNum = parseFloat(wallet_balance);
      const contributionNum = parseFloat(contribution_amount);

      // เงินไม่พอ
      if (balanceNum < contributionNum) {
        console.warn(`⚠️ Wallet ${wallet_id} ไม่มีเงินพอหัก ${contributionNum}`);
        await logActivity({
            user_id: user_id,
            actor_id: null,
            actor_type: 'system',
            action: 'AUTODEDUCT_FAIL_INSUFFICIENT_FUNDS',
            table_name: 'wallet',
            record_id: wallet_id,
            description: `Auto-deduct failed for goal '${goal_name}': Insufficient funds.`
        });
        continue;
      }

      // ✅ หัก wallet
      await query(
        `UPDATE wallet 
         SET balance = balance - ?,
             updated_at = NOW()
         WHERE wallet_id = ?`,
        [contributionNum, wallet_id]
      );

      // ✅ เพิ่มยอดใน saving goal
      const newAmount = parseFloat(current_amount) + contributionNum;
      const newStatus = newAmount >= target_amount ? 'completed' : 'active';

      // ✅ กำหนดวันถัดไป
      let nextDate: Date | null = null;
      const now = new Date();
      if (newStatus === 'active') {
        if (frequency === 'daily') nextDate = new Date(now.setDate(now.getDate() + 1));
        else if (frequency === 'weekly') nextDate = new Date(now.setDate(now.getDate() + 7));
        else if (frequency === 'monthly') nextDate = new Date(now.setMonth(now.getMonth() + 1));
        // (ถ้า one-time หรือ completed, nextDate จะเป็น null)
      }

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
      const result: any = await query(
        `INSERT INTO saving_transactions 
         (user_id, wallet_id, goal_id, amount, status, transaction_date) 
         VALUES (?, ?, ?, ?, 'completed', NOW())`,
        [user_id, wallet_id, goal_id, contributionNum]
      );
      const newTxId = result.insertId;

      await logActivity({
          user_id: user_id,
          actor_id: null,
          actor_type: 'system',
          action: 'CREATE_SAVING_AUTODEDUCT',
          table_name: 'saving_transactions',
          record_id: newTxId,
          description: `Auto-deduct success for goal '${goal_name}': ${contributionNum}.`,
          new_value: { goal_id, amount: contributionNum, newAmount, newStatus }
      });

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
  } catch (err: any) {
    await logActivity({
        user_id: null,
        actor_id: null,
        actor_type: 'system',
        action: 'AUTODEDUCT_EXCEPTION',
        description: `Cron job auto-deduct failed. Error: ${err.message}`,
        new_value: { error: err.stack }
    });
    console.error('❌ Cron job error:', err);
  }
});