/**
 * Interface สำหรับข้อมูลที่ใช้ในการส่งคำขอลงทะเบียน
 */
export interface RegisterPayload {
  username: string;
  email: string;
  password: string; // <-- เปลี่ยนจาก password_hash เป็น password
  confirmPassword: string; // <-- เพิ่ม confirmPassword
  phone_number?: string | null;
}

/**
 * Interface สำหรับข้อมูลที่ใช้ในการส่งคำขอตรวจสอบ OTP
 */
export interface VerifyOtpPayload {
  email: string;
  otp: string; // <-- เปลี่ยนจาก otp_code เป็น otp
}

/**
 * Interface สำหรับการตอบกลับทั่วไปจาก Auth API
 */
export interface AuthResponse {
  status: boolean;
  message: string;
}

/**
 * Interface สำหรับข้อมูลที่ใช้ในการส่งคำขอล็อกอิน
 */
export interface LoginPayload {
  username: string;
  password: string;
}

/**
 * Interface สำหรับการตอบกลับเมื่อล็อกอินสำเร็จ
 */
export interface LoginResponse extends AuthResponse {
  token?: string;
  user?: { user_id: number; username: string; role: 'user' | 'admin' };
}