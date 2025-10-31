# Financial Recommendation Microservice

## 1. ภาพรวม (Overview) 

โปรเจกต์นี้คือ Microservice ที่สร้างด้วย Node.js, Express, และ TypeScript มีหน้าที่หลักในการสร้างคำแนะนำทางการเงิน (Financial Recommendations) โดยรับข้อมูลทางการเงินของผู้ใช้และเป้าหมาย (Goal) เข้ามาประมวลผล

**กระบวนการทำงาน (Workflow):**
1.  **สร้างคำแนะนำ:** Client ส่ง `userId`, `goalId`, และข้อมูลการเงินพื้นฐาน (รายได้, หนี้สิน) มายัง `POST /api/recommendations/generate`
2.  **ดึงข้อมูล:** Backend ใช้ `userId` ที่ได้รับมาไปดึงข้อมูล **คำตอบแบบสอบถาม** จากตาราง `survey_answer` และใช้ `goalId` ไปดึง **ข้อมูลเป้าหมาย** จากตาราง `saving_goals`
3.  **วิเคราะห์:** ระบบนำข้อมูลทั้งหมดมาคำนวณ **Risk Profile** (จากคำตอบ) และ **ระยะเวลาของเป้าหมาย** (จากข้อมูลเป้าหมาย) เพื่อสร้าง **คำแนะนำทั่วไป (General Advice)**
4.  **สร้างแผนลงทุน:** ระบบดึงข้อมูลสินทรัพย์ทั้งหมด (`stocks`, `funds`, `stocksTH`) จากฐานข้อมูล แล้วสร้าง **รายการตัวเลือกการลงทุน (Investment Options)** ที่เหมาะสมกับผู้ใช้ โดยพิจารณาทั้ง Risk Profile และระยะเวลาของเป้าหมาย (แนะนำสูงสุดประเภทละ 3 ตัว)
5.  **บันทึกผล:** ระบบบันทึกรายการตัวเลือกที่สร้างขึ้นลงในตาราง `investment_recommendation` โดยผูกกับ `goalId` (และตั้งค่า `recommended_allocation_percent` เป็น 0 เพื่อบ่งบอกว่าเป็น "ตัวเลือก")
6.  **ดึงคำแนะนำ:** Client สามารถดึงรายการตัวเลือกการลงทุนที่บันทึกไว้สำหรับเป้าหมายนั้นๆ ได้ตลอดเวลาผ่าน `GET /api/recommendations/goals/:goalId`

---

## 2. โครงสร้างไฟล์ (File Structure)

โครงสร้างไฟล์ที่สำคัญของโปรเจกต์มีดังนี้:

```
backendscore/
│
├── server.ts                 # จุดเริ่มต้น (Entry Point) ของเซิร์ฟเวอร์
├── type.ts                   # เก็บ TypeScript Types ที่ใช้ร่วมกันทั้งโปรเจกต์
│
├── controller/
│   └── recommendation.controller.ts  # จัดการ Request/Response ของ API
│
├── routes/
│   └── recommendation.routes.ts      # กำหนดเส้นทาง (Endpoint) ของ API
│
└── services/
    ├── database.service.ts         # จัดการการเชื่อมต่อและคำสั่งกับฐานข้อมูล
    ├── recommendation.service.ts   # ตรรกะหลักในการสร้างคำแนะนำ
    └── risk-profile.service.ts     # ตรรกะการคำนวณ Risk Profile
```

---

## 3. วิธีการนำไปใช้งาน (Integration Guide)

มี 2 วิธีหลักในการนำโปรเจกต์นี้ไปใช้:

### วิธีที่ 1: ใช้งานในรูปแบบ Microservice (แนะนำ)

วิธีนี้คือการรันโปรเจกต์นี้แยกเป็นเซิร์ฟเวอร์ของตัวเอง แล้วให้โปรเจกต์หลักมายิง API เรียกใช้งาน

**สิ่งที่ต้องเอาไป:**
*   โค้ดทั้งหมดในโปรเจกต์ `backendscore` นี้
*   ตั้งค่าไฟล์ `.env` ให้ถูกต้อง (โดยเฉพาะการเชื่อมต่อฐานข้อมูล)

**ขั้นตอน:**
1.  ในโปรเจกต์ `backendscore` สั่งรันเซิร์ฟเวอร์ (เช่น `npm start`)
2.  จากโปรเจกต์หลัก (หรือ Postman) ให้ยิง `POST` request มาที่ `http://<backendscore_host>:<port>/api/recommendations/generate-recommendations`
3.  ใน Body ของ Request ให้ส่ง JSON ที่มีหน้าตาแบบนี้:
    ```json
    {
      "userInput": { ... }, // Object ข้อมูลทางการเงินทั้งหมดของผู้ใช้ตามที่กำหนดใน type.ts
      "goalId": 123       // ID ของเป้าหมายที่ต้องการสร้างคำแนะนำ
    }
    ```

### วิธีที่ 2: ใช้งานในรูปแบบ Library/Module

วิธีนี้คือการคัดลอกโค้ดส่วน Logic ไปไว้ในโปรเจกต์หลักโดยตรง

**สิ่งที่ต้องเอาไป:**
*   โฟลเดอร์ `services/` ทั้งหมด
*   โฟลเดอร์ `controller/`
*   ไฟล์ `type.ts`
*   **ข้อควรระวัง:** ต้องรวม Dependencies จาก `package.json` (เช่น `mysql2`) เข้าไปในโปรเจกต์หลักด้วย

**ขั้นตอน:**
1.  คัดลอกไฟล์และโฟลเดอร์ข้างต้นไปไว้ในโปรเจกต์หลัก
2.  ในโปรเจกต์หลัก `import` และเรียกใช้ฟังก์ชันจาก Service โดยตรง เช่น `getFinancialRecommendations()`
3.  วิธีนี้ซับซ้อนกว่าและอาจทำให้โปรเจกต์หลักใหญ่ขึ้นโดยไม่จำเป็น

---

## 4. การเตรียมข้อมูลสำหรับทดสอบ (Prerequisites)

เพื่อให้ระบบทำงานได้อย่างสมบูรณ์ คุณจำเป็นต้องมีข้อมูลในตารางต่อไปนี้:

1.  **`users`**: ต้องมีข้อมูลผู้ใช้อย่างน้อย 1 คน
2.  **`saving_goals`**: ต้องมีข้อมูลเป้าหมายการออมที่ผูกกับ `user_id` นั้นๆ
3.  **`survey_answer`**: ต้องมีข้อมูลคำตอบแบบสอบถามที่ผูกกับ `user_id` นั้นๆ
4.  **`stocks`, `stocksTH`, `funds`**: ต้องมีข้อมูลสินทรัพย์สำหรับใช้ในการสร้างคำแนะนำ

**ตัวอย่างคำสั่ง SQL สำหรับเพิ่มข้อมูลสินทรัพย์:**

```sql
-- เพิ่มข้อมูลกองทุน
INSERT INTO funds (symbol, category) VALUES 
('B-TREASURY', 'GOVERNMENT'),
('K-CHANGE-A(A)', 'ESG');
-- เพิ่มข้อมูลหุ้นไทย
INSERT INTO stocksTH (symbol, industry, sector) VALUES 
('AOT', 'Services', 'TRANSPORT');
-- เพิ่มข้อมูลหุ้นต่างประเทศ
INSERT INTO stocks (symbol, industry, sector) VALUES 
('GOOGL', 'Technology', 'Communication Services'),
('TSLA', 'Consumer Cyclical', 'Auto Manufacturers');
```

### ขั้นตอนที่ 2: การทดสอบใน Postman

1.  **Start Server:** รันเซิร์ฟเวอร์ด้วยคำสั่ง `npm start` (หรือ `ts-node src/backend/server.ts`)
2.  **ตั้งค่าใน Postman:**
    *   **Method:** `POST`
    *   **URL:** `http://localhost:3000/api/recommendations/generate-recommendations` (ถ้าคุณใช้ Port 3000)
    *   **Headers:**
        *   Key: `Content-Type`
        *   Value: `application/json`
    *   **Body:** เลือก `raw` และ `JSON`

3.  **ใส่ข้อมูลใน Body:** คัดลอก JSON ตัวอย่างด้านล่างไปวางใน Body ของ Postman คุณสามารถแก้ไขค่าต่างๆ เพื่อทดสอบสถานการณ์ที่แตกต่างกันได้

    **ตัวอย่าง Body สำหรับผู้ใช้ "Moderate" ที่สนใจ "TECH" และไม่มีหนี้:**
    ```json
    {
      "goalId": 101,
      "userInput": {
        "answers": [
          { "question_id": 1, "answer_value": "B" },
          { "question_id": 2, "answer_value": "B" },
          { "question_id": 3, "answer_value": "B" },
          { "question_id": 4, "answer_value": "MUTUAL_FUND" },
          { "question_id": 5, "answer_value": "STABLE_GROWTH" },
          { "question_id": 6, "answer_value": "TECH" }
        ],
        "main_income_amount": 70000,
        "side_income_amount": 10000,
        "debts": []
      }
    }
    ```

4.  **กด "Send" และตรวจสอบผลลัพธ์:**
    *   **Risk Profile:** ควรจะได้ `Moderate`
    *   **General Advice:** ควรเป็นคำแนะนำเรื่องการออม (Saving)
    *   **Investment Plan:** ควรจะแนะนำสินทรัพย์ที่มี `risk_profile` เป็น `Moderate` และ `industry_tag` เป็น `TECH` (เช่น `GOOGL`)

---

## 5. การจัดการ Dependencies (Dependency Management)

หากคุณต้องการใช้งานโปรเจกต์นี้เป็นส่วนหนึ่งของโปรเจกต์หลัก (ตามวิธีที่ 2) และใช้ `node_modules` ร่วมกัน คุณสามารถลบโฟลเดอร์ `node_modules` ของโปรเจกต์นี้ทิ้งได้ แต่ต้องทำการรวม Dependencies ก่อน

**ขั้นตอน:**
1.  คัดลอก Dependencies จาก `package.json` ของโปรเจกต์นี้ ไปใส่ใน `package.json` ของโปรเจกต์หลัก
2.  ไปที่โฟลเดอร์ของโปรเจกต์หลัก แล้วรัน `npm install`

**Dependencies ที่ต้องการ:**
```json
"dependencies": {
  "dotenv": "^17.2.3",
  "express": "^5.1.0",
  "mysql2": "^3.15.3"
}
```

**DevDependencies ที่ต้องการ:**
```json
"devDependencies": {
  "@types/express": "^5.0.5",
  "@types/node": "^24.9.1"
}
```
```