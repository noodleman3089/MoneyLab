import { Customer, RecommendationResult } from '../types/customer.types';
import { RiskProfileCalculator } from './risk-profile.calculator';

export class RecommendationEngine {
  private riskProfileCalculator: RiskProfileCalculator;

  constructor() {
    this.riskProfileCalculator = new RiskProfileCalculator();
  }

  generateRecommendations(customer: Customer): RecommendationResult {
    const riskProfile = this.riskProfileCalculator.generateRiskProfile(customer);
    const recommendations = this.generateRecommendationsByRiskLevel(riskProfile.riskLevel, customer);

    return {
      customerId: customer.id,
      recommendations,
      riskProfile
    };
  }

  private generateRecommendationsByRiskLevel(
    riskLevel: 'LOW' | 'MEDIUM' | 'HIGH',
    customer: Customer
  ): string[] {
    const recommendations: string[] = [];

    switch (riskLevel) {
      case 'HIGH':
        recommendations.push('Consider debt consolidation');
        recommendations.push('Seek financial counseling');
        if (customer.income < 30000) {
          recommendations.push('Look for additional income sources');
        }
        break;

      case 'MEDIUM':
        recommendations.push('Review and reduce unnecessary expenses');
        recommendations.push('Create an emergency fund');
        if (customer.creditScore < 700) {
          recommendations.push('Work on improving credit score');
        }
        break;

      case 'LOW':
        recommendations.push('Consider investment opportunities');
        recommendations.push('Review insurance coverage');
        recommendations.push('Plan for long-term financial goals');
        break;
    }

    return recommendations;
  }
}