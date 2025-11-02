import express, { Request, Response } from 'express';
import multer from 'multer';
import { spawn } from 'child_process';
import axios from 'axios'; // 1. เพิ่ม axios สำหรับเรียก API ภายใน
import path from 'path';
import fs from 'fs';
import { query } from '../index';
import { authenticateToken } from '../middlewares/authMiddleware';
import { sendEmail } from '../sendEmail/sendEmail';

const routerOCR = express.Router();

const uploadDir = path.resolve(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

// 📂 ตั้งค่า multer
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    const uniqueName = `${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`;
    cb(null, uniqueName);
  }
});
const upload = multer({ storage });

// 📌 [ขั้นตอนที่ 1] OCR route: รับรูป, ทำ OCR, และเดาหมวดหมู่
routerOCR.post(
  '/',
  authenticateToken,
  upload.single('receipt'),
  async (req: Request, res: Response) => {
    if (!req.file) {
      return res.status(400).json({ status: false, message: 'No file uploaded' });
    }

    const imagePath = path.resolve(req.file.path);
    const scriptPath = path.resolve(__dirname, '../../model/ocr_module/extract_receipt.py');

    console.log('🧠 Python script path:', scriptPath);
    console.log('🖼️ Image path:', imagePath);

    try {
      const pythonProcess = spawn('python', [scriptPath, imagePath]);

      let stdoutData = '';
      let stderrData = '';

      pythonProcess.stdout.on('data', (chunk) => (stdoutData += chunk.toString()));
      pythonProcess.stderr.on('data', (err) => (stderrData += err.toString()));

      pythonProcess.on('close', async (code) => {
        if (stderrData.trim()) console.error('⚠️ OCR stderr:', stderrData);
        if (code !== 0) {
          return res.status(500).json({
            status: false,
            message: 'OCR process failed',
            error: stderrData || 'Unknown error',
          });
        }

        try {
          const cleaned = stdoutData
            .split('\n')
            .map((line) => line.trim())
            .filter((line) => line.startsWith('{') || line.startsWith('['))
            .pop();

          if (!cleaned) {
            console.error('❌ OCR output did not contain JSON:', stdoutData);
            return res.status(500).json({ status: false, message: 'Invalid OCR output (no JSON found)' });
          }

          const ocrResult = JSON.parse(cleaned);
          const userId = (req as any).user.user_id;

          // --- [แผนใหม่] ---
          // 2. เรียกใช้ Prediction Service เพื่อเดาหมวดหมู่
          let predictionResult = null;
          if (ocrResult.receiver_name) {
            try {
              const predictionResponse = await axios.post('http://127.0.0.1:5001/api/predict', {
                user_id: userId,
                transaction: {
                  receiver_name: ocrResult.receiver_name,
                  amount: ocrResult.amount || 0,
                  // สามารถส่งข้อมูลอื่นๆ ที่มีประโยชน์ต่อการทำนายได้ที่นี่
                }
              });
              predictionResult = predictionResponse.data;
              console.log('🤖 ML Prediction result:', predictionResult);
            } catch (predictionError: any) {
              console.error('❌ ML Prediction service failed:', predictionError.message);
              // ไม่ต้องหยุดการทำงาน แค่ไม่มีผลการเดา
            }
          }

          // 3. ส่งผลลัพธ์ทั้งหมดกลับไปให้ Frontend
          return res.status(200).json({
            status: true,
            message: 'OCR and prediction completed. Waiting for user confirmation.',
            ocr_data: ocrResult,
            prediction_data: predictionResult,
            receipt_image_url: req.file ? `uploads/${req.file.filename}` : null, // ส่ง URL รูปไปด้วย
          });

          /*
          // --- [โค้ดเก่า] --- ส่วนลอจิกการบันทึกทั้งหมดจะถูกย้ายไปที่ Endpoint ใหม่
          const result = ocrResult;

          if (!result.amount || !result.date) {
            return res.status(400).json({
              status: false,
              message: 'ข้อมูลไม่ครบถ้วนจาก OCR',
              raw: result,
            });
          }

          // ✅ ฟังก์ชันแปลงวันที่
          function parseThaiDate(thaiDate: string): string | null {
            if (!thaiDate) return null;
            const cleanDate = thaiDate.replace(/\s+/g, ' ').replace('น.', '').trim();
            const months: Record<string, string> = {
              'ม.ค.': '01', 'ก.พ.': '02', 'มี.ค.': '03', 'เม.ย.': '04',
              'พ.ค.': '05', 'มิ.ย.': '06', 'ก.ค.': '07', 'ส.ค.': '08',
              'ก.ย.': '09', 'ต.ค.': '10', 'พ.ย.': '11', 'ธ.ค.': '12'
            };
            const regex = /(\d{1,2})\s*([ก-ฮ]{2,3}\.)\s*(\d{2,4})(?:\s+(\d{1,2}:\d{2}))?/;
            const match = cleanDate.match(regex);
            if (!match) return null;

            let [_, day, monthTh, year, time] = match;
            const month = months[monthTh] || '01';
            let y = parseInt(year, 10);
            if (y > 2400) y -= 543;
            else if (y < 100) y += 2500 - 543;
            const dateStr = `${y}-${month}-${day.padStart(2, '0')}`;
            return time ? `${dateStr} ${time}:00` : `${dateStr} 00:00:00`;
          }

          const transactionDate =
            parseThaiDate(result.date) ||
            new Date().toISOString().slice(0, 19).replace('T', ' ');

          // ✅ ความมั่นใจต่ำเกินไป
          if (result.overall_confidence < 0.4) {
            return res.status(400).json({
              status: false,
              message: 'รูปใบเสร็จไม่ถูกต้อง หรือความมั่นใจต่ำกว่าเกณฑ์ (0.4)',
              raw: result,
            });
          }

          // ✅ ตรวจสอบชื่อผู้รับ (จำเป็น)
          if (!result.receiver_name) {
            return res.status(400).json({
              status: false,
              message: 'ไม่พบชื่อผู้รับ กรุณาใส่ชื่อผู้รับก่อนบันทึก',
              require_receiver_name: true,
              raw: result,
            });
          }

          let categoryId: number | null = req.body.category_id || null;

          // ✅ กำหนด type โดยอิงจาก category_type (ถ้ามี) แทนการเดาเอง
          let transactionType = 'expense'; // ค่าเริ่มต้น
          if (categoryId) {
            const cat = await query(
              'SELECT category_type FROM category WHERE category_id = ? LIMIT 1',
              [categoryId]
            );
            if (cat.length > 0) {
              transactionType = cat[0].category_type;
            }
          } else {
            // fallback ถ้าไม่มี category_id ให้ดูจาก amount
            transactionType = result.amount > 0 ? 'income' : 'expense';
          }

          // ✅ ถ้าไม่มี category_id → ตรวจว่าผู้รับนี้เคยอยู่ในระบบไหม
          if (!categoryId) {
            const prev = await query(
              `SELECT t.category_id, c.category_type, c.category_name
               FROM transactions t
               LEFT JOIN category c ON t.category_id = c.category_id
               WHERE t.receiver_name = ?
               ORDER BY t.created_at DESC
               LIMIT 1`,
              [result.receiver_name]
            );

            if (prev.length === 0) {
              console.warn(`🆕 ผู้รับใหม่ (${result.receiver_name}) → ต้องเลือกหมวดหมู่เอง`);
              return res.status(200).json({
                status: false,
                message: `ชื่อผู้รับ "${result.receiver_name}" ยังไม่มีในระบบ กรุณาเลือกหมวดหมู่`,
                require_category_selection: true,
                raw_data: result,
              });
            }

            // มีผู้รับนี้แล้ว
            const prevCategory = prev[0];
            if (prevCategory.category_type !== transactionType) {
              const fallback = await query(
                `SELECT category_id FROM category WHERE category_type = ? 
                 AND (category_name = 'รายรับเบ็ดเตล็ด' OR category_name = 'อื่นๆ') LIMIT 1`,
                [transactionType]
              );
              categoryId = fallback[0]?.category_id || null;
              console.log(`⚠️ ปรับหมวดหมู่ให้ตรงกับประเภท ${transactionType}`);
            } else {
              categoryId = prevCategory.category_id;
            }
          }
          let walletId: number | null = null;
          const wallet = await query(
          'SELECT wallet_id FROM wallet WHERE user_id = ? LIMIT 1',
          [userId]
          );
          if (wallet.length === 0) {
            // 🆕 ถ้ายังไม่มี wallet ให้สร้างใหม่
            const createWallet = await query(
              'INSERT INTO wallet (user_id, wallet_name, currency, balance) VALUES (?, ?, ?, 0)',
              [userId, 'Main Wallet', 'THB']
            );
            walletId = createWallet.insertId;
            console.log(`🆕 สร้าง wallet ใหม่สำหรับ user_id=${userId} → wallet_id=${walletId}`);
          } else {
            walletId = wallet[0].wallet_id;
          }

          await query(
            `INSERT INTO transactions 
            (user_id, wallet_id ,category_id, type, amount, fee, sender_name, receiver_name,
            reference_id, payment_source, data_source, confidence, transaction_date, receipt_image_url)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'ocr', ?, ?, ?)`,
            [
              userId,
              walletId,
              categoryId,
              transactionType, // ✅ ใช้ค่าที่คำนวณจาก category_type
              result.amount || 0,
              result.fee || 0,
              result.sender_name || null,
              result.receiver_name || null,
              result.reference_id || null,
              result.source?.brand || 'unknown',
              result.overall_confidence || 0,
              transactionDate,
              req.file ? `uploads/${req.file.filename}` : null,
            ]
          );

          if (transactionType === 'expense') {
            const today = new Date().toISOString().slice(0, 10);

            // ✅ ดึง daily_budget ของวันนี้
            const [budget]: any = await query(
              `SELECT budget_id, target_spend, 
                  (SELECT COALESCE(SUM(amount),0) 
                  FROM transactions 
                  WHERE user_id = ? AND type = 'expense' 
                  AND DATE(transaction_date) = ?) AS total_spent
              FROM daily_budget 
              WHERE user_id = ? AND budget_date = ? 
              LIMIT 1`,
              [userId, today, userId, today]
            );

            if (budget) {
              const {budget_id} = budget;
              const target_spend = parseFloat(budget.target_spend ?? 0);
              const total_spent = parseFloat(budget.total_spent ?? 0);
              const percentUsed = target_spend > 0 ? (total_spent / target_spend) * 100 : 0;
              
              // ✅ ตรวจว่าเพิ่งข้าม 50% หรือ 100%
              let shouldNotify = false;
              let notifyType: 'warning' | 'error' | null = null;
              let title = '';
              let message = '';

              if (percentUsed >= 100) {
                shouldNotify = true;
                notifyType = 'error';
                title = 'งบวันนี้หมดแล้ว!';
                message = `คุณใช้จ่ายครบงบประจำวันที่ ${today} แล้ว (${total_spent.toFixed(2)} / ${target_spend.toFixed(2)} บาท)`;
              } else if (percentUsed >= 50) {
                shouldNotify = true;
                notifyType = 'warning';
                title = 'ใกล้เต็มงบวันนี้แล้ว!';
                message = `คุณใช้จ่ายไปแล้ว ${percentUsed.toFixed(0)}% ของงบวันนี้ (${total_spent.toFixed(2)} / ${target_spend.toFixed(2)} บาท)`;
              }

              if (shouldNotify && notifyType) {
                // ✅ บันทึก notification ลง DB
                await query(
                  `INSERT INTO notifications 
                  (user_id, type, title, message, reference_type, reference_id)
                  VALUES (?, ?, ?, ?, 'daily_budget', ?)`,
                  [userId, notifyType, title, message, budget_id]
                );

                // ✅ ดึงอีเมลผู้ใช้
                const [userInfo]: any = await query(
                  `SELECT email, username FROM users WHERE user_id = ? LIMIT 1`,
                  [userId]
                );

                if (userInfo?.email) {
                  await sendEmail(
                    userInfo.email,
                    title,
                    message,
                    `
                      <div style="font-family:sans-serif;line-height:1.6">
                        <h3>${title}</h3>
                        <p>สวัสดีคุณ ${userInfo.username || ''},</p>
                        <p>${message}</p>
                        <hr/>
                        <small>ระบบแจ้งเตือนจาก MoneyLab</small>
                      </div>
                    `
                  );
                  console.log(`📧 Budget alert sent to ${userInfo.email}`);
                }
              }
            }
          }


          res.json({
            status: true,
            message: 'OCR data processed and stored successfully',
            data: result,
          });
          */

        } catch (err) {
          console.error('❌ Failed to parse or save OCR result:', err);
          res.status(500).json({ status: false, message: 'Failed to save OCR result' });
        }
      }); // end of pythonProcess.on('close')
    } catch (err) {
      console.error('💥 Server error:', err);
      res.status(500).json({ status: false, message: 'Server error' });
    }
  }
);

// 📌 [ขั้นตอนที่ 2] Confirmation route: รับข้อมูลที่ผู้ใช้ยืนยันแล้วมาบันทึก
routerOCR.post(
  '/confirm',
  authenticateToken,
  async (req: Request, res: Response) => {
    const userId = (req as any).user.user_id;
    const {
      transaction_data, // ข้อมูลที่ผู้ใช้ยืนยัน (อาจจะมีการแก้ไข)
      category_id,      // category_id สุดท้ายที่ผู้ใช้เลือก
      receipt_image_url // URL รูปภาพที่ได้จากขั้นตอนแรก
    } = req.body;

    if (!transaction_data || !category_id) {
      return res.status(400).json({ status: false, message: 'Missing confirmed transaction data or category_id' });
    }

    try {
      // --- ส่วนนี้คือลอจิกเดิมที่ย้ายมาจาก Endpoint แรก ---

      // ✅ ฟังก์ชันแปลงวันที่ (ยังคงจำเป็น)
      function parseThaiDate(thaiDate: string): string | null {
        if (!thaiDate) return null;
        const cleanDate = thaiDate.replace(/\s+/g, ' ').replace('น.', '').trim();
        const months: Record<string, string> = {
          'ม.ค.': '01', 'ก.พ.': '02', 'มี.ค.': '03', 'เม.ย.': '04',
          'พ.ค.': '05', 'มิ.ย.': '06', 'ก.ค.': '07', 'ส.ค.': '08',
          'ก.ย.': '09', 'ต.ค.': '10', 'พ.ย.': '11', 'ธ.ค.': '12'
        };
        const regex = /(\d{1,2})\s*([ก-ฮ]{2,3}\.)\s*(\d{2,4})(?:\s+(\d{1,2}:\d{2}))?/;
        const match = cleanDate.match(regex);
        if (!match) return null;

        let [_, day, monthTh, year, time] = match;
        const month = months[monthTh] || '01';
        let y = parseInt(year, 10);
        if (y > 2400) y -= 543;
        else if (y < 100) y += 2500 - 543;
        const dateStr = `${y}-${month}-${day.padStart(2, '0')}`;
        return time ? `${dateStr} ${time}:00` : `${dateStr} 00:00:00`;
      }

      const transactionDate =
        parseThaiDate(transaction_data.date) ||
        new Date().toISOString().slice(0, 19).replace('T', ' ');

      // ✅ กำหนด type โดยอิงจาก category_type
      let transactionType = 'expense'; // ค่าเริ่มต้น
      const cat = await query(
        'SELECT category_type FROM category WHERE category_id = ? LIMIT 1',
        [category_id]
      );
      if (cat.length > 0) {
        transactionType = cat[0].category_type;
      }

      // ✅ จัดการ Wallet
      let walletId: number | null = null;
      const wallet = await query(
        'SELECT wallet_id FROM wallet WHERE user_id = ? LIMIT 1',
        [userId]
      );
      if (wallet.length === 0) {
        const createWallet = await query(
          'INSERT INTO wallet (user_id, wallet_name, currency, balance) VALUES (?, ?, ?, 0)',
          [userId, 'Main Wallet', 'THB']
        );
        walletId = createWallet.insertId;
        console.log(`🆕 สร้าง wallet ใหม่สำหรับ user_id=${userId} → wallet_id=${walletId}`);
      } else {
        walletId = wallet[0].wallet_id;
      }

      // ✅ บันทึก Transaction
      await query(
        `INSERT INTO transactions 
        (user_id, wallet_id ,category_id, type, amount, fee, sender_name, receiver_name,
        reference_id, payment_source, data_source, confidence, transaction_date, receipt_image_url)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'ocr', ?, ?, ?)`,
        [
          userId,
          walletId,
          category_id, // ใช้ category_id ที่ผู้ใช้ยืนยัน
          transactionType,
          transaction_data.amount || 0,
          transaction_data.fee || 0,
          transaction_data.sender_name || null,
          transaction_data.receiver_name || null,
          transaction_data.reference_id || null,
          transaction_data.source?.brand || 'unknown',
          transaction_data.overall_confidence || 0,
          transactionDate,
          receipt_image_url || null,
        ]
      );

      // ✅ ส่วนของการแจ้งเตือน Budget (ยังทำงานเหมือนเดิม)
      if (transactionType === 'expense') {
        const today = new Date().toISOString().slice(0, 10);
        const [budget]: any = await query(
          `SELECT budget_id, target_spend, 
              (SELECT COALESCE(SUM(amount),0) 
              FROM transactions 
              WHERE user_id = ? AND type = 'expense' 
              AND DATE(transaction_date) = ?) AS total_spent
          FROM daily_budget 
          WHERE user_id = ? AND budget_date = ? 
          LIMIT 1`,
          [userId, today, userId, today]
        );

        if (budget) {
          const { budget_id } = budget;
          const target_spend = parseFloat(budget.target_spend ?? 0);
          const total_spent = parseFloat(budget.total_spent ?? 0);
          const percentUsed = target_spend > 0 ? (total_spent / target_spend) * 100 : 0;
          
          let shouldNotify = false;
          let notifyType: 'warning' | 'error' | null = null;
          let title = '';
          let message = '';

          if (percentUsed >= 100) {
            shouldNotify = true;
            notifyType = 'error';
            title = 'งบวันนี้หมดแล้ว!';
            message = `คุณใช้จ่ายครบงบประจำวันที่ ${today} แล้ว (${total_spent.toFixed(2)} / ${target_spend.toFixed(2)} บาท)`;
          } else if (percentUsed >= 50) {
            shouldNotify = true;
            notifyType = 'warning';
            title = 'ใกล้เต็มงบวันนี้แล้ว!';
            message = `คุณใช้จ่ายไปแล้ว ${percentUsed.toFixed(0)}% ของงบวันนี้ (${total_spent.toFixed(2)} / ${target_spend.toFixed(2)} บาท)`;
          }

          if (shouldNotify && notifyType) {
            await query(
              `INSERT INTO notifications 
              (user_id, type, title, message, reference_type, reference_id)
              VALUES (?, ?, ?, ?, 'daily_budget', ?)`,
              [userId, notifyType, title, message, budget_id]
            );

            const [userInfo]: any = await query(
              `SELECT email, username FROM users WHERE user_id = ? LIMIT 1`,
              [userId]
            );

            if (userInfo?.email) {
              await sendEmail(userInfo.email, title, message, `...`); // HTML content
              console.log(`📧 Budget alert sent to ${userInfo.email}`);
            }
          }
        }
      }

      res.json({
        status: true,
        message: 'Transaction confirmed and stored successfully',
      });

    } catch (err) {
      console.error('💥 Server error during confirmation:', err);
      res.status(500).json({ status: false, message: 'Server error during confirmation' });
    }
  }
);

export default routerOCR;
