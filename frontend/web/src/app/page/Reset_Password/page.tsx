// 1. Importing Dependencies
'use client' // ต้องใช้เพราะใช้ useState และ window, localStorage
import React, { useState, FormEvent } from 'react';
import axios from "axios";

// 2. Creating and Exporting a Component
export default function ResetPasswordPage() {

  // 2.1 Defining Variables, States, and Handlers
  // สร้างตัวแปร state สำหรับเก็บ password และ confirmPassword
  const [newPassword, setNewPassword] = useState<string>("");
  const [confirmPassword, setConfirmPassword] = useState<string>("");

  // สร้างฟังก์ชันสำหรับจัดการการ submit form ไปยัง API
  // โดยใช้ async/await เพื่อจัดการกับการเรียก API แบบ asynchronous
  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault(); // ป้องกัน reload หน้า

    // ตรวจสอบว่า password ตรงกับ confirmPassword หรือไม่
    if (newPassword !== confirmPassword) {
      alert("รหัสผ่านไม่ตรงกัน กรุณาตรวจสอบอีกครั้ง");
      return;
    }

    try {
      // ใช้ axios เพื่อส่ง POST request ไปยัง API
      const response = await axios.post("http://localhost:4000/api/reset-password", {
        newPassword,
        confirmPassword
      });

      const result = response.data; // รับข้อมูลจาก API
      alert(result.message); // แสดงข้อความจาก API

      // ถ้ารีเซ็ตรหัสผ่านสำเร็จ จะ redirect ไปหน้า login
      if (result.status === true) {
        window.location.href = "/page/login";
      }
    } catch (error) {
      console.error("Reset password error:", error); // แสดงข้อผิดพลาดใน console
      alert("Reset password failed. Please try again."); // แสดงข้อความเมื่อรีเซ็ตรหัสผ่านไม่สำเร็จ
    }
  };

  // ฟังก์ชันสำหรับเปลี่ยนเส้นทางไปยังหน้า login
  const handleBack = () => {
    window.location.href = "/page/login";
  };

  const handleNextPage = () => {
    window.location.href = "/page/login"; //เอาไว้ทดสอบการเปลี่ยนหน้า
  }

  return (
    <div className="min-h-screen flex">
      <div className="flex-1 bg-teal-500 flex items-start justify-start p-8">
        <button type="button" onClick={handleBack} className="text-[#223248] hover:text-[#C7DCDE] flex items-center gap-2 text-2xl font-semibold transition-all duration-200 font-be-vietnam-pro">
          <svg className="rotate-180" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 15 15">
            <path fill="currentColor" d="M8.293 2.293a1 1 0 0 1 1.414 0l4.5 4.5a1 1 0 0 1 0 1.414l-4.5 4.5a1 1 0 0 1-1.414-1.414L11 8.5H1.5a1 1 0 0 1 0-2H11L8.293 3.707a1 1 0 0 1 0-1.414" />
          </svg>
          Back
        </button>
      </div>

      <div className="flex-1 bg-[#C7DCDE] flex items-center justify-center p-8">
        <div className="w-full max-w-sm">
          <h1 className="flex items-center justify-center text-[#223248] text-5xl font-semibold mb-6 font-be-vietnam-pro whitespace-nowrap">Reset Your Password</h1>

          <p className="flex items-center justify-center text-[#223248] text-sm mb-8 font-be-vietnam-pro whitespace-nowrap">
            Enter a new password without using a password on your account.
          </p>

          <form onSubmit={handleSubmit} className="space-y-4">
            <input
              type="password"
              name="newPassword"
              placeholder="New password"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              className="w-full px-4 py-3 rounded-sm outline-none border-none bg-white text-black placeholder-gray-500 focus:ring-4 focus:ring-[#4FB7B3] focus:border-4 focus:border-[#4FB7B3] transition-all duration-200 shadow-sm shadow-[#9CAAD6] font-be-vietnam-pro"
              required
            />

            <input
              type="password"
              name="confirmPassword"
              placeholder="Confirm password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              className="w-full px-4 py-3 rounded-sm outline-none border-none bg-white text-black placeholder-gray-500 focus:ring-4 focus:ring-[#4FB7B3] focus:border-4 focus:border-[#4FB7B3] transition-all duration-200 shadow-sm shadow-[#9CAAD6] font-be-vietnam-pro"
              required
            />

            <button
              type="submit"
              className="w-[155px] h-[40px] bg-[#4FB7B3] hover:bg-[#C7DCDE] text-white hover:text-[#008170] font-bold rounded-[20px] hover:border-2 hover:border-[#4FB7B3] hover:shadow-none mt-6 transition-colors duration-200 font-be-vietnam-pro flex items-center justify-center mx-auto shadow-md"
            >
              Confirm
            </button>

            {/* ปุ่มเปลี่ยนหน้าชั่วคราว */}
            <button
              type='button'
              onClick={handleNextPage}
              className='w-[155px] h-[40px] bg-[#4FB7B3] hover:bg-[#C7DCDE] text-white hover:text-[#008170] font-bold rounded-[20px] hover:border-2 hover:border-[#4FB7B3] hover:shadow-none mt-6 transition-colors duration-200 font-be-vietnam-pro flex items-center justify-center mx-auto shadow-md'
            >
              Test Next Page
            </button>

          </form>
        </div>
      </div>
    </div>
  )
}
