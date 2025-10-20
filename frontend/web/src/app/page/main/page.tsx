// 1. Importing Dependencies
'use client' // ต้องใช้เพราะใช้ useState และ window, localStorage
import React, { useState } from 'react';
import axios from "axios";
import Navbar from '@/app/components/Navbar';
import Footer from '@/app/components/Footer';

// 2. Creating and Exporting a Component
export default function MainPage() {

  // ฟังก์ชันสำหรับเปลี่ยนหน้าไปยังแต่ละเมนู
  const handleNavigate = (path: string) => {
    window.location.href = path;
  };

  return (
    // Background
    <div className="min-h-screen bg-white flex flex-col">

      <Navbar />

      {/* Main Content */}
      <main className="container mx-auto px-4 py-12">
        {/* Hero Title */}
        <div className="text-center mb-12">
          <h1 className="text-[#223248] text-6xl font-extrabold mb-4 font-be-vietnam-pro">
            MONEY LAB
          </h1>
          <p className="text-[#223248] text-2xl font-semibold font-be-vietnam-pro">
            เลือกสิ่งที่สนใจ
          </p>
        </div>

        {/* Cards Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 max-w-5xl mx-auto">

          {/* Card 1: วางแผนประจำวัน */}
          <button
            onClick={() => handleNavigate('/page/Set_Daily_Inco-Expe')}
            className="group relative bg-gradient-to-b from-[#3d4f5c] to-[#4FB7B3] rounded-lg overflow-hidden shadow-lg hover:shadow-2xl transform hover:scale-105 transition-all duration-300 h-64"
          >
            <div className="absolute inset-0 flex flex-col items-center justify-center p-6">
              <h2 className="text-white text-3xl font-bold mb-6 font-be-vietnam-pro z-10">
                วางแผนประจำวัน
              </h2>
              {/* Coin Stack Illustration */}
              <div className="relative w-full h-32">
                <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2 flex gap-4">
                  {[...Array(4)].map((_, i) => (
                    <div key={i} className="flex flex-col items-center">
                      <div className="w-12 h-3 bg-yellow-400 rounded-full border-2 border-yellow-500 mb-1"></div>
                      <div className="w-12 h-12 bg-[#4FB7B3] rounded"></div>
                      <div className="w-12 h-12 bg-[#3a9793]"></div>
                      <div className="w-12 h-12 bg-[#4FB7B3]"></div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </button>

          {/* Card 2: วางแผนเงินออม */}
          <button
            onClick={() => handleNavigate('/page/Save_money')}
            className="group relative bg-gradient-to-b from-[#3d4f5c] to-[#4FB7B3] rounded-lg overflow-hidden shadow-lg hover:shadow-2xl transform hover:scale-105 transition-all duration-300 h-64"
          >
            <div className="absolute inset-0 flex flex-col items-center justify-center p-6">
              <h2 className="text-white text-3xl font-bold mb-6 font-be-vietnam-pro z-10">
                วางแผนเงินออม
              </h2>
              {/* Coin Stack Illustration */}
              <div className="relative w-full h-32">
                <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2 flex gap-4">
                  {[...Array(4)].map((_, i) => (
                    <div key={i} className="flex flex-col items-center">
                      <div className="w-12 h-3 bg-yellow-400 rounded-full border-2 border-yellow-500 mb-1"></div>
                      <div className="w-12 h-12 bg-[#4FB7B3] rounded"></div>
                      <div className="w-12 h-12 bg-[#3a9793]"></div>
                      <div className="w-12 h-12 bg-[#4FB7B3]"></div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </button>

          {/* Card 3: สรุปรายรับรายจ่าย */}
          <button
            onClick={() => handleNavigate('/page/Main')}
            className="group relative bg-gradient-to-b from-[#3d4f5c] to-[#4FB7B3] rounded-lg overflow-hidden shadow-lg hover:shadow-2xl transform hover:scale-105 transition-all duration-300 h-64"
          >
            <div className="absolute inset-0 flex flex-col items-center justify-center p-6">
              <h2 className="text-white text-3xl font-bold mb-6 font-be-vietnam-pro z-10">
                สรุปรายรับรายจ่าย
              </h2>
              {/* Bar Chart Illustration */}
              <div className="relative w-full h-32">
                <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2 flex gap-4 items-end">
                  <div className="w-16 h-24 bg-[#4FB7B3] rounded-t"></div>
                  <div className="w-16 h-20 bg-[#3a9793] rounded-t"></div>
                  <div className="w-16 h-28 bg-[#4FB7B3] rounded-t"></div>
                  <div className="w-16 h-16 bg-[#3a9793] rounded-t"></div>
                </div>
              </div>
            </div>
          </button>

          {/* Card 4: ดูการลงทุน */}
          <button
            onClick={() => handleNavigate('/page/Main')}
            className="group relative bg-gradient-to-b from-[#3d4f5c] to-[#4FB7B3] rounded-lg overflow-hidden shadow-lg hover:shadow-2xl transform hover:scale-105 transition-all duration-300 h-64"
          >
            <div className="absolute inset-0 flex flex-col items-center justify-center p-6">
              <h2 className="text-white text-3xl font-bold mb-6 font-be-vietnam-pro z-10">
                ดูการลงทุน
              </h2>
              {/* Bar Chart Illustration */}
              <div className="relative w-full h-32">
                <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2 flex gap-4 items-end">
                  <div className="w-16 h-20 bg-[#4FB7B3] rounded-t"></div>
                  <div className="w-16 h-28 bg-[#3a9793] rounded-t"></div>
                  <div className="w-16 h-24 bg-[#4FB7B3] rounded-t"></div>
                  <div className="w-16 h-16 bg-[#3a9793] rounded-t"></div>
                </div>
              </div>
            </div>
          </button>
        </div>
      </main>

      <Footer />
      
    </div>
  );
}