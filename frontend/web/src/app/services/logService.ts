import axios from 'axios';

// 1. กำหนด Type สำหรับ Log และ Pagination
export interface Log {
  log_id: number;
  actor_id: number | null;
  actor_type: 'user' | 'admin' | 'system' | 'api';
  action: string;
  table_name: string | null;
  record_id: string | null;
  description: string | null;
  ip_address: string | null;
  user_agent: string | null;
  created_at: string;
  old_value: any | null;
  new_value: any | null;
}

export interface Pagination {
  total: number;
  limit: number;
  offset: number;
  nextOffset: number | null;
  prevOffset: number | null;
}

export interface LogsResponse {
  status: boolean;
  data: Log[];
  pagination: Pagination;
  message?: string;
}

// 2. ฟังก์ชันสำหรับดึง Token และสร้าง Header
const getApiUrl = (): string => process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000';

const getAuthHeaders = () => {
  const token = localStorage.getItem('token');
  if (!token) throw new Error('No authentication token found. Please log in.');
  return { 'Authorization': `Bearer ${token}` };
};

// 3. Service function สำหรับดึงข้อมูล Log
export const fetchLogs = async (limit: number, offset: number): Promise<LogsResponse> => {
  const params = new URLSearchParams({ limit: limit.toString(), offset: offset.toString() });
  const url = `${getApiUrl()}/api/logs?${params.toString()}`;

  const response = await axios.get<LogsResponse>(url, {
    headers: getAuthHeaders(),
  });
  return response.data;
};