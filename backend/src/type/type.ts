// d:\ForProject\Test\backendscore\type.ts

export type SingleChoiceValue = "A" | "B" | "C" | "SKIP";
export type KnowledgeValue = "SAVINGS" | "MUTUAL_FUND" | "STOCK" | "BOND" | "CRYPTO" | "NONE";
export type InterestValue = "TECH" | "HEALTHCARE" | "ENERGY_UTILITIES" | "CONSUMER" | "FINANCE" | "ANY";
export type GoalValue = "CAPITAL_PRESERVATION" | "STABLE_GROWTH" | "MAX_RETURN" | "SKIP";

export interface SurveyAnswerRow {
  question_id: number;
  answer_value: string;
}

export interface GroupedAnswers {
  [question_id: string]: string | string[];
}

export type RiskProfileName = "Conservative" | "Moderate" | "Aggressive";

export interface RiskProfileResult {
  profile: RiskProfileName;
  score: number;
}

// ========================================================
// === 🚀 ส่วนที่สำคัญที่ต้องมี ===
// ========================================================

/**
 * ข้อมูลหนี้สิน 1 รายการ
 */
export interface DebtItem {
  debt_type: string;
  debt_amount: number;
  debt_monthly_payment: number;
  debt_interest_rate?: number; // สำคัญมากสำหรับ Logic!
}

/**
 * ข้อมูลสรุปของผู้ใช้ทั้งหมด ที่จะใช้เป็น Input
 */
export interface UserFinancialInput {
  userId: number; // <-- เพิ่มเข้ามา: ID ของผู้ใช้
  answers: SurveyAnswerRow[];
  main_income_amount: number;
  side_income_amount: number;
  debts: DebtItem[];
}

// === Types for RecommendationEngine ===
export type RecommendationCategory = "DEBT" | "SAVING" | "INVESTMENT" | "FINANCIAL_HEALTH";

export interface Recommendation {
  priority: number;
  category: RecommendationCategory;
  title: string;
  description: string;
}

/**
 * หน้าตาของสินทรัพย์ที่เราจะ Query มาจาก DB
 */
export interface Asset {
  id: number;
  type: 'stock' | 'stockTH' | 'fund';
  symbol: string;
  risk_profile: RiskProfileName;
  industry_tag: string;
}

/**
 * หน้าตาของ "ผลลัพธ์" ที่เราจะ INSERT ลง DB
 */
export interface InvestmentRecommendationTarget {
  goal_id: number;
  investment_type: 'stock' | 'stockTH' | 'fund';
  investment_ref_id: number;
  recommended_allocation_percent: number;
}

/**
 * หน้าตาของ "คำแนะนำการลงทุน" ที่จะส่งกลับไปให้ Client
 */
export interface FetchedRecommendation {
  symbol: string;
  type: 'stock' | 'stockTH' | 'fund';
  allocation: number;
}
