export interface User {
  user_id: number;
  username: string;
  email: string;
  phone_number: string | null;
  role: string;
  last_login_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface Pagination {
  total: number;
  limit: number;
  offset: number;
  nextOffset: number | null;
  prevOffset: number | null;
}

export interface UsersResponse {
  status: boolean;
  message: string;
  data: User[];
  pagination: Pagination;
  filter: { role?: string } | null;
}

export interface UserProfile {
  main_income_amount: number;
  side_income_amount: number;
  // เพิ่ม field อื่นๆ จากตาราง profile ตามต้องการ
}

export interface UserDebt {
  debt_id: number;
  debt_type: string;
  debt_amount: number;
  // เพิ่ม field อื่นๆ จากตาราง debt ตามต้องการ
}

export interface UserDetails {
  user: User;
  profile: UserProfile | null;
  debts: UserDebt[];
  transactions: any[]; // ใช้ any ไปก่อนเพื่อความง่าย หรือจะสร้าง Type เฉพาะก็ได้
}