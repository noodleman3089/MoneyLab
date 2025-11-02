import axios from 'axios';
import { RegisterPayload, VerifyOtpPayload, AuthResponse, LoginPayload, LoginResponse } from './auth.types';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000';

/**
 * Service สำหรับส่งคำขอลงทะเบียนผู้ใช้ใหม่
 *
 * @param payload - ข้อมูลการลงทะเบียนประกอบด้วย username, email, password, confirmPassword
 * @returns Promise<AuthResponse>
 */
export const registerUser = async (payload: RegisterPayload): Promise<AuthResponse> => {
  try {
    const url = `${API_BASE_URL}/api/auth/register`;
    const response = await axios.post<AuthResponse>(url, payload);
    return response.data;
  } catch (error: any) {
    // จัดการ Error ที่มาจาก axios ให้มีรูปแบบเดียวกัน
    if (axios.isAxiosError(error) && error.response) {
      return error.response.data;
    }
    // กรณี Error อื่นๆ
    return {
      status: false,
      message: 'An unexpected error occurred during registration.',
    };
  }
};

/**
 * Service สำหรับส่งคำขอล็อกอิน
 *
 * @param payload - ข้อมูลประกอบด้วย username และ password
 * @returns Promise<LoginResponse>
 */
export const loginUser = async (payload: LoginPayload): Promise<LoginResponse> => {
  try {
    // Path ของ login controller คือ /api/login ไม่ได้อยู่ใต้ /auth
    const url = `${API_BASE_URL}/api/login`;
    const response = await axios.post<LoginResponse>(url, payload);
    return response.data;
  } catch (error: any) {
    if (axios.isAxiosError(error) && error.response) {
      // ส่งต่อ message จาก backend ถ้ามี
      return error.response.data;
    }
    // กรณี Error อื่นๆ ที่ไม่ใช่จาก API response
    return {
      status: false,
      message: 'An unexpected error occurred during login.',
    };
  }
};

/**
 * Service สำหรับส่ง OTP เพื่อยืนยันการลงทะเบียน
 *
 * @param payload - ข้อมูลประกอบด้วย email และ otp
 * @returns Promise<AuthResponse>
 */
export const verifyOtp = async (payload: VerifyOtpPayload): Promise<AuthResponse> => {
  try {
    const url = `${API_BASE_URL}/api/auth/verify-otp`;
    const response = await axios.post<AuthResponse>(url, payload);
    return response.data;
  } catch (error: any) {
    if (axios.isAxiosError(error) && error.response) {
      return error.response.data;
    }
    return {
      status: false,
      message: 'An unexpected error occurred during OTP verification.',
    };
  }
};