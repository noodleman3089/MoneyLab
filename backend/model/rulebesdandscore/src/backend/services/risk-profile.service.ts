// RiskProfileEngine.ts

// 1. นำเข้า (Import) Types ทั้งหมดที่เราออกแบบไว้
import {
  SurveyAnswerRow,
  GroupedAnswers,
  UserFinancialInput,
  RiskProfileResult,
  RiskProfileName,
  KnowledgeValue
} from '../type'; // <-- ย้อนกลับ Path

// ========================================================
// === 2. กำหนดค่าคงที่ (Constants) สำหรับการคำนวณ ===
// ========================================================

// ค่าน้ำหนัก (Weights) ของแต่ละคำถาม
const WEIGHTS = {
  Q1_RISK_TOLERANCE: 0.40, // 40% (สำคัญที่สุด)
  Q5_GOAL: 0.30,           // 30%
  Q3_STABILITY: 0.15,      // 15%
  Q4_KNOWLEDGE: 0.10,      // 10%
  Q2_BEHAVIOR: 0.05,       // 5%
};

// เกณฑ์ (Thresholds) ในการแบ่งกลุ่ม
const PROFILE_THRESHOLDS = {
  AGGRESSIVE: 66, // มากกว่า 66
  MODERATE: 34,   // 34 - 66
  // (น้อยกว่า 34 คือ Conservative)
};

// ========================================================
// === 3. ฟังก์ชันจัดกลุ่มคำตอบ (Helper Function) ===
// ========================================================

/**
 * แปลง Array ของคำตอบจาก DB ให้เป็น Object ที่ใช้งานง่าย
 * @param answers - Array ของ SurveyAnswerRow จาก DB
 * @returns Object ที่มี question_id เป็น key
 */
export function groupAnswers(answers: SurveyAnswerRow[]): GroupedAnswers {
  return answers.reduce((acc, answer) => {
    const qId = answer.question_id.toString();
    const value = answer.answer_value;

    if (!acc[qId]) {
      // ถ้ายังไม่มี key นี้ ให้เพิ่มเข้าไปเป็น string
      acc[qId] = value;
    } else {
      // ถ้ามี key นี้แล้ว (แสดงว่าเป็น multi_choice)
      if (Array.isArray(acc[qId])) {
        // ถ้าเป็น Array อยู่แล้ว (มี 2+ ค่า)
        (acc[qId] as string[]).push(value);
      } else {
        // ถ้ายังเป็น string (นี่คือค่าที่ 2)
        // แปลงให้เป็น Array
        acc[qId] = [acc[qId] as string, value];
      }
    }
    return acc;
  }, {} as GroupedAnswers);
}

// ========================================================
// === 4. ฟังก์ชันหลัก (Main Function) ===
// ========================================================

/**
 * คำนวณ Risk Profile จากข้อมูลทั้งหมดของผู้ใช้
 * @param input - Object ที่มีทั้งคำตอบ, รายได้, และหนี้สิน
 * @returns Object ที่มี profile name และคะแนน
 */
export function calculateRiskProfile(input: UserFinancialInput): RiskProfileResult {
  
  // 4.1. จัดกลุ่มคำตอบให้อยู่ในรูปแบบที่ใช้งานง่าย
  const answers = groupAnswers(input.answers);

  // 4.2. สร้างฟังก์ชันย่อยสำหรับให้คะแนนแต่ละข้อ
  // (ใช้หลัก Safety-first: ถ้าไม่ตอบ หรือตอบ SKIP จะได้คะแนน 0 (Conservative))
  
  const getQ1Score = (val: string): number => {
    switch (val) {
      case "C": return 100; // เสี่ยงสูง
      case "B": return 50;  // เสี่ยงกลาง
      case "A":
      case "SKIP":
      default: return 0;   // เสี่ยงต่ำ
    }
  };

  const getQ2Score = (val: string): number => {
    switch (val) {
      case "A": return 100; // วินัยสูง
      case "B": return 50;  // วินัยกลาง
      case "C":
      case "SKIP":
      default: return 0;   // วินัยต่ำ
    }
  };

  const getQ3Score = (val: string): number => {
    switch (val) {
      case "A": return 100; // มั่นคงสูง
      case "B": return 50;  // มั่นคงกลาง
      case "C":
      case "SKIP":
      default: return 0;   // มั่นคงต่ำ
    }
  };

  const getQ4Score = (val: string | string[] | undefined): number => {
    if (!val) return 0; // ไม่ตอบเลย
    
    // ทำให้เป็น Array เสมอ (ถ้าเป็น string ก็แปลงเป็น array ที่มี 1 item)
    const knowledge = Array.isArray(val) ? val : [val];
    
    // ยึดตามความเสี่ยงสูงสุดที่เขารู้จัก
    if (knowledge.includes("STOCK") || knowledge.includes("CRYPTO")) {
      return 100;
    }
    if (knowledge.includes("MUTUAL_FUND") || knowledge.includes("BOND")) {
      return 50;
    }
    // (ถ้ามีแค่ SAVINGS หรือ NONE)
    return 0;
  };

  const getQ5Score = (val: string): number => {
    switch (val) {
      case "MAX_RETURN": return 100; // เป้าหมายเสี่ยงสูง
      case "STABLE_GROWTH": return 50; // เป้าหมายเสี่ยงกลาง
      case "CAPITAL_PRESERVATION":
      case "SKIP":
      default: return 0; // เป้าหมายเสี่ยงต่ำ
    }
  };

  // 4.3. คำนวณคะแนนดิบของแต่ละข้อ
  // (เราใช้ `answers['1']` เพื่อดึงคำตอบของ Q1)
  // (การใช้ `|| ''` เพื่อป้องกันค่า undefined หากผู้ใช้ไม่ตอบข้อนั้นๆ เลย)
  const scores = {
    q1: getQ1Score(answers['1'] as string || ''),
    q2: getQ2Score(answers['2'] as string || ''),
    q3: getQ3Score(answers['3'] as string || ''),
    q4: getQ4Score(answers['4']),
    q5: getQ5Score(answers['5'] as string || ''),
  };

  // 4.4. คำนวณคะแนนรวมแบบถ่วงน้ำหนัก
  const totalScore = 
    (scores.q1 * WEIGHTS.Q1_RISK_TOLERANCE) +
    (scores.q5 * WEIGHTS.Q5_GOAL) +
    (scores.q3 * WEIGHTS.Q3_STABILITY) +
    (scores.q4 * WEIGHTS.Q4_KNOWLEDGE) +
    (scores.q2 * WEIGHTS.Q2_BEHAVIOR);

  // 4.5. สรุปผลและแปลงคะแนนเป็น Profile Name
  let finalProfile: RiskProfileName;
  if (totalScore > PROFILE_THRESHOLDS.AGGRESSIVE) {
    finalProfile = "Aggressive";
  } else if (totalScore > PROFILE_THRESHOLDS.MODERATE) {
    finalProfile = "Moderate";
  } else {
    finalProfile = "Conservative";
  }

  // 4.6. ส่งคืนผลลัพธ์
  return {
    profile: finalProfile,
    score: totalScore,
  };
}