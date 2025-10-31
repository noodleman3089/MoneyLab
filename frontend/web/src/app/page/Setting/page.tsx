// 1. Importing Dependencies
'use client' // ต้องใช้เพราะใช้ useState และ window, localStorage
import React, { useState } from 'react';
import { useRouter } from 'next/navigation';

// 2. Creating and Exporting a Component
export default function SettingPage() {

  // 2.1 Defining Variables, States, and Handlers
  const router = useRouter();
  const [showNotifications, setShowNotifications] = useState<boolean>(false);
  const [showProfileMenu, setShowProfileMenu] = useState<boolean>(false);
  const [showSidebar, setShowSidebar] = useState<boolean>(false);

  // ข้อมูลผู้ใช้ตัวอย่าง (ควรดึงจาก API หรือ localStorage จริงๆ)
  const [username] = useState<string>("PeakPeak999");

  // ฟังก์ชันสำหรับเปลี่ยนหน้าไปยังแต่ละเมนู
  const handleNavigate = (path: string) => {
    router.push(path);
  };

  // ฟังก์ชัน Logout
  const handleLogout = () => {
    // ลบข้อมูลจาก localStorage
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    // เปลี่ยนหน้าไปที่ login
    router.push('/page/login');
  };

  return (
    <div className="min-h-screen bg-white flex flex-col">
      {/* Header */}
      <header className="bg-teal-500 text-[#223248] py-4 px-6 flex items-center justify-between">
        <div className="text-[32px] font-extrabold font-be-vietnam-pro">MONEY LAB</div>

        <div className="flex items-center gap-4">
          {/* Notification Icon */}
          <div className="relative">
            <button
              onClick={() => setShowNotifications(!showNotifications)}
              className="relative hover:bg-[#3a9793] p-2 rounded-full transition-colors duration-200"
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
                <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
              </svg>
              {/* Notification Badge */}
              <span className="absolute top-1 right-1 bg-red-500 text-white text-xs font-bold rounded-full w-5 h-5 flex items-center justify-center">
                6
              </span>
            </button>

            {/* Notifications Dropdown */}
            {showNotifications && (
              <div className="absolute right-0 mt-2 w-80 bg-white rounded-lg shadow-lg z-50 p-4">
                <h3 className="text-[#223248] font-semibold mb-3 font-be-vietnam-pro">การแจ้งเตือน</h3>
                <div className="space-y-2">
                  <div className="p-3 bg-[#C7DCDE] rounded hover:bg-[#B8D4D6] cursor-pointer transition-colors duration-200">
                    <p className="text-sm text-[#223248] font-be-vietnam-pro">คุณมีรายจ่ายใหม่ที่ต้องบันทึก</p>
                    <p className="text-xs text-gray-600 mt-1">5 นาทีที่แล้ว</p>
                  </div>
                  <div className="p-3 bg-[#C7DCDE] rounded hover:bg-[#B8D4D6] cursor-pointer transition-colors duration-200">
                    <p className="text-sm text-[#223248] font-be-vietnam-pro">เป้าหมายการออมของคุณใกล้บรรลุแล้ว!</p>
                    <p className="text-xs text-gray-600 mt-1">1 ชั่วโมงที่แล้ว</p>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Profile Icon */}
          <div className="relative">
            <button
              onClick={() => setShowProfileMenu(!showProfileMenu)}
              className="hover:bg-[#3a9793] p-2 rounded-full transition-colors duration-200"
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                <circle cx="12" cy="7" r="4"></circle>
              </svg>
            </button>

            {/* Profile Dropdown */}
            {showProfileMenu && (
              <div className="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg z-50 py-2">
                <button
                  onClick={() => handleNavigate('/page/Profile')}
                  className="w-full text-left px-4 py-2 text-[#223248] hover:bg-[#C7DCDE] transition-colors duration-200 font-be-vietnam-pro"
                >
                  โปรไฟล์
                </button>
                <button
                  onClick={() => handleNavigate('/page/Setting')}
                  className="w-full text-left px-4 py-2 text-[#223248] hover:bg-[#C7DCDE] transition-colors duration-200 font-be-vietnam-pro"
                >
                  ตั้งค่า
                </button>
                <hr className="my-2" />
                <button
                  onClick={handleLogout}
                  className="w-full text-left px-4 py-2 text-red-600 hover:bg-red-50 transition-colors duration-200 font-be-vietnam-pro"
                >
                  ออกจากระบบ
                </button>
              </div>
            )}
          </div>

          {/* Hamburger Menu */}
          <button
            onClick={() => setShowSidebar(!showSidebar)}
            className="hover:bg-[#3a9793] p-2 rounded transition-colors duration-200"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <line x1="3" y1="12" x2="21" y2="12"></line>
              <line x1="3" y1="6" x2="21" y2="6"></line>
              <line x1="3" y1="18" x2="21" y2="18"></line>
            </svg>
          </button>
        </div>
      </header>

      {/* Sidebar Menu */}
      {showSidebar && (
        <>
          {/* Overlay */}
          <div
            className="fixed inset-0 bg-black/50 z-40"
            onClick={() => setShowSidebar(false)}
          ></div>

          {/* Sidebar */}
          <div className="fixed right-0 top-0 h-full w-64 bg-white shadow-lg z-50 transform transition-transform duration-300">
            <div className="p-6">
              <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl font-bold text-[#223248] font-be-vietnam-pro">เมนู</h2>
                <button
                  onClick={() => setShowSidebar(false)}
                  className="text-gray-500 hover:text-gray-700"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                  </svg>
                </button>
              </div>

              <nav className="space-y-2">
                {/* หน้าหลัก */}
                <button
                  onClick={() => handleNavigate("/page/Main")}
                  className="w-full text-left px-4 py-3 text-[#223248] hover:bg-[#C7DCDE] rounded transition-colors duration-200 font-be-vietnam-pro"
                >
                  หน้าหลัก
                </button>

                {/* วางแผนประจำวัน */}
                <button
                  onClick={() => handleNavigate("/page/Set_Daily_Inco-Expe")}
                  className="w-full text-left px-4 py-3 text-[#223248] hover:bg-[#C7DCDE] rounded transition-colors duration-200 font-be-vietnam-pro"
                >
                  วางแผนประจำวัน
                </button>

                {/* วางแผนเงินออม */}
                <button
                  onClick={() => handleNavigate("/page/Save_money")}
                  className="w-full text-left px-4 py-3 text-[#223248] hover:bg-[#C7DCDE] rounded transition-colors duration-200 font-be-vietnam-pro"
                >
                  วางแผนเงินออม
                </button>

                {/* สรุปรายรับรายจ่าย */}
                <button
                  onClick={() => handleNavigate("/page/Main")}
                  className="w-full text-left px-4 py-3 text-[#223248] hover:bg-[#C7DCDE] rounded transition-colors duration-200 font-be-vietnam-pro"
                >
                  สรุปรายรับรายจ่าย
                </button>

                {/* ดูการลงทุน */}
                <button
                  onClick={() => handleNavigate("/page/Main")}
                  className="w-full text-left px-4 py-3 text-[#223248] hover:bg-[#C7DCDE] rounded transition-colors duration-200 font-be-vietnam-pro"
                >
                  ดูการลงทุน
                </button>

              </nav>
            </div>
          </div>
        </>
      )}

      {/* Main Content */}
      <main className="container mx-auto px-4 py-8 flex-1 max-w-3xl">
        {/* Profile Section */}
        <div className="bg-[#C7DCDE] rounded-xl p-6 mb-6 flex items-center gap-6 shadow-md">
          {/* Profile Icon */}
          <div className="w-20 h-20 bg-[#2d3e50] rounded-full flex items-center justify-center flex-shrink-0 shadow-lg">
            <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
              <circle cx="12" cy="7" r="4"></circle>
            </svg>
          </div>
          {/* Username */}
          <div className="flex-1">
            <h2 className="text-[#223248] text-2xl font-bold font-be-vietnam-pro">{username}</h2>
          </div>
        </div>

        {/* Settings List */}
        <div className="space-y-3">
          {/* บัญชี Section */}
          <div className="bg-white border-l-4 border-[#223248] rounded-r-lg shadow-sm">
            <h3 className="text-[#223248] text-lg font-bold font-be-vietnam-pro px-6 py-3 bg-[#C7DCDE] rounded-tr-lg">
              บัญชี
            </h3>
            <button
              onClick={() => handleNavigate('/page/Change_Password')}
              className="w-full text-left px-6 py-4 text-[#223248] hover:bg-[#C7DCDE]/30 transition-colors duration-200 font-be-vietnam-pro flex items-center justify-between group"
            >
              <span className="flex items-center gap-3">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                  <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                </svg>
                เปลี่ยนรหัสผ่าน
              </span>
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="group-hover:translate-x-1 transition-transform">
                <polyline points="9 18 15 12 9 6"></polyline>
              </svg>
            </button>
          </div>

          {/* จัดการเก็บ Section */}
          <div className="bg-white border-l-4 border-[#223248] rounded-r-lg shadow-sm">
            <h3 className="text-[#223248] text-lg font-bold font-be-vietnam-pro px-6 py-3 bg-[#C7DCDE] rounded-tr-lg">
              จัดการเก็บ
            </h3>
            <button
              onClick={() => handleNavigate('/page/Manage_Savings')}
              className="w-full text-left px-6 py-4 text-[#223248] hover:bg-[#C7DCDE]/30 transition-colors duration-200 font-be-vietnam-pro flex items-center justify-between group"
            >
              <span className="flex items-center gap-3">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <line x1="12" y1="1" x2="12" y2="23"></line>
                  <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path>
                </svg>
                สร้าง / แก้ไขเก็บ
              </span>
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="group-hover:translate-x-1 transition-transform">
                <polyline points="9 18 15 12 9 6"></polyline>
              </svg>
            </button>
          </div>

          {/* การแจ้งเตือน Section */}
          <div className="bg-white border-l-4 border-[#223248] rounded-r-lg shadow-sm">
            <h3 className="text-[#223248] text-lg font-bold font-be-vietnam-pro px-6 py-3 bg-[#C7DCDE] rounded-tr-lg">
              การแจ้งเตือน
            </h3>
            <button
              onClick={() => handleNavigate('/page/Notification_Settings')}
              className="w-full text-left px-6 py-4 text-[#223248] hover:bg-[#C7DCDE]/30 transition-colors duration-200 font-be-vietnam-pro flex items-center justify-between group"
            >
              <span className="flex items-center gap-3">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
                  <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
                </svg>
                เปิด/ปิดการแจ้งเตือนเมื่อใช้เงินเกิน
              </span>
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="group-hover:translate-x-1 transition-transform">
                <polyline points="9 18 15 12 9 6"></polyline>
              </svg>
            </button>
          </div>

          {/* ตั้งค่าทั่วไป Section */}
          <div className="bg-white border-l-4 border-[#223248] rounded-r-lg shadow-sm">
            <h3 className="text-[#223248] text-lg font-bold font-be-vietnam-pro px-6 py-3 bg-[#C7DCDE] rounded-tr-lg">
              ตั้งค่าทั่วไป
            </h3>
            <button
              onClick={() => handleNavigate('/page/General_Settings')}
              className="w-full text-left px-6 py-4 text-[#223248] hover:bg-[#C7DCDE]/30 transition-colors duration-200 font-be-vietnam-pro flex items-center justify-between group"
            >
              <span className="flex items-center gap-3">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <circle cx="12" cy="12" r="3"></circle>
                  <path d="M12 1v6m0 6v6m8.66-10.5l-5.2 3M8.54 14l-5.2 3m13.32 0l-5.2-3M8.54 10l-5.2-3"></path>
                </svg>
                เปลี่ยนภาษา / โหมด / จังหวะ
              </span>
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="group-hover:translate-x-1 transition-transform">
                <polyline points="9 18 15 12 9 6"></polyline>
              </svg>
            </button>
          </div>
        </div>

        {/* Logout Button */}
        <div className="mt-8 flex justify-center">
          <button
            onClick={handleLogout}
            className="bg-teal-500 hover:bg-teal-600 text-white font-bold font-be-vietnam-pro px-12 py-3 rounded-full shadow-lg hover:shadow-xl transition-all duration-200 flex items-center gap-2"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
              <polyline points="16 17 21 12 16 7"></polyline>
              <line x1="21" y1="12" x2="9" y2="12"></line>
            </svg>
            Logout
          </button>
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-teal-500 text-[#223248] text-center py-4 mt-8">
        <p className="text-sm font-be-vietnam-pro font-semibold">Copyright 2025 © RMUTTO</p>
      </footer>
    </div>
  );
}
