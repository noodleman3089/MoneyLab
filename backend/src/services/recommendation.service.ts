// RecommendationEngine.ts

// 1. นำเข้า (Import) Types ที่จำเป็น
import { 
  UserFinancialInput,
  RiskProfileResult,
  Recommendation, // (เราจะไปสร้าง Type นี้ใน type.ts กัน)
  DebtItem,
  SurveyAnswerRow,
  Asset,
  InvestmentRecommendationTarget,
  GoalInfo,
} from '../type/type'; // <-- ย้อนกลับ Path
import { groupAnswers } from './risk-profile.service'; // นำเข้าฟังก์ชันจัดกลุ่มคำตอบ

// ========================================================
// === 2. Constants and Configuration                   ===
// ========================================================

const HIGH_INTEREST_THRESHOLD = 10; // ดอกเบี้ย > 10% ถือว่าเป็นดอกเบี้ยสูง
const DTI_YELLOW_THRESHOLD = 36; // DTI > 36% เริ่มมีความเสี่ยง (ค่าสมมติ)
const DTI_RED_THRESHOLD = 43;    // DTI > 43% มีความเสี่ยงสูงมาก (ค่าสมมติ)

// ========================================================
// === 3. Helper Functions                            ===
// ========================================================

/**
 * คำนวณอัตราส่วนหนี้ต่อรายได้ (Debt-to-Income Ratio)
 * @param debts - รายการหนี้ทั้งหมด
 * @param monthlyIncome - รายได้ต่อเดือน
 * @returns DTI Ratio (เป็นเปอร์เซ็นต์)
 */
function calculateDTI(debts: DebtItem[], monthlyIncome: number): number {
  if (monthlyIncome <= 0) return Infinity; // ป้องกันการหารด้วยศูนย์

  const totalMonthlyDebtPayments = debts.reduce((sum, debt) => sum + debt.debt_monthly_payment, 0);
  
  return (totalMonthlyDebtPayments / monthlyIncome) * 100;
}

/**
 * ตรวจสอบหาหนี้ที่มีดอกเบี้ยสูง
 * @param debts - รายการหนี้ทั้งหมด
 * @returns หนี้ที่มีดอกเบี้ยสูงรายการแรกที่เจอ หรือ undefined
 */
function findHighInterestDebt(debts: DebtItem[]): DebtItem | undefined {
  return debts.find(debt => typeof debt.debt_interest_rate === 'number' && debt.debt_interest_rate > HIGH_INTEREST_THRESHOLD);
}

// ========================================================
// === 4. Main Recommendation Logic                   ===
// ========================================================

/**
 * สร้างคำแนะนำทางการเงินตามโปรไฟล์และความเสี่ยงของผู้ใช้
 * @param userInput - ข้อมูลทางการเงินทั้งหมดของผู้ใช้
 * @param riskProfile - ผลการวิเคราะห์ความเสี่ยง
 * @returns Array ของคำแนะนำ
 */
export function getFinancialRecommendations(
  userInput: UserFinancialInput,
  riskProfile: RiskProfileResult,
  allAssetsFromDb: Asset[], // <-- 1. รับสินทรัพย์จริง
  targetGoalId: number,      // <-- 2. รับ Goal ID
  goalInfo: GoalInfo        // <-- 3. รับข้อมูลเป้าหมายที่คำนวณแล้ว
): { generalAdvice: Recommendation[], investmentsToSave: InvestmentRecommendationTarget[] } { // <-- 3. เปลี่ยน Return type

  const recommendations: Recommendation[] = [];
  const investmentsToSave: InvestmentRecommendationTarget[] = [];
  const { debts, answers: surveyAnswers, main_income_amount, side_income_amount } = userInput;
  const monthlyIncome = main_income_amount + side_income_amount;

  // --- 1. สร้าง "โปรไฟล์ที่มีผล" (Effective Profile) ---
  // คัดลอกโปรไฟล์เดิมมาก่อน
  let effectiveRiskProfile: RiskProfileResult = { ...riskProfile }; //

  // --- 2. กฎไฟจราจร (ปรับปรุงใหม่) ---
  const highInterestDebt = findHighInterestDebt(debts);
  
  if (highInterestDebt) {
    // --- กฎนิรภัย (Safety Override Rule) ---
    // ถ้าเจอหนี้สูง ให้บังคับโปรไฟล์เป็น Conservative
    effectiveRiskProfile.profile = "Conservative";
    effectiveRiskProfile.score = 0; // (ปรับคะแนนให้สอดคล้องกัน)
    
    // เพิ่มคำแนะนำเรื่องหนี้ (Priority 1)
    recommendations.push({
      priority: 1,
      category: "DEBT",
      title: `[สำคัญที่สุด] ปิดหนี้ดอกเบี้ยสูงก่อน: ${highInterestDebt.debt_type}`,
      description: `เราพบหนี้ดอกเบี้ย ${highInterestDebt.debt_interest_rate}% การปิดหนี้นี้คือ 'ผลตอบแทนที่การันตี' ที่ดีที่สุดของคุณตอนนี้`
    });
    
    // *** สำคัญ: เราไม่ 'return' แล้ว ***
    
  } else if (calculateDTI(debts, monthlyIncome) > DTI_RED_THRESHOLD) {
     // (Logic DTI ยังทำงานเหมือนเดิม)
      const dti = calculateDTI(debts, monthlyIncome);
      recommendations.push({
        priority: 1,
        category: "DEBT",
        title: "ลดภาระหนี้สินด่วน",
        description: `อัตราส่วนหนี้ต่อรายได้ (DTI) ของคุณอยู่ที่ ${dti.toFixed(2)}% ซึ่งสูงมาก ควรให้ความสำคัญกับการลดหนี้เพื่อเพิ่มสภาพคล่องทางการเงิน`,
      });
  } else if (calculateDTI(debts, monthlyIncome) > DTI_YELLOW_THRESHOLD) {
      const dti = calculateDTI(debts, monthlyIncome);
      recommendations.push({
        priority: 2, // ความสำคัญรองลงมา
        category: "DEBT",
        title: "สร้างเงินสำรองฉุกเฉินและควบคุมหนี้",
        description: `อัตราส่วนหนี้ต่อรายได้ (DTI) ของคุณอยู่ที่ ${dti.toFixed(2)}% ควรพิจารณาสร้างเงินสำรองฉุกเฉินให้ครอบคลุมรายจ่าย 3-6 เดือน และหลีกเลี่ยงการสร้างหนี้ที่ไม่จำเป็นเพิ่ม`,
      });
  } 

  // --- 3. คำแนะนำการออม (ยังทำงานปกติ) ---
  if (recommendations.length === 0) { // ถ้าไม่มีคำเตือนเรื่องหนี้
     recommendations.push({
      priority: 1,
      category: "SAVING",
      title: "เริ่มต้นสร้างเงินสำรองฉุกเฉิน",
      description: "ควรมีเงินสำรองฉุกเฉินสำหรับค่าใช้จ่าย 3-6 เดือน เพื่อรับมือกับเหตุการณ์ไม่คาดฝัน"
    });
  }

  // --- 4. คำแนะนำการลงทุน (ทำงานเสมอ) ---
  const investmentResults = getInvestmentSuggestion(effectiveRiskProfile, surveyAnswers, allAssetsFromDb, targetGoalId, goalInfo);
  
  if (investmentResults.length > 0) {
    investmentsToSave.push(...investmentResults);
    
    recommendations.push({
      priority: 3, // เป็น Priority รอง
      category: "INVESTMENT",
      title: "พิจารณาการลงทุนตามแผน",
      description: `นี่คือแผนการลงทุนที่เหมาะสมกับโปรไฟล์ (${effectiveRiskProfile.profile}) ของคุณ`
    });
  }

  // --- 5. คืนค่าทั้งหมด ---
  return {
    generalAdvice: recommendations.sort((a, b) => a.priority - b.priority),
    investmentsToSave: investmentsToSave
  };
}


/**
 * สร้างคำแนะนำการลงทุนตามโปรไฟล์ความเสี่ยงและความสนใจของผู้ใช้
 * @returns Array ของ InvestmentRecommendationTarget ที่พร้อมสำหรับบันทึกลง DB
 */
function getInvestmentSuggestion(
  riskProfile: RiskProfileResult,
  surveyAnswers: SurveyAnswerRow[],
  allAssets: Asset[],
  targetGoalId: number,
  goalInfo: GoalInfo // <-- รับข้อมูลเป้าหมายเข้ามา
): InvestmentRecommendationTarget[] { // <-- คืนค่าเป็น Array ที่พร้อม Save

  // 1. ดึงความสนใจ (Interest): ดึงคำตอบข้อ 6
  const answers = groupAnswers(surveyAnswers);
  const rawInterests = answers['6']; // Can be string, string[], or undefined
  const interestsArray = Array.isArray(rawInterests) ? rawInterests : (rawInterests ? [rawInterests] : []);

  // 2. กรองขั้นที่ 1 (ตาม Risk และ **ระยะเวลาเป้าหมาย**)
  let riskFilteredAssets = allAssets.filter(asset => asset.risk_profile === riskProfile.profile);

  // --- กฎใหม่: ปรับการเลือกสินทรัพย์ตามระยะเวลา ---
  if (goalInfo.calculatedDurationMonths <= 12) { // น้อยกว่าหรือเท่ากับ 1 ปี
    // บังคับให้เลือกเฉพาะสินทรัพย์ความเสี่ยงต่ำสุดเท่านั้น
    riskFilteredAssets = allAssets.filter(asset => asset.risk_profile === 'Conservative');
  } else if (goalInfo.calculatedDurationMonths <= 36) { // 1-3 ปี
    // ไม่อนุญาตให้มีสินทรัพย์เสี่ยงสูง
    riskFilteredAssets = riskFilteredAssets.filter(asset => asset.risk_profile !== 'Aggressive');
  }
  // ถ้ามากกว่า 3 ปี (37+ เดือน) ก็ใช้สินทรัพย์ตาม Risk Profile ของผู้ใช้ได้เลย
  // -----------------------------------------


  // 6. (ถ้าไม่มีสินทรัพย์): ถ้ากรองตาม Risk แล้วไม่เจออะไรเลย ให้ return []
  if (riskFilteredAssets.length === 0) {
    return [];
  }

  // 3. กรองขั้นที่ 2 (ตาม Interest)
  let interestFilteredAssets = riskFilteredAssets.filter(asset => interestsArray.includes(asset.industry_tag));

  // 4. (กฎสำรอง): ถ้ากรองตาม Interest แล้วไม่เหลืออะไรเลย ให้ใช้ผลลัพธ์จากข้อ 2
  if (interestFilteredAssets.length === 0) {
    interestFilteredAssets = riskFilteredAssets;
  }

  // 5. ตัดสินใจ (Rule): ปรับปรุงใหม่
  // 5.1 สุ่มลำดับสินทรัพย์ที่กรองมาได้ เพื่อไม่ให้ได้ตัวเดิมทุกครั้ง
  const shuffledAssets = interestFilteredAssets.sort(() => 0.5 - Math.random());

  // 5.2 เลือกสินทรัพย์มาสูงสุด 3 ตัว
  const MAX_ASSETS_TO_RECOMMEND = 3;
  const selectedAssets = shuffledAssets.slice(0, MAX_ASSETS_TO_RECOMMEND);

  // 5.3 ถ้าไม่มีสินทรัพย์ที่เลือกได้เลย ให้คืนค่าว่าง
  if (selectedAssets.length === 0) {
    return [];
  }

  // 5.4 คำนวณสัดส่วนการลงทุน (แบ่งเท่าๆ กัน)
  const allocationPercent = parseFloat((100 / selectedAssets.length).toFixed(2));

  // 5.5 สร้างผลลัพธ์ที่พร้อมสำหรับบันทึกลง DB
  const recommendations: InvestmentRecommendationTarget[] = selectedAssets.map((asset, index) => {
    // จัดการเศษทศนิยมโดยปัดให้ตัวสุดท้ายเพื่อให้รวมกันได้ 100% พอดี
    const isLast = index === selectedAssets.length - 1;
    const finalAllocation = isLast ? 100 - (allocationPercent * (selectedAssets.length - 1)) : allocationPercent;

    return {
      goal_id: targetGoalId,
      investment_type: asset.type,
      investment_ref_id: asset.id,
      recommended_allocation_percent: parseFloat(finalAllocation.toFixed(2)),
    };
  });

  return recommendations;
}