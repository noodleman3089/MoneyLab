'use client';

import React, { useState, useRef, useEffect, ChangeEvent, KeyboardEvent, FormEvent } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { verifyOtp } from '@/app/services/authService'; // Import service สำหรับยืนยัน OTP

export default function VerifyOtpPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const email = searchParams.get('email');

  const [otp, setOtp] = useState<string[]>(new Array(6).fill(''));
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
  const inputRefs = useRef<(HTMLInputElement | null)[]>([]);

  useEffect(() => {
    if (!email) {
      // ถ้าไม่มี email ใน URL ให้ส่งกลับไปหน้า register
      router.push('/page/register');
    }
    // โฟกัสที่ input แรกเมื่อหน้าโหลด
    inputRefs.current[0]?.focus();
  }, [email, router]);

  const handleChange = (e: ChangeEvent<HTMLInputElement>, index: number) => {
    const { value } = e.target;
    if (/^[0-9]$/.test(value) || value === '') {
      const newOtp = [...otp];
      newOtp[index] = value;
      setOtp(newOtp);

      // เลื่อนโฟกัสไปข้างหน้าถ้าพิมพ์ตัวเลข
      if (value !== '' && index < 5) {
        inputRefs.current[index + 1]?.focus();
      }
    }
  };

  const handleKeyDown = (e: KeyboardEvent<HTMLInputElement>, index: number) => {
    // เลื่อนโฟกัสไปข้างหลังถ้ากด Backspace ในช่องที่ว่างอยู่
    if (e.key === 'Backspace' && otp[index] === '' && index > 0) {
      inputRefs.current[index - 1]?.focus();
    }
  };

  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setMessage(null);
    const otpCode = otp.join('');

    if (otpCode.length !== 6) {
      setMessage({ type: 'error', text: 'กรุณากรอกรหัส OTP ให้ครบ 6 หลัก' });
      return;
    }

    if (!email) {
      setMessage({ type: 'error', text: 'ไม่พบอีเมลสำหรับยืนยัน' });
      return;
    }

    setIsLoading(true);

    try {
      const result = await verifyOtp({ email, otp: otpCode });

      if (result.status) {
        setMessage({ type: 'success', text: 'ยืนยันบัญชีสำเร็จ! กำลังนำท่านไปหน้าเข้าสู่ระบบ...' });
        setTimeout(() => {
          router.push('/page/login');
        }, 2000);
      } else {
        setMessage({ type: 'error', text: result.message || 'รหัส OTP ไม่ถูกต้องหรือหมดอายุแล้ว' });
        setOtp(new Array(6).fill('')); // เคลียร์ค่า OTP
        inputRefs.current[0]?.focus(); // กลับไปโฟกัสช่องแรก
      }
    } catch (error) {
      console.error("OTP Verification error:", error);
      setMessage({ type: 'error', text: 'เกิดข้อผิดพลาดที่ไม่คาดคิด กรุณาลองอีกครั้ง' });
    } finally {
      setIsLoading(false);
    }
  };

  const handleBack = () => {
    router.push('/page/register');
  };

  return (
    <div className="min-h-screen flex font-be-vietnam-pro">
      {/* --- ฝั่งซ้าย --- */}
      <div className="flex-1 bg-teal-500 flex items-start justify-start p-8">
        <button type="button" onClick={handleBack} className="text-[#223248] hover:text-[#C7DCDE] flex items-center gap-2 text-2xl font-semibold transition-all duration-200">
          <svg className="rotate-180" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 15 15">
            <path fill="currentColor" d="M8.293 2.293a1 1 0 0 1 1.414 0l4.5 4.5a1 1 0 0 1 0 1.414l-4.5 4.5a1 1 0 0 1-1.414-1.414L11 8.5H1.5a1 1 0 0 1 0-2H11L8.293 3.707a1 1 0 0 1 0-1.414" />
          </svg>
          Back
        </button>
      </div>

      {/* --- ฝั่งขวา --- */}
      <div className="flex-1 bg-[#C7DCDE] flex items-center justify-center p-8">
        <div className="w-full max-w-md text-center">
          <h1 className="text-[#223248] text-5xl font-semibold mb-4">Verify OTP</h1>
          <p className="text-gray-600 mb-8">
            กรุณากรอกรหัส 6 หลักที่ส่งไปยัง <br />
            <span className="font-bold text-[#223248]">{email}</span>
          </p>

          {message && (
            <div className={`p-3 rounded-md text-center mb-6 text-white ${
              message.type === 'error' ? 'bg-red-500' : 'bg-green-500'
            }`}
            >
              {message.text}
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div className="flex justify-center gap-2 md:gap-4 mb-8">
              {otp.map((digit, index) => (
                <input
                  key={index}
                  ref={(el) => (inputRefs.current[index] = el)}
                  type="text"
                  maxLength={1}
                  value={digit}
                  onChange={(e) => handleChange(e, index)}
                  onKeyDown={(e) => handleKeyDown(e, index)}
                  className="w-12 h-14 md:w-14 md:h-16 text-center text-2xl md:text-3xl font-bold bg-white text-black rounded-md shadow-sm focus:ring-4 focus:ring-[#4FB7B3] focus:border-[#4FB7B3] transition-all duration-200"
                  required
                  disabled={isLoading}
                />
              ))}
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="w-[155px] h-[40px] bg-[#4FB7B3] hover:bg-[#3a9793] text-white font-bold rounded-[20px] transition-colors duration-200 flex items-center justify-center mx-auto shadow-md disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              {isLoading ? 'กำลังตรวจสอบ...' : 'Verify'}
            </button>
          </form>

          <div className="mt-6 text-sm">
            <span className="text-gray-600">ไม่ได้รับรหัส? </span>
            <button
              type="button"
              // onClick={handleResendOtp} // สามารถเพิ่มฟังก์ชันนี้ในอนาคต
              className="text-blue-500 hover:text-blue-700 font-semibold disabled:text-gray-400"
              disabled={isLoading}
            >
              ส่งรหัสอีกครั้ง
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}