import axios from 'axios';
import { DashboardSummary, ExpenseChartData, IncomeChartData, ApiResponse } from '../services/dashboard.types';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000';
const DASHBOARD_API_ENDPOINT = '/api/dashboard';

/**
 * ดึง Token จาก Local Storage และสร้าง Header สำหรับ Authorization
 */
const getAuthHeaders = () => {
  const token = localStorage.getItem('token');
  if (!token) {
    throw new Error('No authentication token found. Please log in.');
  }
  return {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
  };
};

/**
 * Service สำหรับดึงข้อมูลตัวเลขสรุปทั้งหมด
 */
export const fetchDashboardSummary = async (): Promise<ApiResponse<DashboardSummary>> => {
  const url = `${API_BASE_URL}${DASHBOARD_API_ENDPOINT}/summary`;
  const response = await axios.get<ApiResponse<DashboardSummary>>(url, { headers: getAuthHeaders() });
  return response.data;
};

/**
 * Service สำหรับดึงข้อมูลกราฟแท่งรายจ่าย
 */
export const fetchExpenseChartData = async (): Promise<ApiResponse<ExpenseChartData[]>> => {
  const url = `${API_BASE_URL}${DASHBOARD_API_ENDPOINT}/expense-chart`;
  const response = await axios.get<ApiResponse<ExpenseChartData[]>>(url, { headers: getAuthHeaders() });
  return response.data;
};

/**
 * Service สำหรับดึงข้อมูลกราฟวงกลมรายรับ
 */
export const fetchIncomeChartData = async (): Promise<ApiResponse<IncomeChartData[]>> => {
  const url = `${API_BASE_URL}${DASHBOARD_API_ENDPOINT}/income-chart`;
  const response = await axios.get<ApiResponse<IncomeChartData[]>>(url, { headers: getAuthHeaders() });
  return response.data;
};