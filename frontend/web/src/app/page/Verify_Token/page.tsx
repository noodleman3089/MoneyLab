// 1. Importing Dependencies
'use client' // ต้องใช้เพราะใช้ useState และ window, localStorage
import React, { useState, useRef, useEffect, FormEvent } from 'react';
import { useSearchParams, useRouter } from 'next/navigation'; // 1. Import hooks จาก Next.js
import axios from "axios";

// 2. Creating and Exporting a Component
export default function VerifyTokenPage() {

  // 2.1 Defining Variables, States, and Handlers
  // สร้างตัวแปร state สำหรับเก็บ OTP แต่ละช่อง (6 หลัก)
  const [otp, setOtp] = useState<string[]>(["", "", "", "", "", ""]);
  const [timer, setTimer] = useState<number>(60); // นับถอยหลัง 60 วินาที
  const inputRefs = useRef<(HTMLInputElement | null)[]>([]);
  const [email, setEmail] = useState<string | null>(null); // 2. สร้าง state สำหรับเก็บ email
  const [error, setError] = useState<string | null>(null); // State สำหรับเก็บข้อความ error

  // 3. อ่าน email จาก URL ตอนที่หน้าโหลด
  const searchParams = useSearchParams();
  const router = useRouter();
  useEffect(() => {
    setEmail(searchParams.get('email'));
  }, [searchParams]);

  // สร้าง timer สำหรับนับถอยหลัง
  useEffect(() => {
    if (timer > 0) {
      const countdown = setTimeout(() => setTimer(timer - 1), 1000);
      return () => clearTimeout(countdown);
    }
  }, [timer]);

  // ฟังก์ชันจัดการการเปลี่ยนแปลงของ input
  const handleChange = (index: number, value: string) => {
    // อนุญาตเฉพาะตัวเลข
    if (!/^\d*$/.test(value)) return;

    const newOtp = [...otp];
    newOtp[index] = value;
    setOtp(newOtp);

    // ย้ายไปช่องถัดไปอัตโนมัติเมื่อกรอกเสร็จ
    if (value && index < 5) {
      inputRefs.current[index + 1]?.focus();
    }
  };

  // ฟังก์ชันจัดการการกด backspace
  const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Backspace" && !otp[index] && index > 0) {
      inputRefs.current[index - 1]?.focus();
    }
  };

  // ฟังก์ชันจัดการการ paste
  const handlePaste = (e: React.ClipboardEvent) => {
    e.preventDefault();
    const pastedData = e.clipboardData.getData("text").slice(0, 6);
    if (!/^\d+$/.test(pastedData)) return;

    const newOtp = [...otp];
    for (let i = 0; i < pastedData.length && i < 6; i++) {
      newOtp[i] = pastedData[i];
    }
    setOtp(newOtp);

    // ย้าย focus ไปช่องสุดท้ายที่มีข้อมูล
    const nextIndex = Math.min(pastedData.length, 5);
    inputRefs.current[nextIndex]?.focus();
  };

  // สร้างฟังก์ชันสำหรับจัดการการ submit form ไปยัง API
  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault(); // ป้องกัน reload หน้า
    setError(null); // Reset error ทุกครั้งที่ submit

    const otpCode = otp.join(""); // รวม OTP ทั้ง 6 หลักเป็น string

    // ตรวจสอบว่ากรอก OTP ครบ 6 หลักหรือไม่
    if (otpCode.length !== 6) {
      setError("กรุณากรอกรหัส OTP ให้ครบ 6 หลัก");
      return;
    }

    // ตรวจสอบว่ามี email จาก URL หรือไม่
    if (!email) {
      setError("ไม่พบอีเมลสำหรับยืนยัน กรุณากลับไปหน้าสมัครสมาชิก");
      return;
    }

    try {
      // 4. [THE FIX] เรียก API ที่ถูกต้องพร้อมส่ง email และ otp
      const response = await axios.post("http://localhost:5000/api/verify-otp", {
        email: email,
        otp: otpCode
      });

      const result = response.data; // รับข้อมูลจาก API
      alert(result.message); // แสดงข้อความจาก API

      // 5. [THE FIX] ถ้ายืนยันสำเร็จ ให้ไปหน้า Login
      if (result.status === true) {
        router.push("/page/login");
      }
    } catch (err: any) {
      console.error("Verify OTP error:", err);
      const errorMessage = err.response?.data?.message || "Verification failed. Please try again.";
      setError(errorMessage);
    }
  };

  // ฟังก์ชันสำหรับเปลี่ยนเส้นทางกลับไปหน้า login
  const handleBack = () => {
    window.location.href = "/page/login";
  };

  const handleNextPage = () => {
    window.location.href = "/page/Reset_Password"; //เอาไว้ทดสอบการเปลี่ยนหน้า
  }

  return (
    <div className="min-h-screen flex">
      <div className="flex-1 bg-teal-500 flex items-start justify-start p-8">
        <button type="button" onClick={handleBack} className="text-[#223248] hover:text-[#C7DCDE] flex items-center gap-2 text-2xl font-semibold transition-all duration-200 font-be-vietnam-pro">
          <svg className="rotate-180" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 15 15" >
            <path fill="currentColor" d="M8.293 2.293a1 1 0 0 1 1.414 0l4.5 4.5a1 1 0 0 1 0 1.414l-4.5 4.5a1 1 0 0 1-1.414-1.414L11 8.5H1.5a1 1 0 0 1 0-2H11L8.293 3.707a1 1 0 0 1 0-1.414" />
          </svg>
          Back
        </button>
      </div>

      <div className="flex-1 bg-[#C7DCDE] flex items-center justify-center p-8">
        <div className="w-full max-w-md">
          <h1 className="text-[#223248] text-5xl font-semibold mb-6 text-center font-be-vietnam-pro">Confirm Your Number</h1>
          
          <p className="flex items-center justify-center text-[#008170] text-xl font-semibold mb-8 font-be-vietnam-pro whitespace-nowrap">
            Enter the 6-digit code we just sent to your email address.
          </p>

          <form onSubmit={handleSubmit} className="space-y-6">
            {/* OTP Input Fields */}
            <div className="flex justify-center gap-3 mb-6">
              {otp.map((digit, index) => (
                <input
                  key={index}
                  ref={(el) => {
                    inputRefs.current[index] = el;
                  }}
                  type="text"
                  maxLength={1}
                  value={digit}
                  onChange={(e) => handleChange(index, e.target.value)}
                  onKeyDown={(e) => handleKeyDown(index, e)}
                  onPaste={handlePaste}
                  className="w-12 h-14 text-center text-2xl font-semibold rounded-sm outline-none border-none bg-white text-[#223248] focus:ring-4 focus:ring-[#4FB7B3] focus:border-4 focus:border-[#4FB7B3] transition-all duration-200 shadow-sm shadow-[#9CAAD6] font-be-vietnam-pro"
                  required
                />
              ))}
            </div>

            {/* 6. แสดงข้อความ Error (ถ้ามี) */}
            {error && (
              <p className="text-red-500 text-center text-sm font-be-vietnam-pro">{error}</p>
            )}

            <div className="text-center space-y-1">
              <p className="text-[#223248] text-sm font-be-vietnam-pro">
                The code has been sent to your email.
              </p>
              <p className="text-gray-400 text-xs font-be-vietnam-pro">
                Code will expire in {timer} sec
              </p>
            </div>

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
