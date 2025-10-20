// 1. Importing Dependencies
'use client' // ต้องใช้เพราะใช้ useState และ window, localStorage
import React, { useState, FormEvent } from 'react';
import axios from "axios";

// Interfaces
interface Transaction {
  id: string;
  date: string;
  category: string;
  description: string;
  amount: number;
  type: 'income' | 'expense';
}

interface CategoryBudget {
  id: string;
  name: string;
  allocated: number;
  spent: number;
  color: string;
}

// 2. Creating and Exporting a Component
export default function SetDailyIncoExpePage() {

  // 2.1 Defining Variables, States, and Handlers
  const [showNotifications, setShowNotifications] = useState<boolean>(false);
  const [showProfileMenu, setShowProfileMenu] = useState<boolean>(false);
  const [showSidebar, setShowSidebar] = useState<boolean>(false);

  // Modal states
  const [showAddTransactionModal, setShowAddTransactionModal] = useState<boolean>(false);
  const [showEditBudgetModal, setShowEditBudgetModal] = useState<boolean>(false);
  const [selectedDate, setSelectedDate] = useState<string>(new Date().toISOString().split('T')[0]);

  // Budget settings
  const [dailyGoal, setDailyGoal] = useState<number>(1000);
  const [balance, setBalance] = useState<number>(1500);

  // Transactions (Mock data - แทนที่ด้วย API call)
  const [transactions] = useState<Transaction[]>([
    { id: '1', date: '2025-10-20', category: 'รายได้เสริม', description: 'ฟรีแลนซ์', amount: 50, type: 'income' },
    { id: '2', date: '2025-10-20', category: 'อาหาร', description: 'ข้าวเช้า', amount: 80, type: 'expense' },
    { id: '3', date: '2025-10-20', category: 'ขนส่ง', description: 'ค่ารถเมล์', amount: 40, type: 'expense' },
    { id: '4', date: '2025-10-20', category: 'อาหาร', description: 'อาหารกลางวัน', amount: 120, type: 'expense' },
    { id: '5', date: '2025-10-20', category: 'บันเทิง', description: 'กาแฟ', amount: 60, type: 'expense' },
    { id: '6', date: '2025-10-20', category: 'ขนส่ง', description: 'น้ำมันรถ', amount: 200, type: 'expense' },
    { id: '7', date: '2025-10-19', category: 'อาหาร', description: 'ข้าวเย็น', amount: 150, type: 'expense' },
    { id: '8', date: '2025-10-19', category: 'รายได้เสริม', description: 'ขายของออนไลน์', amount: 300, type: 'income' },
  ]);

  // Category budgets (Mock data - แทนที่ด้วย API call)
  const [categoryBudgets] = useState<CategoryBudget[]>([
    { id: '1', name: 'อาหาร', allocated: 300, spent: 200, color: '#FF6B9D' },
    { id: '2', name: 'ขนส่ง', allocated: 200, spent: 120, color: '#4FB7B3' },
    { id: '3', name: 'บันเทิง', allocated: 500, spent: 60, color: '#FFB84D' },
  ]);

  // Form state สำหรับเพิ่มรายการใหม่
  const [newTransaction, setNewTransaction] = useState({
    type: 'expense' as 'income' | 'expense',
    category: '',
    description: '',
    amount: ''
  });

  // Calculate totals for selected date
  const getTransactionsForDate = (date: string) => {
    return transactions.filter(t => t.date === date);
  };

  const calculateIncome = (date: string) => {
    return getTransactionsForDate(date)
      .filter(t => t.type === 'income')
      .reduce((sum, t) => sum + t.amount, 0);
  };

  const calculateExpense = (date: string) => {
    return getTransactionsForDate(date)
      .filter(t => t.type === 'expense')
      .reduce((sum, t) => sum + t.amount, 0);
  };

  const todayIncome = calculateIncome(selectedDate);
  const todayExpense = calculateExpense(selectedDate);
  const currentExpense = todayExpense;

  // ฟังก์ชันสำหรับคำนวณเปอร์เซ็นต์
  const calculatePercentage = () => {
    if (dailyGoal === 0) return 0;
    return Math.min(100, Math.round((currentExpense / dailyGoal) * 100));
  };

  // Calculate gauge rotation (0 to 180 degrees for semi-circle)
  const getGaugeRotation = () => {
    const percentage = calculatePercentage();
    return -90 + (percentage / 100) * 180;
  };

  // Group transactions by date for display
  const getUniqueTransactionDates = () => {
    const dates = [...new Set(transactions.map(t => t.date))];
    return dates.sort((a, b) => new Date(b).getTime() - new Date(a).getTime());
  };

  // Format date for display
  const formatDateThai = (dateString: string) => {
    const date = new Date(dateString);
    const days = ['อาทิตย์', 'จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์'];
    const months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];

    return {
      day: days[date.getDay()],
      date: date.getDate(),
      month: months[date.getMonth()],
      fullDate: `${date.getDate()} ${months[date.getMonth()]} ${date.getFullYear() + 543}`
    };
  };

  // Handle add transaction
  const handleAddTransaction = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    if (!newTransaction.category || !newTransaction.description || !newTransaction.amount) {
      alert('กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }

    // เตรียม API call (ยังไม่เรียกจริง)
    /*
    try {
      const response = await axios.post('http://localhost:4000/api/transactions', {
        date: selectedDate,
        category: newTransaction.category,
        description: newTransaction.description,
        amount: parseFloat(newTransaction.amount),
        type: newTransaction.type
      }, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });

      // Update transactions list
      setTransactions([...transactions, response.data]);
      setShowAddTransactionModal(false);
      resetForm();
      alert('เพิ่มรายการสำเร็จ!');
    } catch (error) {
      console.error('Error adding transaction:', error);
      alert('เกิดข้อผิดพลาดในการเพิ่มรายการ');
    }
    */

    // For now, just close modal
    setShowAddTransactionModal(false);
    resetForm();
    alert('ฟังก์ชันนี้จะทำงานเมื่อเชื่อมต่อกับ Backend');
  };

  const resetForm = () => {
    setNewTransaction({
      type: 'expense',
      category: '',
      description: '',
      amount: ''
    });
  };

  // Handle delete transaction
  const handleDeleteTransaction = async (id: string) => {
    if (!confirm('คุณต้องการลบรายการนี้หรือไม่?')) return;

    // เตรียม API call (ยังไม่เรียกจริง)
    /*
    try {
      await axios.delete(`http://localhost:4000/api/transactions/${id}`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });

      setTransactions(transactions.filter(t => t.id !== id));
      alert('ลบรายการสำเร็จ!');
    } catch (error) {
      console.error('Error deleting transaction:', error);
      alert('เกิดข้อผิดพลาดในการลบรายการ');
    }
    */

    alert('ฟังก์ชันนี้จะทำงานเมื่อเชื่อมต่อกับ Backend');
  };

  // ฟังก์ชันสำหรับเปลี่ยนหน้าไปยังแต่ละเมนู
  const handleNavigate = (path: string) => {
    window.location.href = path;
  };

  // ฟังก์ชัน Logout
  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    window.location.href = '/page/login';
  };

  return (
    <div className="min-h-screen bg-white flex flex-col">
      {/* Header */}
      <header className="bg-teal-500 text-[#223248] py-4 px-6 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() => handleNavigate('/page/Main')}
            className="text-[#223248] hover:text-white transition-colors duration-200"
          >
            <svg className="rotate-180" xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 15 15">
              <path fill="currentColor" d="M8.293 2.293a1 1 0 0 1 1.414 0l4.5 4.5a1 1 0 0 1 0 1.414l-4.5 4.5a1 1 0 0 1-1.414-1.414L11 8.5H1.5a1 1 0 0 1 0-2H11L8.293 3.707a1 1 0 0 1 0-1.414" />
            </svg>
          </button>
          <div className="text-2xl font-bold font-be-vietnam-pro">MONEY LAB</div>
        </div>

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
              <span className="absolute top-1 right-1 bg-red-500 text-white text-xs font-bold rounded-full w-5 h-5 flex items-center justify-center">
                2
              </span>
            </button>

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
          <div
            className="fixed inset-0 bg-black/50 z-40"
            onClick={() => setShowSidebar(false)}
          ></div>

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
                <button
                  onClick={() => handleNavigate("/page/Main")}
                  className="w-full text-left px-4 py-3 text-[#223248] hover:bg-[#C7DCDE] rounded transition-colors duration-200 font-be-vietnam-pro"
                >
                  หน้าหลัก
                </button>
                <button
                  onClick={() => handleNavigate("/page/Set_Daily_Inco-Expe")}
                  className="w-full text-left px-4 py-3 text-[#223248] bg-[#C7DCDE] rounded hover:bg-[#B8D4D6] transition-colors duration-200 font-be-vietnam-pro"
                >
                  วางแผนประจำวัน
                </button>
                <button
                  onClick={() => handleNavigate("/page/Save_money")}
                  className="w-full text-left px-4 py-3 text-[#223248] hover:bg-[#C7DCDE] rounded transition-colors duration-200 font-be-vietnam-pro"
                >
                  วางแผนเงินออม
                </button>
                <button
                  onClick={() => handleNavigate("/page/Spending_Summary")}
                  className="w-full text-left px-4 py-3 text-[#223248] hover:bg-[#C7DCDE] rounded transition-colors duration-200 font-be-vietnam-pro"
                >
                  สรุปรายรับรายจ่าย
                </button>
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
      <main className="container mx-auto px-4 py-8 max-w-6xl flex-1">
        {/* Page Title */}
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-[#223248] text-3xl font-bold font-be-vietnam-pro">
            สรุปรายได้ - ค่าใช้จ่าย
          </h1>
          <button
            onClick={() => setShowAddTransactionModal(true)}
            className="bg-[#4FB7B3] hover:bg-[#3a9793] text-white font-bold px-6 py-2 rounded-lg transition-colors duration-200 font-be-vietnam-pro flex items-center gap-2"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <line x1="12" y1="5" x2="12" y2="19"></line>
              <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
            เพิ่มรายการ
          </button>
        </div>

        {/* Top Section with Gauge Chart */}
        <div className="bg-[#C7DCDE] rounded-lg p-8 mb-6 shadow-md">
          {/* Budget Info and Gauge */}
          <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 mb-4">
            <div>
              <p className="text-[#223248] text-sm font-be-vietnam-pro mb-1">คงเหลือ (บาท)</p>
              <p className="text-[#223248] text-5xl md:text-6xl font-bold font-be-vietnam-pro mb-3">
                {balance.toLocaleString()}
              </p>
              <button
                onClick={() => handleNavigate('/page/Spending_Summary')}
                className="bg-[#4FB7B3] text-white px-6 py-2 rounded-full text-sm font-be-vietnam-pro hover:bg-[#3a9793] transition-colors duration-200"
              >
                ดูสรุปรายได้ - ค่าใช้จ่าย
              </button>
            </div>
            <div className="text-left md:text-right">
              <p className="text-[#223248] text-sm font-be-vietnam-pro mb-1">รายได้ (บาท)</p>
              <p className="text-[#223248] text-4xl md:text-5xl font-bold font-be-vietnam-pro mb-4 md:mb-8 text-green-600">
                +{todayIncome.toLocaleString()}
              </p>
              <p className="text-[#223248] text-sm font-be-vietnam-pro mb-1">ค่าใช้จ่าย (บาท)</p>
              <p className="text-[#223248] text-4xl md:text-5xl font-bold font-be-vietnam-pro text-red-600">
                -{todayExpense.toLocaleString()}
              </p>
            </div>
          </div>

          {/* Semi-circle Gauge Chart */}
          <div className="relative flex justify-center items-center h-56 mt-8">
            <svg viewBox="0 0 200 120" className="w-full max-w-lg">
              {/* Background Arc (Light gray) */}
              <path
                d="M 20 100 A 80 80 0 0 1 180 100"
                fill="none"
                stroke="#E5E7EB"
                strokeWidth="35"
                strokeLinecap="round"
              />
              {/* Foreground Arc (Gradient based on percentage) */}
              <path
                d="M 20 100 A 80 80 0 0 1 180 100"
                fill="none"
                stroke={calculatePercentage() > 80 ? '#FF6B9D' : '#4FB7B3'}
                strokeWidth="35"
                strokeLinecap="round"
                strokeDasharray={`${calculatePercentage() * 2.51} 251`}
              />
              {/* Center Text */}
              <text x="100" y="75" textAnchor="middle" className="text-sm font-semibold fill-[#223248] font-be-vietnam-pro" style={{ fontSize: '14px' }}>
                ค่าใช้จ่ายวันนี้
              </text>
              <text x="100" y="100" textAnchor="middle" className="text-4xl font-bold fill-[#223248] font-be-vietnam-pro" style={{ fontSize: '28px' }}>
                {currentExpense.toLocaleString()}
              </text>
              <text x="100" y="115" textAnchor="middle" className="text-xs fill-gray-600 font-be-vietnam-pro" style={{ fontSize: '12px' }}>
                ใช้ไป {calculatePercentage()}%
              </text>
            </svg>

            {/* Needle Indicator */}
            <div
              className="absolute top-12 left-1/2 origin-bottom transition-transform duration-500"
              style={{
                transform: `translateX(-50%) rotate(${getGaugeRotation()}deg)`,
                height: '60px',
                width: '3px'
              }}
            >
              <div className="w-full h-full bg-[#223248] rounded-full"></div>
              <div className="absolute -top-2 left-1/2 -translate-x-1/2 w-3 h-3 bg-[#223248] rounded-full"></div>
            </div>

            {/* Goal Info */}
            <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2 bg-[#4FB7B3] text-white px-6 py-2 rounded-full text-sm font-be-vietnam-pro shadow-md">
              เป้าหมาย {dailyGoal.toLocaleString()} บาท/วัน
            </div>
          </div>
        </div>

        {/* Grid Layout - Transaction History and Category Budgets */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
          {/* Left Section - Transaction History */}
          <div className="lg:col-span-2 space-y-6">
            <h2 className="text-2xl font-bold text-[#223248] font-be-vietnam-pro flex items-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                <line x1="16" y1="2" x2="16" y2="6"></line>
                <line x1="8" y1="2" x2="8" y2="6"></line>
                <line x1="3" y1="10" x2="21" y2="10"></line>
              </svg>
              ประวัติรายการ
            </h2>

            {getUniqueTransactionDates().slice(0, 3).map((date) => {
              const dateInfo = formatDateThai(date);
              const dayTransactions = getTransactionsForDate(date);
              const dayIncome = calculateIncome(date);
              const dayExpense = calculateExpense(date);

              return (
                <div key={date} className="bg-[#C7DCDE] rounded-lg p-5 shadow-md">
                  <div className="grid grid-cols-3 gap-4 mb-4">
                    <div>
                      <p className="text-[#223248] text-sm font-be-vietnam-pro mb-1">{dateInfo.day}</p>
                      <p className="text-[#223248] font-bold font-be-vietnam-pro text-lg">{dateInfo.fullDate}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-[#223248] text-sm font-be-vietnam-pro mb-1">รายได้</p>
                      <p className="text-green-600 font-bold font-be-vietnam-pro text-lg">+{dayIncome.toLocaleString()}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-[#223248] text-sm font-be-vietnam-pro mb-1">ค่าใช้จ่าย</p>
                      <p className="text-red-600 font-bold font-be-vietnam-pro text-lg">-{dayExpense.toLocaleString()}</p>
                    </div>
                  </div>

                  {/* Transaction Items */}
                  <div className="space-y-2">
                    {dayTransactions.map((transaction) => (
                      <div
                        key={transaction.id}
                        className={`${transaction.type === 'income' ? 'bg-green-500' : 'bg-[#FF6B9D]'} text-white rounded-lg px-4 py-3 flex justify-between items-center group hover:opacity-90 transition-opacity`}
                      >
                        <div className="flex-1">
                          <span className="font-be-vietnam-pro font-semibold">{transaction.description}</span>
                          <span className="text-sm opacity-80 ml-2">({transaction.category})</span>
                        </div>
                        <div className="flex items-center gap-3">
                          <span className="font-be-vietnam-pro font-bold text-lg">
                            {transaction.type === 'income' ? '+' : '-'}{transaction.amount.toLocaleString()}
                          </span>
                          <button
                            onClick={() => handleDeleteTransaction(transaction.id)}
                            className="opacity-0 group-hover:opacity-100 transition-opacity p-1 hover:bg-white/20 rounded"
                            title="ลบรายการ"
                          >
                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                              <polyline points="3 6 5 6 21 6"></polyline>
                              <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                            </svg>
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              );
            })}
          </div>

          {/* Right Section - Category Budgets */}
          <div className="lg:col-span-1">
            <div className="bg-[#C7DCDE] rounded-lg p-6 h-full shadow-md">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-[#223248] text-xl font-bold font-be-vietnam-pro">
                  งบประมาณแบ่งตามหมวด
                </h2>
                <button
                  onClick={() => setShowEditBudgetModal(true)}
                  className="text-[#4FB7B3] hover:text-[#3a9793] transition-colors"
                  title="แก้ไขงบประมาณ"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                  </svg>
                </button>
              </div>
              <p className="text-[#223248] text-sm mb-6 font-be-vietnam-pro text-gray-600">
                ติดตามการใช้จ่ายในแต่ละหมวดหมู่
              </p>

              <div className="space-y-4">
                {categoryBudgets.map((budget) => {
                  const percentage = (budget.spent / budget.allocated) * 100;
                  const remaining = budget.allocated - budget.spent;

                  return (
                    <div key={budget.id} className="bg-white p-5 rounded-lg shadow-sm">
                      <div className="flex justify-between items-center mb-2">
                        <p className="text-[#223248] font-semibold font-be-vietnam-pro">{budget.name}</p>
                        <span className="text-sm text-gray-600 font-be-vietnam-pro">
                          {percentage.toFixed(0)}%
                        </span>
                      </div>

                      {/* Progress bar */}
                      <div className="h-2 bg-gray-200 rounded-full mb-2 overflow-hidden">
                        <div
                          className="h-full rounded-full transition-all duration-300"
                          style={{
                            width: `${Math.min(100, percentage)}%`,
                            backgroundColor: budget.color
                          }}
                        ></div>
                      </div>

                      <div className="flex justify-between items-center text-sm">
                        <span className="text-gray-600 font-be-vietnam-pro">
                          ใช้ไป {budget.spent.toLocaleString()} บาท
                        </span>
                        <span className="text-[#223248] font-bold font-be-vietnam-pro">
                          เหลือ {remaining.toLocaleString()} บาท
                        </span>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex justify-end gap-4">
          <button
            onClick={() => handleNavigate('/page/Main')}
            className="bg-gray-200 hover:bg-gray-300 text-[#223248] font-bold px-8 py-2.5 rounded-lg transition-colors duration-200 font-be-vietnam-pro"
          >
            ย้อนกลับ
          </button>
          <button
            onClick={() => handleNavigate('/page/Spending_Summary')}
            className="bg-[#4FB7B3] hover:bg-[#3a9793] text-white font-bold px-8 py-2.5 rounded-lg transition-colors duration-200 font-be-vietnam-pro"
          >
            ดูรายงานสรุป
          </button>
        </div>
      </main>

      {/* Add Transaction Modal */}
      {showAddTransactionModal && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg w-full max-w-md shadow-2xl">
            <div className="flex items-center justify-between p-4 border-b border-gray-200 bg-teal-500 rounded-t-lg">
              <h2 className="font-bold text-lg text-[#223248] font-be-vietnam-pro">เพิ่มรายการใหม่</h2>
              <button
                onClick={() => {
                  setShowAddTransactionModal(false);
                  resetForm();
                }}
                className="text-[#223248] hover:text-white text-2xl font-bold transition-colors duration-200"
              >
                ×
              </button>
            </div>

            <form onSubmit={handleAddTransaction} className="p-6 space-y-4">
              {/* Transaction Type */}
              <div>
                <label className="text-sm text-[#223248] font-semibold block mb-2 font-be-vietnam-pro">ประเภท</label>
                <div className="flex gap-2">
                  <button
                    type="button"
                    onClick={() => setNewTransaction({...newTransaction, type: 'expense'})}
                    className={`flex-1 px-4 py-2 rounded font-be-vietnam-pro transition-colors duration-200 ${
                      newTransaction.type === 'expense'
                        ? 'bg-red-500 text-white'
                        : 'bg-gray-200 text-[#223248] hover:bg-gray-300'
                    }`}
                  >
                    รายจ่าย
                  </button>
                  <button
                    type="button"
                    onClick={() => setNewTransaction({...newTransaction, type: 'income'})}
                    className={`flex-1 px-4 py-2 rounded font-be-vietnam-pro transition-colors duration-200 ${
                      newTransaction.type === 'income'
                        ? 'bg-green-500 text-white'
                        : 'bg-gray-200 text-[#223248] hover:bg-gray-300'
                    }`}
                  >
                    รายรับ
                  </button>
                </div>
              </div>

              {/* Category */}
              <div>
                <label className="text-sm text-[#223248] font-semibold block mb-1 font-be-vietnam-pro">หมวดหมู่</label>
                <select
                  value={newTransaction.category}
                  onChange={(e) => setNewTransaction({...newTransaction, category: e.target.value})}
                  className="w-full bg-white border border-gray-300 text-[#223248] px-3 py-2 rounded outline-none focus:ring-4 focus:ring-[#4FB7B3] focus:border-[#4FB7B3] transition-all duration-200 font-be-vietnam-pro"
                  required
                >
                  <option value="">เลือกหมวดหมู่</option>
                  {newTransaction.type === 'expense' ? (
                    <>
                      <option value="อาหาร">อาหาร</option>
                      <option value="ขนส่ง">ขนส่ง</option>
                      <option value="บันเทิง">บันเทิง</option>
                      <option value="สาธารณูปโภค">สาธารณูปโภค</option>
                      <option value="ช้อปปิ้ง">ช้อปปิ้ง</option>
                      <option value="อื่นๆ">อื่นๆ</option>
                    </>
                  ) : (
                    <>
                      <option value="เงินเดือน">เงินเดือน</option>
                      <option value="รายได้เสริม">รายได้เสริม</option>
                      <option value="ขายของ">ขายของ</option>
                      <option value="อื่นๆ">อื่นๆ</option>
                    </>
                  )}
                </select>
              </div>

              {/* Description */}
              <div>
                <label className="text-sm text-[#223248] font-semibold block mb-1 font-be-vietnam-pro">รายละเอียด</label>
                <input
                  type="text"
                  value={newTransaction.description}
                  onChange={(e) => setNewTransaction({...newTransaction, description: e.target.value})}
                  placeholder="ระบุรายละเอียด"
                  className="w-full bg-white border border-gray-300 text-[#223248] px-3 py-2 rounded outline-none focus:ring-4 focus:ring-[#4FB7B3] focus:border-[#4FB7B3] transition-all duration-200 font-be-vietnam-pro"
                  required
                />
              </div>

              {/* Amount */}
              <div>
                <label className="text-sm text-[#223248] font-semibold block mb-1 font-be-vietnam-pro">จำนวนเงิน (บาท)</label>
                <input
                  type="number"
                  value={newTransaction.amount}
                  onChange={(e) => setNewTransaction({...newTransaction, amount: e.target.value})}
                  placeholder="0"
                  min="0"
                  step="0.01"
                  className="w-full bg-white border border-gray-300 text-[#223248] px-3 py-2 rounded outline-none focus:ring-4 focus:ring-[#4FB7B3] focus:border-[#4FB7B3] transition-all duration-200 font-be-vietnam-pro"
                  required
                />
              </div>

              {/* Buttons */}
              <div className="flex justify-end gap-2 pt-4 border-t border-gray-200">
                <button
                  type="button"
                  onClick={() => {
                    setShowAddTransactionModal(false);
                    resetForm();
                  }}
                  className="bg-gray-200 hover:bg-gray-300 text-[#223248] px-6 py-2 rounded font-semibold transition-colors duration-200 font-be-vietnam-pro"
                >
                  ยกเลิก
                </button>
                <button
                  type="submit"
                  className="bg-[#4FB7B3] hover:bg-[#3a9793] text-white px-6 py-2 rounded font-bold shadow-md hover:shadow-lg transition-all duration-200 font-be-vietnam-pro"
                >
                  บันทึก
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Edit Budget Modal */}
      {showEditBudgetModal && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg w-full max-w-md shadow-2xl">
            <div className="flex items-center justify-between p-4 border-b border-gray-200 bg-teal-500 rounded-t-lg">
              <h2 className="font-bold text-lg text-[#223248] font-be-vietnam-pro">แก้ไขงบประมาณประจำวัน</h2>
              <button
                onClick={() => setShowEditBudgetModal(false)}
                className="text-[#223248] hover:text-white text-2xl font-bold transition-colors duration-200"
              >
                ×
              </button>
            </div>

            <div className="p-6 space-y-4">
              <div>
                <label className="text-sm text-[#223248] font-semibold block mb-1 font-be-vietnam-pro">
                  เป้าหมายค่าใช้จ่ายต่อวัน (บาท)
                </label>
                <input
                  type="number"
                  value={dailyGoal}
                  onChange={(e) => setDailyGoal(parseFloat(e.target.value))}
                  min="0"
                  className="w-full bg-white border border-gray-300 text-[#223248] px-3 py-2 rounded outline-none focus:ring-4 focus:ring-[#4FB7B3] focus:border-[#4FB7B3] transition-all duration-200 font-be-vietnam-pro"
                />
              </div>

              <div className="bg-[#C7DCDE] p-4 rounded-lg">
                <p className="text-sm text-[#223248] font-be-vietnam-pro">
                  ฟังก์ชันแก้ไขงบประมาณตามหมวดหมู่จะทำงานเมื่อเชื่อมต่อกับ Backend
                </p>
              </div>

              <div className="flex justify-end gap-2 pt-4 border-t border-gray-200">
                <button
                  onClick={() => setShowEditBudgetModal(false)}
                  className="bg-gray-200 hover:bg-gray-300 text-[#223248] px-6 py-2 rounded font-semibold transition-colors duration-200 font-be-vietnam-pro"
                >
                  ยกเลิก
                </button>
                <button
                  onClick={() => {
                    setShowEditBudgetModal(false);
                    alert('บันทึกการตั้งค่าสำเร็จ!');
                  }}
                  className="bg-[#4FB7B3] hover:bg-[#3a9793] text-white px-6 py-2 rounded font-bold shadow-md hover:shadow-lg transition-all duration-200 font-be-vietnam-pro"
                >
                  บันทึก
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Footer */}
      <footer className="bg-teal-500 text-[#223248] text-center py-4 mt-8">
        <p className="text-sm font-be-vietnam-pro font-semibold">Copyright 2025 © RMUTTO © MONEY LAB</p>
      </footer>
    </div>
  );
}
