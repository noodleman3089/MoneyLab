import { redirect } from 'next/navigation';

/**
 * นี่คือหน้าแรกของเว็บไซต์ (/)
 * เราจะใช้หน้านี้เพื่อ redirect ผู้ใช้ไปยังหน้า Login โดยอัตโนมัติ
 */
export default function RootPage() {
  redirect('/page/login');
}