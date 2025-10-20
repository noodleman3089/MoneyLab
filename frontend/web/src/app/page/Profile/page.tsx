'use client'
import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

interface UserData {
  username: string;
  age: number | null;
  email: string;
  registerDate: string;
  mainIncome: number | null;
  extraIncome: number | null;
  totalIncome: number | null;
}

export default function ProfilePage() {
  const router = useRouter();
  const [showNotifications, setShowNotifications] = useState<boolean>(false);
  const [showProfileMenu, setShowProfileMenu] = useState<boolean>(false);
  const [showSidebar, setShowSidebar] = useState<boolean>(false);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>('');

  const [userData, setUserData] = useState<UserData>({
    username: '',
    age: null,
    email: '',
    registerDate: '',
    mainIncome: null,
    extraIncome: null,
    totalIncome: null
  });

  //เก็บไว้ใช้ตอน fetch data จริง
//   useEffect(() => {
//     fetchUserProfile();
//     // eslint-disable-next-line react-hooks/exhaustive-deps
//   }, []);

//   const fetchUserProfile = async () => {
//     try {
//       setLoading(true);
//       setError('');

//       const token = localStorage.getItem('token');
//       if (!token) {
//         router.push('/page/login');
//         return;
//       }

//       const response = await fetch('http://localhost:4000/api/profile', {
//         method: 'GET',
//         headers: {
//           'Authorization': `Bearer ${token}`,
//           'Content-Type': 'application/json',
//         },
//       });

//       if (!response.ok) {
//         if (response.status === 401) {
//           localStorage.removeItem('token');
//           localStorage.removeItem('user');
//           router.push('/page/login');
//           return;
//         }
//         throw new Error('ไม่สามารถดึงข้อมูลโปรไฟล์ได้');
//       }

//       const data = await response.json();
//       setUserData({
//         username: data.username || '',
//         age: data.age || null,
//         email: data.email || '',
//         registerDate: data.createdAt ? new Date(data.createdAt).toLocaleDateString('th-TH', {
//           year: 'numeric',
//           month: 'long',
//           day: 'numeric'
//         }) : '',
//         mainIncome: data.mainIncome || null,
//         extraIncome: data.extraIncome || null,
//         totalIncome: data.totalIncome || null
//       });
//     } catch (err) {
//       setError(err instanceof Error ? err.message : 'เกิดข้อผิดพลาดในการโหลดข้อมูล');
//       console.error('Error fetching profile:', err);
//     } finally {
//       setLoading(false);
//     }
//   };

  //Code ชั่วคราว
  const handleNavigate = (path: string) => {
    router.push(path);
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    router.push('/page/login');
  };

  const handleEditProfile = () => {
    router.push('/page/edit-profile');
  };

  const formatCurrency = (amount: number | null) => {
    if (amount === null || amount === 0) return '-';
    return new Intl.NumberFormat('th-TH', {
      style: 'currency',
      currency: 'THB'
    }).format(amount);
  };

//   if (loading) {
//     return (
//       <div className="min-h-screen bg-white flex items-center justify-center">
//         <div className="text-center">
//           <div className="inline-block animate-spin rounded-full h-16 w-16 border-t-4 border-b-4 border-teal-500"></div>
//           <p className="mt-4 text-[#223248] font-be-vietnam-pro text-lg">กำลังโหลดข้อมูล...</p>
//         </div>
//       </div>
//     );
//   }

 const handleBack = () => {
    window.location.href = "/page/main";
  }

  return (
    <div className="min-h-screen bg-white flex flex-col">
      {error && (
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 mx-4 mt-4 rounded relative" role="alert">
          <strong className="font-bold">เกิดข้อผิดพลาด!</strong>
          <span className="block sm:inline"> {error}</span>
          <button
            onClick={() => setError('')}
            className="absolute top-0 bottom-0 right-0 px-4 py-3"
          >
            <span className="text-2xl">&times;</span>
          </button>
        </div>
      )}

      <header className="bg-teal-500 text-[#223248] py-4 px-6 flex items-center justify-between">
        <div className="text-[32px] font-extrabold font-be-vietnam-pro">MONEY LAB</div>
        <div className="flex items-center gap-4">
          <div className="relative">
            <button onClick={() => setShowNotifications(!showNotifications)} className="relative hover:bg-[#3a9793] p-2 rounded-full transition-colors duration-200">
              <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
                <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
              </svg>
              <span className="absolute top-1 right-1 bg-red-500 text-white text-xs font-bold rounded-full w-5 h-5 flex items-center justify-center">6</span>
            </button>
            {showNotifications && (
              <div className="absolute right-0 mt-2 w-80 bg-white rounded-lg shadow-lg z-50 p-4">
                <h3 className="text-[#223248] font-semibold mb-3 font-be-vietnam-pro">การแจ้งเตือน</h3>
                <div className="space-y-2">
                  <div className="p-3 bg-[#C7DCDE] rounded hover:bg-[#B8D4D6] cursor-pointer transition-colors duration-200">
                    <p className="text-sm text-[#223248] font-be-vietnam-pro">คุณมีรายจ่ายใหม่ที่ต้องบันทึก</p>
                    <p className="text-xs text-gray-600 mt-1">5 นาทีที่แล้ว</p>
                  </div>
                </div>
              </div>
            )}
          </div>
          <div className="relative">
            <button onClick={() => setShowProfileMenu(!showProfileMenu)} className="hover:bg-[#3a9793] p-2 rounded-full transition-colors duration-200">
              <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                <circle cx="12" cy="7" r="4"></circle>
              </svg>
            </button>
            {showProfileMenu && (
              <div className="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg z-50 py-2">
                <button onClick={() => handleNavigate('/page/Profile')} className="w-full text-left px-4 py-2 text-[#223248] hover:bg-[#C7DCDE] transition-colors duration-200 font-be-vietnam-pro">โปรไฟล์</button>
                <button onClick={() => handleNavigate('/page/Setting')} className="w-full text-left px-4 py-2 text-[#223248] hover:bg-[#C7DCDE] transition-colors duration-200 font-be-vietnam-pro">ตั้งค่า</button>
                <hr className="my-2" />
                <button onClick={handleLogout} className="w-full text-left px-4 py-2 text-red-600 hover:bg-red-50 transition-colors duration-200 font-be-vietnam-pro">ออกจากระบบ</button>
              </div>
            )}
          </div>
          <button onClick={() => setShowSidebar(!showSidebar)} className="hover:bg-[#3a9793] p-2 rounded transition-colors duration-200">
            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <line x1="3" y1="12" x2="21" y2="12"></line>
              <line x1="3" y1="6" x2="21" y2="6"></line>
              <line x1="3" y1="18" x2="21" y2="18"></line>
            </svg>
          </button>
        </div>
      </header>

      {showSidebar && (
        <>
          <div className="fixed inset-0 bg-black/50 z-40" onClick={() => setShowSidebar(false)}></div>
          <div className="fixed right-0 top-0 h-full w-64 bg-white shadow-lg z-50 transform transition-transform duration-300">
            <div className="p-6">
              <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl font-bold text-[#223248] font-be-vietnam-pro">เมนู</h2>
                <button onClick={() => setShowSidebar(false)} className="text-gray-500 hover:text-gray-700">
                  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                  </svg>
                </button>
              </div>
              <nav className="space-y-2">
                <button onClick={() => handleNavigate("/page/Main")} className="w-full text-left px-4 py-3 text-[#223248] hover:bg-[#C7DCDE] rounded transition-colors duration-200 font-be-vietnam-pro">หน้าหลัก</button>
                <button onClick={() => handleNavigate("/page/Set_Daily_Inco-Expe")} className="w-full text-left px-4 py-3 text-[#223248] hover:bg-[#C7DCDE] rounded transition-colors duration-200 font-be-vietnam-pro">วางแผนประจำวัน</button>
                <button onClick={() => handleNavigate("/page/Save_money")} className="w-full text-left px-4 py-3 text-[#223248] hover:bg-[#C7DCDE] rounded transition-colors duration-200 font-be-vietnam-pro">วางแผนเงินออม</button>
                <button onClick={() => handleNavigate("/page/Main")} className="w-full text-left px-4 py-3 text-[#223248] hover:bg-[#C7DCDE] rounded transition-colors duration-200 font-be-vietnam-pro">สรุปรายรับรายจ่าย</button>
                <button onClick={() => handleNavigate("/page/Main")} className="w-full text-left px-4 py-3 text-[#223248] hover:bg-[#C7DCDE] rounded transition-colors duration-200 font-be-vietnam-pro">ดูการลงทุน</button>
              </nav>
            </div>
          </div>
        </>
      )}

      <main className="container mx-auto px-4 py-8 flex-1">
        <div className="max-w-4xl mx-auto">
          <div className="bg-gradient-to-r from-[#4FB7B3] to-[#3a9793] rounded-xl p-6 md:p-8 mb-6 shadow-xl">
            <div className="flex flex-col md:flex-row items-center gap-6 mb-6">
              <div className="w-24 h-24 md:w-32 md:h-32 bg-white rounded-full flex items-center justify-center flex-shrink-0 shadow-lg border-4 border-white/50">
                <svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="#4FB7B3" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                  <circle cx="12" cy="7" r="4"></circle>
                </svg>
              </div>
              <div className="flex-1 text-center md:text-left">
                <h2 className="text-white text-3xl md:text-4xl font-bold font-be-vietnam-pro mb-2">{userData.username || 'ผู้ใช้งาน'}</h2>
                <p className="text-white/80 font-be-vietnam-pro">สมาชิก Money Lab</p>
              </div>
              <button
                onClick={handleEditProfile}
                className="bg-white hover:bg-gray-100 text-[#4FB7B3] font-semibold px-6 py-3 rounded-full transition-all duration-200 font-be-vietnam-pro shadow-lg hover:shadow-xl hover:scale-105 flex items-center gap-2 w-full md:w-auto justify-center"
              >
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                </svg>
                <span className="hidden sm:inline">แก้ไขโปรไฟล์</span>
                <span className="sm:hidden">แก้ไข</span>
              </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mt-6">
              <div className="bg-white/20 backdrop-blur-sm rounded-lg p-4 text-center">
                <div className="text-white/80 text-sm font-be-vietnam-pro mb-1">สมาชิกเมื่อ</div>
                <div className="text-white text-base md:text-lg font-bold font-be-vietnam-pro">{userData.registerDate || '-'}</div>
              </div>
              <div className="bg-white/20 backdrop-blur-sm rounded-lg p-4 text-center">
                <div className="text-white/80 text-sm font-be-vietnam-pro mb-1">อีเมล</div>
                <div className="text-white text-sm font-semibold font-be-vietnam-pro truncate">{userData.email || '-'}</div>
              </div>
              <div className="bg-white/20 backdrop-blur-sm rounded-lg p-4 text-center">
                <div className="text-white/80 text-sm font-be-vietnam-pro mb-1">อายุ</div>
                <div className="text-white text-base md:text-lg font-bold font-be-vietnam-pro">{userData.age ? `${userData.age} ปี` : '-'}</div>
              </div>
            </div>
          </div>

          <div className="bg-[#C7DCDE] rounded-lg p-8 mb-6 shadow-md">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-[#223248] text-xl font-bold font-be-vietnam-pro flex items-center gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                  <circle cx="12" cy="7" r="4"></circle>
                </svg>
                ข้อมูลบัญชีผู้ใช้
              </h3>
              <button
                onClick={handleBack} //fetchUserProfile (เปลี่ยนเป็นฟังก์ชันรีเฟรชข้อมูลจริงเมื่อเปิดใช้งาน)
                disabled={loading}
                className="text-[#4FB7B3] hover:text-[#3a9793] transition-colors p-2 rounded-full hover:bg-white/50 disabled:opacity-50"
                title="รีเฟรชข้อมูล"
              >
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={loading ? 'animate-spin' : ''}>
                  <polyline points="23 4 23 10 17 10"></polyline>
                  <polyline points="1 20 1 14 7 14"></polyline>
                  <path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"></path>
                </svg>
              </button>
            </div>
            <div className="space-y-4 text-[#223248] font-be-vietnam-pro">
              <div className="flex items-center justify-between p-3 bg-white/50 rounded-lg hover:bg-white/80 transition-colors">
                <span className="font-semibold flex items-center gap-2">
                  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                    <line x1="16" y1="2" x2="16" y2="6"></line>
                    <line x1="8" y1="2" x2="8" y2="6"></line>
                    <line x1="3" y1="10" x2="21" y2="10"></line>
                  </svg>
                  อายุ
                </span>
                <span className="text-gray-700">{userData.age ? `${userData.age} ปี` : 'ไม่ได้ระบุ'}</span>
              </div>
              <div className="flex items-center justify-between p-3 bg-white/50 rounded-lg hover:bg-white/80 transition-colors">
                <span className="font-semibold flex items-center gap-2">
                  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"></path>
                    <polyline points="22,6 12,13 2,6"></polyline>
                  </svg>
                  อีเมล
                </span>
                <span className="text-gray-700">{userData.email || 'ไม่ได้ระบุ'}</span>
              </div>
              <div className="flex items-center justify-between p-3 bg-white/50 rounded-lg hover:bg-white/80 transition-colors">
                <span className="font-semibold flex items-center gap-2">
                  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <circle cx="12" cy="12" r="10"></circle>
                    <polyline points="12 6 12 12 16 14"></polyline>
                  </svg>
                  สมัครใช้งานวันที่
                </span>
                <span className="text-gray-700">{userData.registerDate || 'ไม่ทราบ'}</span>
              </div>
            </div>

            <h3 className="text-[#223248] text-xl font-bold mt-8 mb-6 font-be-vietnam-pro flex items-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <line x1="12" y1="1" x2="12" y2="23"></line>
                <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path>
              </svg>
              รายรับต่อเดือน
            </h3>
            <div className="space-y-4 text-[#223248] font-be-vietnam-pro">
              <div className="flex items-center justify-between p-3 bg-white/50 rounded-lg hover:bg-white/80 transition-colors">
                <span className="font-semibold">รายรับหลัก</span>
                <span className="text-lg font-bold text-green-700">{formatCurrency(userData.mainIncome)}</span>
              </div>
              <div className="flex items-center justify-between p-3 bg-white/50 rounded-lg hover:bg-white/80 transition-colors">
                <span className="font-semibold">รายรับเสริม</span>
                <span className="text-lg font-bold text-green-600">{formatCurrency(userData.extraIncome)}</span>
              </div>
              <div className="flex items-center justify-between p-4 bg-[#4FB7B3] rounded-lg shadow-lg">
                <span className="font-bold text-white">รวมต่อเดือน</span>
                <span className="text-xl font-extrabold text-white">{formatCurrency(userData.totalIncome)}</span>
              </div>
            </div>
          </div>
        </div>
      </main>

      <footer className="bg-teal-500 text-[#223248] text-center py-4 mt-auto">
        <p className="text-sm font-be-vietnam-pro font-semibold">Copyright 2025 © RMUTTO</p>
      </footer>
    </div>
  );
}
