
import mysql from 'mysql2/promise';
import 'dotenv/config';
import { Asset, InvestmentRecommendationTarget } from '../type/type';

// --- 1. DATABASE CONFIGURATION ---
export const dbConfig = {
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: parseInt(process.env.DB_PORT || '3306', 10),
};

// --- 2. DATABASE HELPER FUNCTIONS ---

/**
 * Fetches all available assets from the database.
 */
export async function fetchAssetsFromDb(connection: mysql.Connection): Promise<Asset[]> {
  const allAssets: Asset[] = [];
  
  const getRandomRiskProfile = (): Asset['risk_profile'] => {
    const profiles: Asset['risk_profile'][] = ['Conservative', 'Moderate', 'Aggressive'];
    return profiles[Math.floor(Math.random() * profiles.length)];
  };

  // Fetch US Stocks
  const [stocksRows] = await connection.execute('SELECT stock_id AS id, symbol, industry, sector FROM stocks');
  (stocksRows as any[]).forEach(row => {
    allAssets.push({
      id: row.id, type: 'stock', symbol: row.symbol,
      risk_profile: getRandomRiskProfile(),
      industry_tag: (row.industry || row.sector || 'OTHER').toUpperCase(),
    });
  });

  // Fetch Thai Stocks
  const [stocksTHRows] = await connection.execute('SELECT stock_id AS id, symbol, industry, sector FROM stocksTH');
  (stocksTHRows as any[]).forEach(row => {
    allAssets.push({
      id: row.id, type: 'stockTH', symbol: row.symbol,
      risk_profile: getRandomRiskProfile(),
      industry_tag: (row.industry || row.sector || 'OTHER').toUpperCase(),
    });
  });

  // Fetch Funds
  const [fundsRows] = await connection.execute('SELECT fund_id AS id, symbol, category FROM funds');
  (fundsRows as any[]).forEach(row => {
    allAssets.push({
      id: row.id, type: 'fund', symbol: row.symbol,
      risk_profile: getRandomRiskProfile(),
      industry_tag: (row.category || 'OTHER').toUpperCase(),
    });
  });

  return allAssets;
}

/**
 * Saves the generated investment recommendations to the database.
 */
export async function saveRecommendationsToDb(connection: mysql.Connection, recommendations: InvestmentRecommendationTarget[]): Promise<void> {
  if (recommendations.length === 0) {
    return; // Nothing to save
  }

  const sql = `
    INSERT INTO investment_recommendation ( 
      goal_id, 
      investment_type, 
      investment_ref_id, 
      recommended_allocation_percent
    ) VALUES ?;
  `;

  const values = recommendations.map(rec => [
    rec.goal_id,
    rec.investment_type,
    rec.investment_ref_id,
    rec.recommended_allocation_percent,
  ]);

  await connection.query(sql, [values]);
}
