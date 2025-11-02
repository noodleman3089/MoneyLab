// 1. Importing Dependencies
'use client' // ต้องใช้เพราะใช้ useState และ window, localStorage
import React, { useState, FormEvent } from 'react';
import { useRouter } from 'next/navigation';
import { loginUser } from '@/app/services/authService'; // 👈 1. Import service ที่ถูกต้อง

// 2. Creating and Exporting a Component
export default function LoginPage() {

  // 2.1 Defining Variables, States, and Handlers
  const router = useRouter();
  const [username, setUsername] = useState<string>("");
  const [password, setPassword] = useState<string>("");
  // --- State สำหรับจัดการ Loading และ Messages ---
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  // สร้างฟังก์ชันสำหรับจัดการการ submit form ไปยัง API
  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault() // ป้องกัน reload หน้า
    setMessage(null);
    setIsLoading(true);

    try {
      // 👈 2. [REFACTORED] เรียกใช้ Service ที่เราสร้างไว้
      const result = await loginUser({
        username,
        password
      });

      if (result.status === true) {
        setMessage({ type: 'success', text: 'เข้าสู่ระบบสำเร็จ!' });
        
        // 👈 3. [IMPLEMENTED] บันทึก token และข้อมูลผู้ใช้
        localStorage.setItem('token', result.token!);
        if (result.user) {
          localStorage.setItem('user', JSON.stringify(result.user));
        }

        
        if (result.user?.role === 'admin') {
          router.push('/admin/main');
        } else {
          router.push('/page/main'); // ไปหน้าหลักสำหรับ User
        }
      } else {
        setMessage({ type: 'error', text: result.message || 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง' });
      }
    } catch (error) {
      console.error("Login error:", error); // แสดงข้อผิดพลาดใน console
      setMessage({ type: 'error', text: 'เกิดข้อผิดพลาดในการเชื่อมต่อ' });
    } finally {
      setIsLoading(false);
    }
  };

  // ฟังก์ชันสำหรับเปลี่ยนเส้นทางไปยังหน้า Forget_Password
  const handleForgotPassword = () => {
    router.push("/page/Forget_Password");
  };

  // ฟังก์ชันสำหรับเปลี่ยนเส้นทางไปยังหน้า register
  const handleSignUp = () => {
    router.push("/page/register");
  };

  return (
    <div className="min-h-screen flex">
      <div className="flex-1 bg-teal-500 flex items-start justify-start p-8">
      </div>

      <div className="flex-1 bg-[#C7DCDE] flex items-center justify-center p-8">
        <div className="w-full max-w-sm">
          <h1 className="text-[#223248] text-5xl font-semibold mb-12 text-center font-be-vietnam-pro">Login</h1>

          {/* 👈 5. [NEW] ส่วนแสดงข้อความ Success/Error */}
          {message && (
            <div className={`p-3 rounded-md text-center mb-6 text-white font-be-vietnam-pro ${
              message.type === 'error' ? 'bg-red-500' : 'bg-green-500'
            }`}
            >
              {message.text}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-6">
            <input
              type="text"
              name="username"
              placeholder="Username"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="w-full px-4 py-3 rounded-sm outline-none border-none bg-white text-black placeholder-gray-500 focus:ring-4 focus:ring-[#4FB7B3] transition-all duration-200 shadow-sm shadow-[#9CAAD6] font-be-vietnam-pro"
              required
            />

            <input
              type="password"
              name="password"
              placeholder="Passwords"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-3 rounded-sm outline-none border-none bg-white text-black placeholder-gray-500 focus:ring-4 focus:ring-[#4FB7B3] transition-all duration-200 shadow-sm shadow-[#9CAAD6] font-be-vietnam-pro"
              required
            />

            <button
              type="submit"
              disabled={isLoading} // 👈 6. ปิดปุ่มตอนโหลด
              className="w-[155px] h-[40px] bg-[#4FB7B3] hover:bg-[#3a9793] text-white font-bold rounded-[20px] mt-8 transition-colors duration-200 font-be-vietnam-pro flex items-center justify-center mx-auto shadow-md disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              {isLoading ? 'กำลังเข้าสู่ระบบ...' : 'Confirm'}
            </button>

            <div className="flex justify-between items-center mt-6 text-[#223248] text-sm font-be-vietnam-pro">
              <button
                type="button"
                onClick={handleForgotPassword}
                className="hover:text-[#008170] hover:font-bold transition-colors duration-200"
              >
                Forget Password ?
              </button>
              <button
                type="button"
                onClick={handleSignUp}
                className="hover:text-[#008170] hover:font-bold transition-colors duration-200"
              >
                Don't have account
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}