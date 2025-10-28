# Financial Recommendation Microservice

## 1. ภาพรวม (Overview)

โปรเจกต์นี้คือ Microservice ที่สร้างด้วย Node.js, Express, และ TypeScript มีหน้าที่หลักในการสร้างคำแนะนำทางการเงิน (Financial Recommendations) โดยรับข้อมูลทางการเงินของผู้ใช้และเป้าหมาย (Goal) เข้ามาประมวลผล

**กระบวนการทำงาน:**
1.  รับข้อมูล `userInput` และ `goalId` ผ่าน API
2.  คำนวณโปรไฟล์ความเสี่ยง (`Risk Profile`) จากแบบสอบถาม
3.  สร้างคำแนะนำทั่วไป (General Advice) เช่น การจัดการหนี้, การออม
4.  สร้างคำแนะนำการลงทุน (Investment Recommendations) โดยอิงจาก Risk Profile และสินทรัพย์ที่มีในฐานข้อมูล
5.  บันทึกคำแนะนำการลงทุนลงฐานข้อมูลและส่งผลลัพธ์ทั้งหมดกลับไปให้ผู้เรียก (Client)

---

## 2. โครงสร้างไฟล์ (File Structure)

หลังจากทำการ Refactor โครงสร้างไฟล์ที่สำคัญมีดังนี้:

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

## 3. วิธีการนำไปใช้งานในโปรเจคหลัก (Integration Guide)

มี 2 วิธีหลักในการนำโปรเจกต์นี้ไปใช้:

### วิธีที่ 1: ใช้งานในรูปแบบ Microservice (แนะนำ)

วิธีนี้คือการรันโปรเจกต์นี้แยกเป็นเซิร์ฟเวอร์ของตัวเอง แล้วให้โปรเจกต์หลักมายิง API เรียกใช้งาน

**สิ่งที่ต้องเอาไป:**
*   โค้ดทั้งหมดในโปรเจกต์ `backendscore` นี้
*   ตั้งค่าไฟล์ `.env` ให้ถูกต้อง (โดยเฉพาะการเชื่อมต่อฐานข้อมูล)

**ขั้นตอน:**
1.  ในโปรเจกต์ `backendscore` สั่งรันเซิร์ฟเวอร์ (เช่น `npm start`)
2.  จากโปรเจกต์หลัก ให้ยิง `POST` request มาที่ `http://<backendscore_host>:<port>/api/generate-recommendations`
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

## 4. วิธีการทดสอบ (Testing Guide)

### ทดสอบผ่าน API Endpoint (Integration Test)

1.  **Start Server:** รันเซิร์ฟเวอร์ด้วยคำสั่ง `npm start` หรือ `ts-node server.ts`
2.  **Send Request:** ใช้เครื่องมืออย่าง Postman, Insomnia, หรือ `curl` เพื่อส่ง `POST` request ไปที่ `http://localhost:3000/api/generate-recommendations`
3.  **Request Body:** ใส่ JSON ที่มี `userInput` และ `goalId` ให้ครบถ้วน
    ```bash
    curl -X POST http://localhost:3000/api/generate-recommendations \
    -H "Content-Type: application/json" \
    -d '{
          "goalId": 1,
          "userInput": {
            "answers": [
              {"question_id": 1, "answer_value": "A"},
              {"question_id": 5, "answer_value": "CAPITAL_PRESERVATION"}
            ],
            "main_income_amount": 50000,
            "side_income_amount": 0,
            "debts": []
          }
        }'
    ```
4.  **Verify Response:** ตรวจสอบ `JSON response` ที่ได้รับว่ามี `riskProfile` และ `recommendations` ถูกต้องหรือไม่

### ทดสอบที่ระดับฟังก์ชัน (Unit Test)

คุณสามารถเขียนเทสสำหรับแต่ละ Service ได้โดยตรงเพื่อทดสอบ Logic การทำงาน

*   **ตัวอย่าง:** สร้างไฟล์ `services/recommendation.test.ts`
*   `import` ฟังก์ชัน `getFinancialRecommendations`
*   สร้างข้อมูล Mock `userInput`, `riskProfile`, `allAssetsFromDb`
*   เรียกใช้ฟังก์ชันและ `assert` ผลลัพธ์ที่ได้ว่าเป็นไปตามที่คาดหวังหรือไม่

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