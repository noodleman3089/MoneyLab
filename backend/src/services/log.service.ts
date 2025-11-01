// ในไฟล์ (ใหม่) src/services/log.service.ts
import { Request } from 'express';
import { query } from '../index'; // import ฟังก์ชัน query ของคุณ

// 1. สร้าง Interface สำหรับ Options
interface LogOptions {
  user_id: number; // 👈 User ที่ "ถูก" กระทำ (Affected User)
  action: string; // 👈 การกระทำ เช่น 'LOGIN_SUCCESS', 'UPDATE_PROFILE'
  
  // Actor: ผู้กระทำ (อาจจะเป็น user คนเดียวกัน, admin, หรือ system)
  actor_id?: number | null;
  actor_type?: 'user' | 'admin' | 'system' | 'api';

  // Request Details (ถ้ามี)
  req?: Request;

  // Context: รายละเอียดว่าทำอะไร ที่ไหน
  table_name?: string | null;
  record_id?: string | number | null;
  description?: string | null;

  // Data Changes: สำหรับเก็บข้อมูลก่อน-หลัง
  old_value?: object | null;
  new_value?: object | null;
  changed_fields?: object | null; // (ขั้นสูง)
}

/**
 * ฟังก์ชันกลางสำหรับบันทึก Log กิจกรรมต่างๆ ลงตาราง `log`
 */
export async function logActivity(options: LogOptions): Promise<void> {
  // 2. แยกค่าและตั้งค่าเริ่มต้น
  const {
    user_id,
    action,
    actor_id = null, // ถ้าไม่ส่งมา ให้เป็น null
    actor_type = 'user', // ค่าเริ่มต้น
    req = null, // รับ request object มา (ถ้ามี)
    table_name = null,
    record_id = null,
    description = null,
    old_value = null,
    new_value = null,
    changed_fields = null,
  } = options;

  console.log('--- 1. logActivity CALLED ---');
  console.log('--- ACTION:', options.action);

  // 3. ดึง IP และ User Agent จาก Request (ถ้ามี)
  const ip_address = req ? req.ip : null;
  const user_agent = req ? req.get('User-Agent') : null;

  // 4. สร้าง SQL Query
  const sql = `
    INSERT INTO log 
      (user_id, actor_id, actor_type, table_name, record_id, 
       action, old_value, new_value, changed_fields, 
       ip_address, user_agent, description)
    VALUES 
      (?, ?, ?, ?, ?, ?, ?, ?, ?, INET6_ATON(?), ?, ?)
  `;

  // ❗️ หมายเหตุ: INET6_ATON(?) ใช้สำหรับแปลง IP (v6) เป็น INT เพื่อเก็บใน VARBINARY(16)
  // ถ้าคุณใช้ IPv4 หรือต้องการเก็บเป็น String ให้เปลี่ยน schema และ query ครับ
  // สำหรับความง่าย อาจใช้ VARCHAR(45) แทน VARBINARY(16) และไม่ต้องใช้ INET6_ATON
  
  const params = [
    user_id,
    actor_id,
    actor_type,
    table_name,
    record_id ? String(record_id) : null,
    action,
    old_value ? JSON.stringify(old_value) : null,
    new_value ? JSON.stringify(new_value) : null,
    changed_fields ? JSON.stringify(changed_fields) : null,
    ip_address,
    user_agent,
    description
  ];

  console.log('--- 2. EXECUTING SQL ---', sql.substring(0, 100) + '...');
  console.log('--- PARAMS:', params);

  // 5. บันทึก Log และดักจับ Error
  try {
    await query(sql, params);
    console.log('--- 3. LOG INSERTED SUCCESSFULLY! ---');
  } catch (err) {
    console.error('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
    console.error('--- ❌ CRITICAL: FAILED TO WRITE LOG ---');
    console.error(err);
    console.error('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
    console.error('CRITICAL: Failed to write to log table:', err);
  }
}