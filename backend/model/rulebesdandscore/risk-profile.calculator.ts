import { Customer, RiskProfile } from '../models/types';

export class RiskProfileCalculator {
  calculateRiskScore(customer: Customer): number {
    let score = 0;
    
    // Age factor
    if (customer.age < 25) {
      score += 30;
    } else if (customer.age < 35) {
      score += 20;
    } else if (customer.age < 50) {
      score += 10;
    }

    // Income factor
    if (customer.income < 15000) {
      score += 30;
    } else if (customer.income < 30000) {
      score += 20;
    } else if (customer.income < 50000) {
      score += 10;
    }

    // Credit score factor
    if (customer.creditScore < 500) {
      score += 40;
    } else if (customer.creditScore < 700) {
      score += 20;
    } else if (customer.creditScore < 800) {
      score += 10;
    }

    return score;
  }

  determineRiskLevel(score: number): 'LOW' | 'MEDIUM' | 'HIGH' {
    if (score >= 70) {
      return 'HIGH';
    } else if (score >= 40) {
      return 'MEDIUM';
    }
    return 'LOW';
  }

  generateRiskProfile(customer: Customer): RiskProfile {
    const riskScore = this.calculateRiskScore(customer);
    const riskLevel = this.determineRiskLevel(riskScore);
    const factors = this.determineRiskFactors(customer);

    return {
      customerId: customer.id,
      riskScore,
      riskLevel,
      factors
    };
  }

  private determineRiskFactors(customer: Customer): string[] {
    const factors: string[] = [];

    if (customer.age < 25) {
      factors.push('Young age');
    }
    if (customer.income < 15000) {
      factors.push('Low income');
    }
    if (customer.creditScore < 500) {
      factors.push('Poor credit history');
    }

    return factors;
  }
}