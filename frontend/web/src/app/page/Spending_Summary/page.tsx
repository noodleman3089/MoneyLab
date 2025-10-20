'use client'
import React, { useState } from 'react';
import axios from "axios";

// Types
interface Transaction {
  id: string;
  date: string;
  category: string;
  description: string;
  amount: number;
  type: 'income' | 'expense';
}

interface CategorySummary {
  category: string;
  amount: number;
  percentage: number;
  color: string;
}

interface MonthlyData {
  month: string;
  income: number;
  expense: number;
}

export default function SpendingSummaryPage() {
  // States
  const [showNotifications, setShowNotifications] = useState<boolean>(false);
  const [showProfileMenu, setShowProfileMenu] = useState<boolean>(false);
  const [showSidebar, setShowSidebar] = useState<boolean>(false);
  const [filterType, setFilterType] = useState<'all' | 'income' | 'expense'>('all');

  // Mock data - replace with API calls
  const [transactions] = useState<Transaction[]>([
    { id: '1', date: '2025-10-18', category: 'อาหาร', description: 'ร้านอาหาร A', amount: 250, type: 'expense' },
    { id: '2', date: '2025-10-17', category: 'ขนส่ง', description: 'ค่าน้ำมัน', amount: 500, type: 'expense' },
    { id: '3', date: '2025-10-16', category: 'บันเทิง', description: 'ดูหนัง', amount: 300, type: 'expense' },
    { id: '4', date: '2025-10-15', category: 'เงินเดือน', description: 'รายได้ประจำ', amount: 15000, type: 'income' },
    { id: '5', date: '2025-10-14', category: 'อาหาร', description: 'ซื้อของในตลาด', amount: 800, type: 'expense' },
    { id: '6', date: '2025-10-13', category: 'สาธารณูปโภค', description: 'ค่าไฟฟ้า', amount: 1200, type: 'expense' },
    { id: '7', date: '2025-10-12', category: 'ขนส่ง', description: 'ค่าแท็กซี่', amount: 150, type: 'expense' },
    { id: '8', date: '2025-10-11', category: 'รายได้เสริม', description: 'งานฟรีแลนซ์', amount: 3000, type: 'income' },
  ]);

  const [monthlyData] = useState<MonthlyData[]>([
    { month: 'ก.ค. 68', income: 18000, expense: 12000 },
    { month: 'ส.ค. 68', income: 20000, expense: 15000 },
    { month: 'ก.ย. 68', income: 17000, expense: 13000 },
    { month: 'ต.ค. 68', income: 18000, expense: 11700 },
  ]);

  // Calculate summary
  const totalIncome = transactions
    .filter(t => t.type === 'income')
    .reduce((sum, t) => sum + t.amount, 0);

  const totalExpense = transactions
    .filter(t => t.type === 'expense')
    .reduce((sum, t) => sum + t.amount, 0);

  const balance = totalIncome - totalExpense;

  // Calculate category breakdown for pie chart
  const expenseByCategory = transactions
    .filter(t => t.type === 'expense')
    .reduce((acc, t) => {
      acc[t.category] = (acc[t.category] || 0) + t.amount;
      return acc;
    }, {} as Record<string, number>);

  const categoryColors: Record<string, string> = {
    'อาหาร': '#FF6B9D',
    'ขนส่ง': '#4FB7B3',
    'บันเทิง': '#FFB84D',
    'สาธารณูปโภค': '#A78BFA',
    'ช้อปปิ้ง': '#34D399',
    'อื่นๆ': '#94A3B8'
  };

  const categorySummary: CategorySummary[] = Object.entries(expenseByCategory).map(([category, amount]) => ({
    category,
    amount,
    percentage: (amount / totalExpense) * 100,
    color: categoryColors[category] || categoryColors['อื่นๆ']
  })).sort((a, b) => b.amount - a.amount);

  // Navigation handlers
  const handleNavigate = (path: string) => {
    window.location.href = path;
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    window.location.href = '/page/login';
  };

  const handleBack = () => {
    window.location.href = "/page/main";
  };

  // Format currency
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('th-TH', {
      style: 'currency',
      currency: 'THB',
      minimumFractionDigits: 0
    }).format(amount);
  };

  // Filter transactions
  const filteredTransactions = transactions.filter(t => {
    if (filterType === 'all') return true;
    return t.type === filterType;
  });

  // Calculate max value for bar chart scaling
  const maxValue = Math.max(...monthlyData.flatMap(d => [d.income, d.expense]));

  return (
    <div className="min-h-screen bg-white flex flex-col">
      {/* Header */}
      <header className="bg-teal-500 text-[#223248] py-4 px-6 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={handleBack}
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
              <span className="absolute top-1 right-1 bg-red-500 text-white text-xs font-bold rounded-full w-5 h-5 flex items-center justify-center">2</span>
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
                  className="w-full text-left px-4 py-3 text-[#223248] hover:bg-[#C7DCDE] rounded transition-colors duration-200 font-be-vietnam-pro"
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
                  className="w-full text-left px-4 py-3 text-[#223248] bg-[#C7DCDE] rounded transition-colors duration-200 font-be-vietnam-pro"
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
      <main className="container mx-auto px-4 py-6 flex-1">
        {/* Page Title */}
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-[#223248] font-be-vietnam-pro mb-2">
            Spending Summary (สรุปรายรับรายจ่าย)
          </h1>
          <p className="text-gray-600 font-be-vietnam-pro">ติดตามรายรับรายจ่ายของคุณ</p>
        </div>

        {/* Summary Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          <div className="bg-gradient-to-br from-green-400 to-green-600 rounded-lg p-6 text-white shadow-lg">
            <div className="flex items-center justify-between mb-2">
              <h3 className="text-sm font-semibold font-be-vietnam-pro opacity-90">รายรับทั้งหมด</h3>
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <line x1="12" y1="1" x2="12" y2="23"></line>
                <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path>
              </svg>
            </div>
            <p className="text-3xl font-bold font-be-vietnam-pro">{formatCurrency(totalIncome)}</p>
          </div>

          <div className="bg-gradient-to-br from-red-400 to-red-600 rounded-lg p-6 text-white shadow-lg">
            <div className="flex items-center justify-between mb-2">
              <h3 className="text-sm font-semibold font-be-vietnam-pro opacity-90">รายจ่ายทั้งหมด</h3>
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="12" cy="12" r="10"></circle>
                <line x1="15" y1="9" x2="9" y2="15"></line>
                <line x1="9" y1="9" x2="15" y2="15"></line>
              </svg>
            </div>
            <p className="text-3xl font-bold font-be-vietnam-pro">{formatCurrency(totalExpense)}</p>
          </div>

          <div className={`bg-gradient-to-br ${balance >= 0 ? 'from-[#4FB7B3] to-[#3a9793]' : 'from-orange-400 to-orange-600'} rounded-lg p-6 text-white shadow-lg`}>
            <div className="flex items-center justify-between mb-2">
              <h3 className="text-sm font-semibold font-be-vietnam-pro opacity-90">คงเหลือ</h3>
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <rect x="1" y="4" width="22" height="16" rx="2" ry="2"></rect>
                <line x1="1" y1="10" x2="23" y2="10"></line>
              </svg>
            </div>
            <p className="text-3xl font-bold font-be-vietnam-pro">{formatCurrency(balance)}</p>
          </div>
        </div>

        {/* Charts Section */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
          {/* Pie Chart - Category Breakdown */}
          <div className="bg-[#C7DCDE] rounded-lg p-6 shadow-md">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xl font-bold text-[#223248] font-be-vietnam-pro">สรุปรายรับรายจ่าย</h2>
              <button className="bg-[#4FB7B3] hover:bg-[#3a9793] text-white px-3 py-1 rounded text-sm font-be-vietnam-pro transition-colors duration-200">
                แก้ไข
              </button>
            </div>

            {/* Pie Chart */}
            <div className="bg-white rounded-lg p-6 mb-4 flex items-center justify-center" style={{ minHeight: '250px' }}>
              <div className="relative w-48 h-48">
                <svg viewBox="0 0 200 200" className="transform -rotate-90">
                  {categorySummary.reduce((acc, cat, index) => {
                    const prevPercentage = categorySummary.slice(0, index).reduce((sum, c) => sum + c.percentage, 0);
                    const startAngle = (prevPercentage / 100) * 360;
                    const endAngle = ((prevPercentage + cat.percentage) / 100) * 360;

                    const startRad = (startAngle * Math.PI) / 180;
                    const endRad = (endAngle * Math.PI) / 180;

                    const x1 = 100 + 80 * Math.cos(startRad);
                    const y1 = 100 + 80 * Math.sin(startRad);
                    const x2 = 100 + 80 * Math.cos(endRad);
                    const y2 = 100 + 80 * Math.sin(endRad);

                    const largeArc = cat.percentage > 50 ? 1 : 0;

                    const path = `M 100 100 L ${x1} ${y1} A 80 80 0 ${largeArc} 1 ${x2} ${y2} Z`;

                    acc.push(
                      <path
                        key={cat.category}
                        d={path}
                        fill={cat.color}
                        stroke="white"
                        strokeWidth="2"
                      />
                    );
                    return acc;
                  }, [] as React.ReactElement[])}
                </svg>
              </div>
            </div>

            {/* Legend */}
            <div className="space-y-2">
              {categorySummary.map(cat => (
                <div key={cat.category} className="flex items-center justify-between text-sm">
                  <div className="flex items-center gap-2">
                    <div
                      className="w-4 h-4 rounded"
                      style={{ backgroundColor: cat.color }}
                    ></div>
                    <span className="text-[#223248] font-be-vietnam-pro">{cat.category}</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="text-gray-600 font-be-vietnam-pro">{cat.percentage.toFixed(1)}%</span>
                    <span className="text-[#223248] font-semibold font-be-vietnam-pro">{formatCurrency(cat.amount)}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Bar Chart - Monthly Comparison */}
          <div className="bg-[#C7DCDE] rounded-lg p-6 shadow-md">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xl font-bold text-[#223248] font-be-vietnam-pro">สรุปรายรับรายจ่าย</h2>
              <button className="bg-[#4FB7B3] hover:bg-[#3a9793] text-white px-3 py-1 rounded text-sm font-be-vietnam-pro transition-colors duration-200">
                แก้ไข
              </button>
            </div>

            {/* Legend */}
            <div className="flex items-center justify-center gap-6 mb-4">
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 rounded bg-[#FF6B9D]"></div>
                <span className="text-sm text-[#223248] font-be-vietnam-pro">1</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 rounded bg-[#4FB7B3]"></div>
                <span className="text-sm text-[#223248] font-be-vietnam-pro">2</span>
              </div>
            </div>

            {/* Bar Chart */}
            <div className="bg-white rounded-lg p-6" style={{ minHeight: '250px' }}>
              <div className="flex items-end justify-around h-48 gap-4">
                {monthlyData.map((data, index) => {
                  const incomeHeight = (data.income / maxValue) * 100;
                  const expenseHeight = (data.expense / maxValue) * 100;

                  return (
                    <div key={index} className="flex-1 flex flex-col items-center gap-2">
                      <div className="w-full flex items-end justify-center gap-1 h-40">
                        <div className="relative group flex-1">
                          <div
                            className="bg-[#FF6B9D] rounded-t hover:opacity-80 transition-opacity cursor-pointer"
                            style={{ height: `${incomeHeight}%` }}
                            title={`รายรับ: ${formatCurrency(data.income)}`}
                          ></div>
                        </div>
                        <div className="relative group flex-1">
                          <div
                            className="bg-[#4FB7B3] rounded-t hover:opacity-80 transition-opacity cursor-pointer"
                            style={{ height: `${expenseHeight}%` }}
                            title={`รายจ่าย: ${formatCurrency(data.expense)}`}
                          ></div>
                        </div>
                      </div>
                      <span className="text-xs text-[#223248] font-be-vietnam-pro">{data.month}</span>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        </div>

        {/* Transaction List */}
        <div className="bg-[#C7DCDE] rounded-lg p-6 shadow-md">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-bold text-[#223248] font-be-vietnam-pro">รายการทั้งหมด</h2>
            <button className="bg-[#4FB7B3] hover:bg-[#3a9793] text-white px-4 py-2 rounded font-be-vietnam-pro transition-colors duration-200">
              แก้ไข
            </button>
          </div>

          {/* Filter Buttons */}
          <div className="flex gap-2 mb-4">
            <button
              onClick={() => setFilterType('all')}
              className={`px-4 py-2 rounded font-be-vietnam-pro transition-colors duration-200 ${
                filterType === 'all'
                  ? 'bg-[#4FB7B3] text-white'
                  : 'bg-white text-[#223248] hover:bg-[#B8D4D6]'
              }`}
            >
              ทั้งหมด
            </button>
            <button
              onClick={() => setFilterType('income')}
              className={`px-4 py-2 rounded font-be-vietnam-pro transition-colors duration-200 ${
                filterType === 'income'
                  ? 'bg-[#4FB7B3] text-white'
                  : 'bg-white text-[#223248] hover:bg-[#B8D4D6]'
              }`}
            >
              รายรับ
            </button>
            <button
              onClick={() => setFilterType('expense')}
              className={`px-4 py-2 rounded font-be-vietnam-pro transition-colors duration-200 ${
                filterType === 'expense'
                  ? 'bg-[#4FB7B3] text-white'
                  : 'bg-white text-[#223248] hover:bg-[#B8D4D6]'
              }`}
            >
              รายจ่าย
            </button>
          </div>

          {/* Transaction Table */}
          <div className="bg-white rounded-lg overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="bg-[#B8D4D6]">
                    <th className="px-4 py-3 text-left text-sm font-bold text-[#223248] font-be-vietnam-pro">วันที่</th>
                    <th className="px-4 py-3 text-left text-sm font-bold text-[#223248] font-be-vietnam-pro">ประเภท</th>
                    <th className="px-4 py-3 text-left text-sm font-bold text-[#223248] font-be-vietnam-pro">รายการ</th>
                    <th className="px-4 py-3 text-right text-sm font-bold text-[#223248] font-be-vietnam-pro">จำนวนเงิน</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredTransactions.length === 0 ? (
                    <tr>
                      <td colSpan={4} className="px-4 py-8 text-center text-gray-500 font-be-vietnam-pro">
                        ไม่พบรายการ
                      </td>
                    </tr>
                  ) : (
                    filteredTransactions.map((transaction, index) => (
                      <tr
                        key={transaction.id}
                        className={`border-t border-gray-200 hover:bg-[#C7DCDE]/30 transition-colors duration-150 ${
                          index % 2 === 0 ? 'bg-white' : 'bg-gray-50'
                        }`}
                      >
                        <td className="px-4 py-3 text-sm text-[#223248] font-be-vietnam-pro">
                          {new Date(transaction.date).toLocaleDateString('th-TH', {
                            day: '2-digit',
                            month: 'short',
                            year: '2-digit'
                          })}
                        </td>
                        <td className="px-4 py-3">
                          <span
                            className={`inline-block px-3 py-1 rounded-full text-xs font-semibold font-be-vietnam-pro ${
                              transaction.type === 'income'
                                ? 'bg-green-100 text-green-700'
                                : 'bg-red-100 text-red-700'
                            }`}
                          >
                            {transaction.category}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-sm text-[#223248] font-be-vietnam-pro">
                          {transaction.description}
                        </td>
                        <td className={`px-4 py-3 text-sm font-bold text-right font-be-vietnam-pro ${
                          transaction.type === 'income' ? 'text-green-600' : 'text-red-600'
                        }`}>
                          {transaction.type === 'income' ? '+' : '-'}{formatCurrency(transaction.amount)}
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-teal-500 text-[#223248] text-center py-4 mt-8">
        <p className="text-sm font-be-vietnam-pro font-semibold">Copyright 2025 © RMUTTO © MONEY LAB</p>
      </footer>
    </div>
  );
}