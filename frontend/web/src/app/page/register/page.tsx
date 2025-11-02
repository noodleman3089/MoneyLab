// 1. Importing Dependencies
'use client' // ต้องใช้เพราะใช้ useState และ window, localStorage
import React, { useState, FormEvent } from 'react'
import { useRouter } from 'next/navigation'; // 👈 1. Import useRouter สำหรับเปลี่ยนหน้า
import { registerUser } from '@/app/services/authService'; // 👈 2. Import service ที่ถูกต้อง

// 2. Creating and Exporting a Component
export default function RegisterPage() {

  // 2.1 Defining Variables and State, and Handlers

  const [username, setUsername] = useState<string>("");
  const router = useRouter(); // 👈 3. สร้าง instance ของ router
  const [email, setEmail] = useState<string>("");
  const [phone_number, setphone_number] = useState<string>("");
  const [password, setPassword] = useState<string>("");
  const [confirmPassword, setConfirmPassword] = useState<string>("");
  const [acceptTerms, setAcceptTerms] = useState<boolean>(false);
  const [showTermsModal, setShowTermsModal] = useState<boolean>(false);
  const [showPrivacyModal, setShowPrivacyModal] = useState<boolean>(false);
  // --- State สำหรับจัดการ Loading และ Messages ---
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  // สร้างฟังก์ชันสำหรับจัดการการ submit form ไปยัง API
  // โดยใช้ async/await เพื่อจัดการกับการเรียก API แบบ asynchronous
  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault(); // ป้องกัน reload หน้า
    setMessage(null); // เคลียร์ข้อความเก่า

    // ตรวจสอบว่ากดติ๊กถูกที่ Terms and Conditions หรือยัง
    if (!acceptTerms) {
      setMessage({ type: 'error', text: 'กรุณายอมรับเงื่อนไขการใช้งานและนโยบายความเป็นส่วนตัว' });
      return;
    }

    // ตรวจสอบว่า password ตรงกับ confirmPassword หรือไม่
    if (password !== confirmPassword) {
      setMessage({ type: 'error', text: 'รหัสผ่านและยืนยันรหัสผ่านไม่ตรงกัน' });
      return;
    }

    setIsLoading(true);

    try{
      // 👈 4. [REFACTORED] เรียกใช้ Service ที่เราสร้างไว้
      const result = await registerUser({
        username,
        password,
        confirmPassword,
        email,
        phone_number
      });

      if(result.status === true) {
        // 👈 5. [FIXED LOGIC] ส่งไปหน้า Verify OTP พร้อมกับส่ง email ไปด้วย
        router.push(`/page/otp?email=${encodeURIComponent(email)}`);
      } else {
        setMessage({ type: 'error', text: result.message || 'การลงทะเบียนล้มเหลว' });
      }
    } catch (error) {
      console.error("Registration error:", error); // แสดงข้อผิดพลาดใน console
      setMessage({ type: 'error', text: 'เกิดข้อผิดพลาดที่ไม่คาดคิด กรุณาลองอีกครั้ง' });
    } finally {
      setIsLoading(false);
    }
  };

    // Code ชั่วคราว
  const handleGoogleSignIn = () => {
    // Handle Google sign-in logic here
    console.log('Google sign-in clicked')
  }

  const handleBack = () => {
    window.location.href = "/page/login";
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
          <h1 className="text-[#223248] text-5xl font-semibold mb-8 text-center font-be-vietnam-pro">Sign Up</h1>

          {/* 👈 6. [NEW] ส่วนแสดงข้อความ Success/Error */}
          {message && (
            <div className={`p-3 rounded-md text-center mb-4 text-white font-be-vietnam-pro ${
              message.type === 'error' ? 'bg-red-500' : 'bg-green-500'
            }`}
            >
              {message.text}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
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
              type="email"
              name="email"
              placeholder="Email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-3 rounded-sm outline-none border-none bg-white text-black placeholder-gray-500 focus:ring-4 focus:ring-[#4FB7B3] transition-all duration-200 shadow-sm shadow-[#9CAAD6] font-be-vietnam-pro"
              required
            />

            <input
              type="tel"
              name="phone_number"
              placeholder="Phone Numbers"
              value={phone_number}
              onChange={(e) => setphone_number(e.target.value)}
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

            <input
              type="password"
              name="confirmPassword"
              placeholder="Confirm passwords"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              className="w-full px-4 py-3 rounded-sm outline-none border-none bg-white text-black placeholder-gray-500 focus:ring-4 focus:ring-[#4FB7B3] transition-all duration-200 shadow-sm shadow-[#9CAAD6] font-be-vietnam-pro"
              required
            />

            <div className="flex items-center gap-3 mt-6">
              <input
                type="checkbox"
                id="terms"
                checked={acceptTerms}
                onChange={(e) => setAcceptTerms(e.target.checked)}
                className="w-4 h-4 text-[#008170] bg-[#C7DCDE] border-[#20C997] rounded focus:ring-[#20C997]"
              />
              <label htmlFor="terms" className="text-[#223248] text-sm font-be-vietnam-pro">
                I accept{' '}
                <button
                  type="button"
                  onClick={() => setShowTermsModal(true)}
                  className="text-blue-500 hover:text-blue-700 text-base font-semibold transition-all duration-200"
                >
                  Terms of Use
                </button>
                {' '}and{' '}
                <button
                  type="button"
                  onClick={() => setShowPrivacyModal(true)}
                  className="text-blue-500 hover:text-blue-700 text-base font-semibold transition-all duration-200"
                >
                  Privacy Policy
                </button>
              </label>
            </div>

            <button
              type="submit"
              disabled={isLoading} // 👈 7. ปิดปุ่มตอนโหลด
              className="w-[155px] h-[40px] bg-[#4FB7B3] hover:bg-[#3a9793] text-white font-bold rounded-[20px] mt-6 transition-colors duration-200 font-be-vietnam-pro flex items-center justify-center mx-auto shadow-md disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              {isLoading ? 'กำลังลงทะเบียน...' : 'Register'}
            </button>

            <div className="text-center mt-4">
              <span className="text-[#223248] text-base font-be-vietnam-pro">or</span>
            </div>

            <button
              type="button"
              onClick={handleGoogleSignIn}
              className="w-[155px] h-[40px] bg-white hover:bg-[#C7DCDE] text-gray-700 hover:text-[#008170] font-bold rounded-[20px] hover:border-2 hover:border-[#4FB7B3] hover:shadow-none mt-4 gap-2 transition-colors duration-200 font-be-vietnam-pro flex items-center justify-center mx-auto shadow-md"
            >
              <svg className="w-5 h-5" viewBox="0 0 24 24">
                <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
              </svg>
              Google
            </button>
          </form>
        </div>
      </div>

      {/* Terms of Use Modal */}
      {showTermsModal && (
        <div className="fixed inset-0 bg-white/10 backdrop-blur-md flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-2xl w-full max-h-[80vh] overflow-y-auto p-6">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-2xl font-bold text-[#223248] font-be-vietnam-pro">เงื่อนไขการใช้งาน</h2>
              <button
                type="button"
                onClick={() => setShowTermsModal(false)}
                className="text-gray-500 hover:text-gray-700 text-2xl"
              >
                ×
              </button>
            </div>
            <div className="text-[#223248] space-y-4 font-be-vietnam-pro">
              <p>ยินดีต้อนรับสู่ MoneyLab กรุณาอ่านเงื่อนไขการใช้งานเหล่านี้อย่างละเอียดก่อนใช้บริการของเรา</p>

              <h3 className="font-semibold mt-4">1. การยอมรับเงื่อนไข</h3>
              <p>การใช้บริการของเราถือว่าคุณยอมรับและตกลงที่จะปฏิบัติตามเงื่อนไขการใช้งานทั้งหมด</p>

              <h3 className="font-semibold mt-4">2. การใช้บริการ</h3>
              <p>คุณตกลงที่จะใช้บริการเพื่อวัตถุประสงค์ที่ถูกต้องตามกฎหมายเท่านั้น</p>

              <h3 className="font-semibold mt-4">3. ความรับผิดชอบของผู้ใช้</h3>
              <p>ผู้ใช้มีหน้าที่รับผิดชอบในการรักษาความปลอดภัยของบัญชีและรหัสผ่านของตนเอง</p>

              <h3 className="font-semibold mt-4">4. การเปลี่ยนแปลงเงื่อนไข</h3>
              <p>เราขอสงวนสิทธิ์ในการเปลี่ยนแปลงเงื่อนไขการใช้งานได้ตลอดเวลา</p>
            </div>
            <button
              type="button"
              onClick={() => setShowTermsModal(false)}
              className="mt-6 w-full bg-[#4FB7B3] hover:bg-[#3a9793] text-white font-bold py-2 px-4 rounded font-be-vietnam-pro"
            >
              ปิด
            </button>
          </div>
        </div>
      )}

      {/* Privacy Policy Modal */}
      {showPrivacyModal && (
        <div className="fixed inset-0 bg-white/10 backdrop-blur-md flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-2xl w-full max-h-[80vh] overflow-y-auto p-6">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-2xl font-bold text-[#223248] font-be-vietnam-pro">นโยบายความเป็นส่วนตัว</h2>
              <button
                type="button"
                onClick={() => setShowPrivacyModal(false)}
                className="text-gray-500 hover:text-gray-700 text-2xl"
              >
                ×
              </button>
            </div>
            <div className="text-[#223248] space-y-4 font-be-vietnam-pro">
              <p>เราให้ความสำคัญกับความเป็นส่วนตัวของคุณ นโยบายนี้อธิบายว่าเราจัดการข้อมูลส่วนบุคคลของคุณอย่างไร</p>

              <h3 className="font-semibold mt-4">1. การเก็บรวบรวมข้อมูล</h3>
              <p>เราเก็บรวบรวมข้อมูลที่คุณให้ไว้เมื่อลงทะเบียนและใช้บริการของเรา รวมถึงชื่อผู้ใช้ อีเมล และเบอร์โทรศัพท์</p>

              <h3 className="font-semibold mt-4">2. การใช้ข้อมูล</h3>
              <p>ข้อมูลของคุณจะถูกใช้เพื่อให้บริการและปรับปรุงประสบการณ์การใช้งานของคุณ</p>

              <h3 className="font-semibold mt-4">3. การปกป้องข้อมูล</h3>
              <p>เราใช้มาตรการรักษาความปลอดภัยเพื่อปกป้องข้อมูลส่วนบุคคลของคุณ</p>

              <h3 className="font-semibold mt-4">4. การแบ่งปันข้อมูล</h3>
              <p>เราจะไม่แบ่งปันข้อมูลส่วนบุคคลของคุณกับบุคคลที่สามโดยไม่ได้รับความยินยอมจากคุณ</p>
            </div>
            <button
              type="button"
              onClick={() => setShowPrivacyModal(false)}
              className="mt-6 w-full bg-[#4FB7B3] hover:bg-[#3a9793] text-white font-bold py-2 px-4 rounded font-be-vietnam-pro"
            >
              ปิด
            </button>
          </div>
        </div>
      )}
    </div>
  )
}