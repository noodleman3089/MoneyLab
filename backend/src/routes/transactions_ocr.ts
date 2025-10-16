import express, { Request, Response } from 'express';
import multer from 'multer';
import { spawn } from 'child_process';
import path from 'path';
import fs from 'fs';
import { query } from '../../index';
import { authenticateToken } from '../middlewares/authMiddleware';

const routerOCR = express.Router();

const uploadDir = path.resolve(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

// 🧩 กำหนด storage แบบกำหนดชื่อไฟล์เอง
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname); // ดึง .jpg / .png ออกมา
    const uniqueName = `${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`;
    cb(null, uniqueName);
  }
});

const upload = multer({ storage });

// Route: OCR upload
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

    console.log('Python script path:', scriptPath);
    console.log('Image path:', imagePath);

    try {
      // เรียกใช้ Python OCR module พร้อม --quiet
      const pythonProcess = spawn('python', [
        scriptPath,
        imagePath,
      ]);

      let stdoutData = '';
      let stderrData = '';

      pythonProcess.stdout.on('data', (chunk) => {
        stdoutData += chunk.toString();
      });

      pythonProcess.stderr.on('data', (err) => {
        stderrData += err.toString();
      });

      pythonProcess.on('close', async (code) => {

        // ตรวจสอบ error จาก Python
        if (stderrData.trim()) {
          console.error('OCR stderr:', stderrData);
        }

        if (code !== 0) {
          console.error('Python exited with code', code);
          return res.status(500).json({
            status: false,
            message: 'OCR process failed',
            error: stderrData || 'Unknown error',
          });
        }

        try {
          // กรองเฉพาะ JSON (บางครั้ง Python อาจ print log ก่อนหน้า)
          const cleaned = stdoutData
            .split('\n')
            .map(line => line.trim())
            .filter(line => line.startsWith('{') || line.startsWith('['))
            .pop();

          if (!cleaned) {
            console.error('OCR output did not contain valid JSON:', stdoutData);
            return res.status(500).json({ status: false, message: 'Invalid OCR output (no JSON found)' });
          }

          const result = JSON.parse(cleaned);
          const userId = (req as any).user.user_id;

          // ตรวจสอบข้อมูลขั้นต่ำ
          if (!result.amount || !result.date) {
            return res.status(400).json({
              status: false,
              message: 'ข้อมูลไม่ครบถ้วนจาก OCR',
              raw: result,
            });
          }

          // หา category จากประเภท (income/expense)
          const category = await query(
            'SELECT category_id FROM category WHERE category_type = ? LIMIT 1',
            [result.amount > 0 ? 'income' : 'expense']
          );

          function parseThaiDate(thaiDate: string): string | null {
            if (!thaiDate) return null;

            // ล้างช่องว่างเกิน และตัดคำ "น." ออก
            const cleanDate = thaiDate.replace(/\s+/g, ' ').replace('น.', '').trim();

            const months: Record<string, string> = {
              'ม.ค.': '01', 'ก.พ.': '02', 'มี.ค.': '03', 'เม.ย.': '04',
              'พ.ค.': '05', 'มิ.ย.': '06', 'ก.ค.': '07', 'ส.ค.': '08',
              'ก.ย.': '09', 'ต.ค.': '10', 'พ.ย.': '11', 'ธ.ค.': '12'
            };

            // regex ใหม่: รองรับช่องว่างซ้ำและเวลาแบบมีหรือไม่มี “น.”
            const regex = /(\d{1,2})\s*([ก-ฮ]{2,3}\.)\s*(\d{2,4})(?:\s+(\d{1,2}:\d{2}))?/;
            const match = cleanDate.match(regex);
            if (!match) return null;

            let [_, day, monthTh, year, time] = match;
            const month = months[monthTh] || '01';
            let y = parseInt(year, 10);

            // แปลง พ.ศ. → ค.ศ. / ปี 2 หลัก → ค.ศ.
            if (y > 2400) y -= 543;
            else if (y < 100) y += 2500 - 543;

            const dateStr = `${y}-${month}-${day.padStart(2, '0')}`;
            return time ? `${dateStr} ${time}:00` : `${dateStr} 00:00:00`;
          }

          const transactionDate = parseThaiDate(result.date) || new Date().toISOString().slice(0, 19).replace('T', ' ');
          if (!transactionDate) {
            return res.status(400).json({
              status: false,
              message: 'ไม่สามารถแปลงวันที่จาก OCR ได้',
              raw_date: result.date,
            });
          }

          // ✅ ตรวจสอบข้อมูล OCR เบื้องต้นก่อนบันทึก
          if (
            !result.amount ||
            !result.date ||
            !result.receiver_name ||
            result.overall_confidence < 0.4
          ) {
            return res.status(400).json({
              status: false,
              message: 'รูปใบเสร็จไม่ถูกต้อง หรือความมั่นใจต่ำกว่าเกณฑ์ (0.4)',
              raw: result,
            });
          }

          // 🧠 ตรวจสอบหมวดหมู่จากชื่อผู้รับ
          let categoryId: number | null = null;

          // 1️⃣ ลองหาหมวดหมู่เดิมของผู้รับ
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
            // 2️⃣ ผู้รับนี้ไม่เคยมีมาก่อน → ตั้งหมวดหมู่ "other"
            const other = await query(
              `SELECT category_id FROM category WHERE category_name = 'รายรับเบ็ดเตล็ด' OR category_name = 'อื่นๆ' LIMIT 1`
            );
            categoryId = other[0]?.category_id || null;
            console.log(`🆕 ผู้รับใหม่ → ใช้หมวดหมู่ 'other'`);
          } else if (prev[0].category_name === 'รายรับเบ็ดเตล็ด' || prev[0].category_name === 'อื่นๆ') {
            // 3️⃣ ผู้รับเคยถูกจัดว่า "other" → คงเดิม
            categoryId = prev[0].category_id;
            console.log(`♻️ ผู้รับเคยเป็น 'other' → คงเดิม`);
          } else {
            // 4️⃣ ผู้รับเคยมีหมวดหมู่เฉพาะ → ใช้หมวดหมู่ล่าสุดนั้น
            categoryId = prev[0].category_id;
            console.log(`🔁 ผู้รับเคยใช้หมวดหมู่ '${prev[0].category_name}' → ใช้ซ้ำ`);
          }

          // ✅ หากไม่พบเลย ใช้สำรองเป็น "รายรับเบ็ดเตล็ด" (กันพัง)
          if (!categoryId) {
            const fallback = await query(
              `SELECT category_id FROM category WHERE category_name = 'รายรับเบ็ดเตล็ด' OR category_name = 'อื่นๆ' LIMIT 1`
            );
            categoryId = fallback[0]?.category_id || null;
          }


          // บันทึกลงฐานข้อมูล
          await query(
            `INSERT INTO transactions 
            (user_id, category_id, type, amount, fee, sender_name, receiver_name,
            reference_id, payment_source, data_source, confidence, transaction_date, receipt_image_url)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'ocr', ?, ?, ?)`,
            [
              userId,
              categoryId,
              result.amount > 0 ? 'income' : 'expense',
              result.amount || 0,
              result.fee || 0,
              result.sender_name || null,
              result.receiver_name || null,
              result.reference_id || null,
              result.source?.brand || 'unknown',
              result.overall_confidence || 0,
              transactionDate,
              req.file ? `uploads/${req.file.filename}` : null
            ]
          );


          res.json({
            status: true,
            message: 'OCR data processed and stored successfully',
            data: result,
          });
        } catch (err) {
          console.error('Failed to parse or save OCR result:', err);
          res.status(500).json({ status: false, message: 'Failed to save OCR result' });
        }
      });
    } catch (err) {
      console.error('Server error:', err);
      res.status(500).json({ status: false, message: 'Server error' });
    }
  }
);

export default routerOCR;
