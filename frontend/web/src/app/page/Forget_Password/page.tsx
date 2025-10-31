// 1. Importing Dependencies
'use client' // ต้องใช้เพราะใช้ useState และ window, localStorage
import React, { useState, FormEvent } from 'react';
import axios from "axios";

// 2. Creating and Exporting a Component
export default function ForgetPasswordPage() {

  // 2.1 Defining Variables, States, and Handlers
  // สร้างตัวแปร state สำหรับเก็บ email
  const [email, setEmail] = useState<string>("");

  // สร้างฟังก์ชันสำหรับจัดการการ submit form ไปยัง API
  // โดยใช้ async/await เพื่อจัดการกับการเรียก API แบบ asynchronous
  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    try {
      const response = await axios.post("http://localhost:4000/api/forget-password", { email });
      console.log(response.data);

    } catch (error) {
      console.error("Forget Password error:", error); // แสดงข้อผิดพลาดใน console
      alert("Failed to send reset link. Please try again."); // แสดงข้อความเมื่อส่งลิงก์รีเซ็ตรหัสผ่านไม่สำเร็จ
    }
  };

  const handleBack = () => {
    window.location.href = "/page/login";
  }

  const handleNextPage = () => {
    window.location.href = "/page/Verify_Token"; //เอาไว้ทดสอบการเปลี่ยนหน้า
  }

  return (
    <div className='min-h-screen flex'>
      <div className='flex-1 bg-teal-500 flex items-start justify-start p-8'>
        <button type="button" onClick={handleBack} className="text-[#223248] hover:text-[#C7DCDE] flex items-center gap-2 text-2xl font-semibold transition-all duration-200 font-be-vietnam-pro">
          <svg className="rotate-180" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 15 15">
            <path fill="currentColor" d="M8.293 2.293a1 1 0 0 1 1.414 0l4.5 4.5a1 1 0 0 1 0 1.414l-4.5 4.5a1 1 0 0 1-1.414-1.414L11 8.5H1.5a1 1 0 0 1 0-2H11L8.293 3.707a1 1 0 0 1 0-1.414" />
          </svg>
          Back
        </button>
      </div>

      <div className='flex-1 bg-[#C7DCDE] flex items-center justify-center p-8'>
        <div className='w-full max-w-sm'>
          <h1 className="flex items-center justify-center text-[#223248] text-5xl font-semibold mb-8 font-be-vietnam-pro whitespace-nowrap">Forgot Password ?</h1>

          <div className="mb-8 text-left">
            <h2 className="text-[#008170] text-xl font-semibold mb-2 font-be-vietnam-pro">Have you forgotten your password?</h2>
            <p className="text-[#223248] text-sm font-be-vietnam-pro">
              Please enter your username or email address <br />to receive a link to reset your password.
            </p>
          </div>

          <form onSubmit={handleSubmit} className='space-y-6'>
            <input
              type='email'
              name='email'
              placeholder='Email'
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className='w-full px-4 py-3 rounded-sm outline-none border-none bg-white text-black placeholder-gray-500 focus:ring-4 focus:ring-[#4FB7B3] focus:border-4 focus:border-[#4FB7B3] transition-all duration-200 shadow-sm shadow-[#9CAAD6] font-be-vietnam-pro'
              required
            />

            <button
              type='submit'
              className='w-[155px] h-[40px] bg-[#4FB7B3] hover:bg-[#C7DCDE] text-white hover:text-[#008170] font-bold rounded-[20px] hover:border-2 hover:border-[#4FB7B3] hover:shadow-none mt-6 transition-colors duration-200 font-be-vietnam-pro flex items-center justify-center mx-auto shadow-md'
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

