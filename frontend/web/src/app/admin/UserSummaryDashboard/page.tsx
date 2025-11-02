'use client'

import React, { useState, useEffect, useCallback } from 'react';
import { BarChart, Bar, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { User } from '@/app/services/user.types'; // Import type จากไฟล์กลาง
import { DashboardSummary, ExpenseChartData, IncomeChartData } from '@/app/services/dashboard.types'; // Import type ของ Dashboard
import { fetchUsers } from '@/app/services/userService'; // Import service สำหรับดึง user
import { fetchDashboardSummary, fetchExpenseChartData, fetchIncomeChartData } from '@/app/services/dashboardService'; // Import service ของ Dashboard

export default function UserSummaryDashboard() {
  const [searchValue, setSearchValue] = useState('');

  // --- State Management for Real Data ---
  const [summaryData, setSummaryData] = useState<DashboardSummary | null>(null);
  const [expenseData, setExpenseData] = useState<ExpenseChartData[]>([]);
  const [incomeData, setIncomeData] = useState<IncomeChartData[]>([]);
  const [recentUsers, setRecentUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>('');

  const COLORS = ['#EF6B61', '#1ECAD8'];

  // --- Fetch All Data on Component Mount ---
  const loadDashboardData = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      // เรียก API ทั้งหมดพร้อมกันเพื่อประสิทธิภาพ
      const [summaryRes, expenseRes, incomeRes, usersRes] = await Promise.all([
        fetchDashboardSummary(),
        fetchExpenseChartData(),
        fetchIncomeChartData(),
        fetchUsers(10, 0) // ดึงผู้ใช้ล่าสุด 10 คน
      ]);

      if (summaryRes.status) setSummaryData(summaryRes.data);
      if (expenseRes.status) setExpenseData(expenseRes.data);
      if (incomeRes.status) setIncomeData(incomeRes.data);
      if (usersRes.status) setRecentUsers(usersRes.data);

    } catch (err: any) {
      console.error("Failed to load dashboard data:", err);
      setError(err.message || 'ไม่สามารถโหลดข้อมูลแดชบอร์ดได้');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadDashboardData();
  }, [loadDashboardData]);

  // --- Render UI ---
  if (loading) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="text-2xl font-bold text-teal-600">กำลังโหลดข้อมูลแดชบอร์ด...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center p-8">
        <div className="bg-red-100 border border-red-400 text-red-700 px-6 py-4 rounded text-center">
          <h2 className="font-bold text-xl mb-2">เกิดข้อผิดพลาด</h2>
          <p>{error}</p>
          <button onClick={loadDashboardData} className="mt-4 bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600">
            ลองอีกครั้ง
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Header */}
      <header className="bg-teal-500 text-white p-4 flex justify-between items-center">
        <h1 className="text-2xl font-bold font-be-vietnam-pro">MONEY LAB</h1>
        <div className="flex items-center gap-4">
          <button type="button" className="relative">
            <span className="text-2xl">🔔</span>
            <span className="absolute top-0 right-0 bg-red-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">5</span>
          </button>
          <button type="button" className="text-2xl">👤</button>
          <button type="button" className="text-2xl">☰</button>
        </div>
      </header>

      {/* Main Content */}
      <main className="p-8">
        {/* Top Bar Section with Search */}
        <div className="flex justify-between items-center mb-8 gap-4">
          <input
            type="text"
            placeholder="ค้นหา..."
            value={searchValue}
            onChange={(e) => setSearchValue(e.target.value)}
            className="flex-1 bg-teal-200 px-4 py-3 rounded text-gray-800 placeholder-gray-600 focus:outline-none focus:ring-2 focus:ring-teal-400 font-be-vietnam-pro"
          />
          <button type="button" className="bg-teal-200 text-gray-800 px-6 py-2 rounded font-be-vietnam-pro hover:bg-teal-300 transition-colors">
            ค้นหา
          </button>
        </div>

        {/* Charts and Customer List Section */}
        <div className="grid grid-cols-3 gap-8 mb-8">
          {/* Bar Chart */}
          <div className="bg-teal-200 rounded-lg p-6">
            <h2 className="text-center text-xl font-bold text-gray-800 mb-6 font-be-vietnam-pro">
              สรุปรายจ่าย
            </h2>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={expenseData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#ccc" />
                <XAxis dataKey="month" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Bar dataKey="total_expense" fill="#EF6B61" name="รายจ่ายรวม" />
              </BarChart>
            </ResponsiveContainer>
          </div>

          {/* Pie Chart */}
          <div className="bg-teal-200 rounded-lg p-6">
            <h2 className="text-center text-xl font-bold text-gray-800 mb-6 font-be-vietnam-pro">
              สรุปรายรับ
            </h2>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={incomeData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={120}
                  paddingAngle={5}
                  dataKey="total_amount"
                  nameKey="category_name"
                >
                  {incomeData.map((_entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>

          {/* Customer List Table */}
          <div className="bg-white rounded-lg overflow-hidden shadow-md flex flex-col">
            <div className="bg-teal-200 px-6 py-4">
              <h2 className="text-center font-bold text-gray-800 font-be-vietnam-pro">
                รายชื่อลูกค้า
              </h2>
            </div>
            <div className="flex-1 overflow-y-auto">
              <table className="w-full">
                <tbody>
                  {recentUsers.map((user) => (
                    <tr key={user.user_id} className="border-b border-gray-300 hover:bg-gray-50 transition-colors h-12">
                      <td className="px-6 py-2 font-be-vietnam-pro text-sm">
                        <div className="font-semibold text-gray-800">{user.username}</div>
                        <div className="text-xs text-gray-500">{user.email}</div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* Table Section */}
        <div className="bg-white rounded-lg overflow-hidden shadow-md">
          <table className="w-full">
            <thead>
              <tr className="bg-teal-200">
                <th className="px-6 py-4 text-left font-bold text-gray-800 font-be-vietnam-pro border-r border-gray-400 w-1/2">
                  รายการทั้งหมด
                </th>
                <th className="px-6 py-4 text-left font-bold text-gray-800 font-be-vietnam-pro w-1/2">
                 คำนวณเงินรวมต่างๆ
                </th>
              </tr>
            </thead>
            <tbody>
              {summaryData && (
                <>
                  <tr className="border-b border-gray-300 h-16"><td className="px-6 py-4 border-r border-gray-300 font-semibold">ผู้ใช้ทั้งหมด</td><td className="px-6 py-4">{summaryData.total_users.toLocaleString()} คน</td></tr>
                  <tr className="border-b border-gray-300 h-16 bg-gray-50"><td className="px-6 py-4 border-r border-gray-300 font-semibold">ธุรกรรมทั้งหมด</td><td className="px-6 py-4">{summaryData.total_transactions.toLocaleString()} รายการ</td></tr>
                  <tr className="border-b border-gray-300 h-16"><td className="px-6 py-4 border-r border-gray-300 font-semibold">รายรับรวม</td><td className="px-6 py-4 text-green-600 font-bold">{summaryData.total_income.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} บาท</td></tr>
                  <tr className="border-b border-gray-300 h-16 bg-gray-50"><td className="px-6 py-4 border-r border-gray-300 font-semibold">รายจ่ายรวม</td><td className="px-6 py-4 text-red-600 font-bold">{summaryData.total_expense.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} บาท</td></tr>
                  <tr className="border-b border-gray-300 h-16"><td className="px-6 py-4 border-r border-gray-300 font-semibold">ผู้ใช้ใหม่วันนี้</td><td className="px-6 py-4">{summaryData.new_users_today.toLocaleString()} คน</td></tr>
                </>
              )}
              {/* เติมแถวว่างเพื่อให้ตารางดูเต็ม */}
              {[...Array(Math.max(0, 3))].map((_, index) => (
                <tr key={`empty-${index}`} className="border-b border-gray-300 h-16">
                  <td className="px-6 py-4 border-r border-gray-300"></td>
                  <td className="px-6 py-4"></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-teal-500 text-white text-center p-4 mt-8">
        <p className="font-be-vietnam-pro">Copyright 2025 © RMUTTO</p>
      </footer>
    </div>
  );
}
