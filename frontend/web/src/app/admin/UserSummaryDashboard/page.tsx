'use client'

import React, { useState } from 'react';
import { BarChart, Bar, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

export default function UserSummaryDashboard() {
  const [searchValue, setSearchValue] = useState('');

  // Chart data
  const barChartData = [
    { month: 'มี.ค. 68', category1: 40, category2: 30 },
    { month: 'เม.ย. 68', category1: 35, category2: 45 },
    { month: 'พ.ค. 68', category1: 50, category2: 30 },
    { month: 'มิ.ย. 68', category1: 45, category2: 55 },
  ];

  const pieChartData = [
    { name: 'Category 1', value: 75 },
    { name: 'Category 2', value: 25 },
  ];

  const COLORS = ['#EF6B61', '#1ECAD8'];

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
              <BarChart data={barChartData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#ccc" />
                <XAxis dataKey="month" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Bar dataKey="category1" fill="#EF6B61" name="1" />
                <Bar dataKey="category2" fill="#1ECAD8" name="2" />
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
                  data={pieChartData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={120}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {pieChartData.map((_entry, index) => (
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
                  {/* Empty rows for customer list */}
                  {[...Array(10)].map((_item, index) => (
                    <tr key={index} className="border-b border-gray-300 hover:bg-gray-50 transition-colors h-12">
                      <td className="px-6 py-2"></td>
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
                 คำนวนเงินรวมต่างๆ
                </th>
              </tr>
            </thead>
            <tbody>
              {/* Empty rows for table */}
              {[...Array(8)].map((_item, index) => (
                <tr key={index} className="border-b border-gray-300 hover:bg-gray-50 transition-colors h-16">
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
