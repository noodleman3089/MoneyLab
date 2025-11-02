import axios from 'axios';
import { UsersResponse, UserDetails } from './user.types';

const API_ENDPOINT = '/api/users';

/**
 * ดึงข้อมูล API URL จาก Environment Variables หรือใช้ค่า Default
 */
const getApiUrl = (): string => {
  return process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000';
};

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
 * Service สำหรับดึงรายชื่อผู้ใช้ทั้งหมดพร้อม Pagination
 * @param limit - จำนวนผู้ใช้ต่อหน้า
 * @param offset - ตำแหน่งเริ่มต้น
 * @returns Promise<UsersResponse>
 */
export const fetchUsers = async (limit: number, offset: number, role?: 'user' | 'admin' | null): Promise<UsersResponse> => {
  const params = new URLSearchParams({
    limit: limit.toString(),
    offset: offset.toString(),
  });

  // เพิ่ม role เข้าไปใน query params ถ้ามีการระบุค่ามา (และไม่ใช่ 'all')
  if (role) {
    params.append('role', role);
  }

  const url = `${getApiUrl()}${API_ENDPOINT}?${params.toString()}`;

  const response = await axios.get<UsersResponse>(url, {
    headers: getAuthHeaders(),
  });

  return response.data;
};

/**
 * Service สำหรับระงับบัญชีผู้ใช้
 * @param userId - ID ของผู้ใช้ที่ต้องการระงับ
 * @returns Promise<any>
 */
export const suspendUser = async (userId: number): Promise<any> => {
  const url = `${getApiUrl()}/api/users/${userId}/suspend`;
  const response = await axios.put(url, {}, {
    headers: getAuthHeaders(),
  });
  return response.data;
};

/**
 * Service สำหรับลบบัญชีผู้ใช้
 * @param userId - ID ของผู้ใช้ที่ต้องการลบ
 * @returns Promise<any>
 */
export const hardDeleteUser = async (userId: number): Promise<any> => {
  const url = `${getApiUrl()}/api/users/${userId}`;
  const response = await axios.delete(url, {
    headers: getAuthHeaders(),
  });
  return response.data;
};

/**
 * Service สำหรับลบบัญชีผู้ใช้แบบ Soft Delete
 * @param userId - ID ของผู้ใช้ที่ต้องการลบ
 * @returns Promise<any>
 */
export const softDeleteUser = async (userId: number): Promise<any> => {
  const url = `${getApiUrl()}/api/users/soft/${userId}`;
  const response = await axios.delete(url, {
    headers: getAuthHeaders(),
  });
  return response.data;
};

/**
 * Service สำหรับดึงข้อมูลรายละเอียดผู้ใช้เชิงลึก
 * @param userId - ID ของผู้ใช้
 * @returns Promise<{status: boolean, data: UserDetails}>
 */
export const fetchUserDetails = async (userId: number): Promise<{ status: boolean, data: UserDetails }> => {
  const url = `${getApiUrl()}/api/users/${userId}`;
  const response = await axios.get(url, {
    headers: getAuthHeaders(),
  });
  return response.data;
};

/**
 * Service สำหรับเลื่อนขั้นผู้ใช้ให้เป็น Admin
 * @param userId - ID ของผู้ใช้ที่ต้องการเลื่อนขั้น
 * @returns Promise<any>
 */
export const promoteUser = async (userId: number): Promise<any> => {
  const url = `${getApiUrl()}/api/users/${userId}/promote`;
  const response = await axios.patch(url, {}, { // ใช้ PATCH method
    headers: getAuthHeaders(),
  });
  return response.data;
};