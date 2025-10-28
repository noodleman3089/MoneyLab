export interface Customer {
  id: string;
  name: string;
  age: number;
  income: number;
  occupation: string;
  creditScore: number;
}

export interface RiskProfile {
  customerId: string;
  riskScore: number;
  riskLevel: 'LOW' | 'MEDIUM' | 'HIGH';
  factors: string[];
}

export interface RecommendationResult {
  customerId: string;
  recommendations: string[];
  riskProfile: RiskProfile;
}