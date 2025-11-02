export interface DashboardSummary {
  total_users: number;
  total_transactions: number;
  total_income: number;
  total_expense: number;
  new_users_today: number;
}

export interface ExpenseChartData {
  month: string;
  total_expense: number;
}

export interface IncomeChartData {
  category_name: string;
  total_amount: number;
}

export interface ApiResponse<T> {
  status: boolean;
  data: T;
}