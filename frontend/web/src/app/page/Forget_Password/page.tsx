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
      const response = await axios.post("/api/forget-password", { email });
      console.log(response.data);
    } catch (error) {
      console.error(error);
    }
  };

  const handleBack = () => {
    window.location.href = "/page/login";
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
          <h1 className='text-[#223248] text-5xl font-semibold mb-12 text-center font-be-vietnam-pro'>Forget Password</h1>

          <form onSubmit={handleSubmit} className='space-y-6'>
            <input
              type='email'
              name='email'
              placeholder='Email'
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className='text-box'
              required
            />

            <button
              type='submit'
              className='btn-primary'
            >
              Confirm
            </button>
          </form>
        </div>
      </div>
    </div>
  )
}

