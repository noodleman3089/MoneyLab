// 1. Importing Dependencies
'use client' // ต้องใช้เพราะใช้ useState และ window, localStorage
import React, { useState, FormEvent } from 'react';
import axios from "axios";

// 2. Creating and Exporting a Component
export default function LoginPage() {

  // 2.1 Defining Variables, States, and Handlers
  // สร้างตัวแปร state สำหรับเก็บ username และ password
  const [username, setUsername] = useState<string>("");
  const [password, setPassword] = useState<string>("");

  // สร้างฟังก์ชันสำหรับจัดการการ submit form ไปยัง API
  // โดยใช้ async/await เพื่อจัดการกับการเรียก API แบบ asynchronous
  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault() // ป้องกัน reload หน้า

    try {
      // ใช้ axios เพื่อส่ง POST request ไปยัง API
      const response = await axios.post("http://localhost:4000/api/login", {
        username,
        password
      });

      const result = response.data // รับข้อมูลจาก API
      alert(result.message); // แสดงข้อความจาก API
      
      // ถ้าเข้าสู่ระบบสำเร็จ จะเก็บ token และ redirect ไปหน้าแรก
      if (result.status === true) {
        // localStorage.setItem('user_id', result.user_id);
        // localStorage.setItem('token', result.token);
        window.location.href = "/page/Main"; // เปลี่ยนเส้นทางไปยังหน้า Main
      }
    } catch (error) {
      console.error("Login error:", error); // แสดงข้อผิดพลาดใน console
      alert("Login failed. Please try again."); // แสดงข้อความเมื่อเข้าสู่ระบบไม่สำเร็จ
    }
  };

  // ฟังก์ชันสำหรับเปลี่ยนเส้นทางไปยังหน้า Forget_Password
  const handleForgotPassword = () => {
    window.location.href = "/page/Forget_Password";
  };

  // ฟังก์ชันสำหรับเปลี่ยนเส้นทางไปยังหน้า register
  const handleSignUp = () => {
    window.location.href = "/page/register";
  };

  return (
    <div className="min-h-screen flex">
      <div className="flex-1 bg-teal-500 flex items-start justify-start p-8">
      </div>

      <div className="flex-1 bg-[#C7DCDE] flex items-center justify-center p-8">
        <div className="w-full max-w-sm">
          <h1 className="text-[#223248] text-5xl font-semibold mb-12 text-center font-be-vietnam-pro">Login</h1>

          <form onSubmit={handleSubmit} className="space-y-6">
            <input
              type="text"
              name="username"
              placeholder="Username"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="w-full px-4 py-3 rounded-sm outline-none border-none bg-white text-black placeholder-gray-500 focus:ring-4 focus:ring-[#4FB7B3] focus:border-4 focus:border-[#4FB7B3] transition-all duration-200 shadow-sm shadow-[#9CAAD6] font-be-vietnam-pro"
              required
            />

            <input
              type="password"
              name="password"
              placeholder="Passwords"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-3 rounded-sm outline-none border-none bg-white text-black placeholder-gray-500 focus:ring-4 focus:ring-[#4FB7B3] focus:border-4 focus:border-[#4FB7B3] transition-all duration-200 shadow-sm shadow-[#9CAAD6] font-be-vietnam-pro"
              required
            />

            <button
              type="submit"
              className="w-[155px] h-[40px] bg-[#4FB7B3] hover:bg-[#C7DCDE] text-white hover:text-[#008170] font-bold rounded-[20px] hover:border-2 hover:border-[#4FB7B3] hover:shadow-none mt-8 transition-colors duration-200 font-be-vietnam-pro flex items-center justify-center mx-auto shadow-md"
            >
              Confirm
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