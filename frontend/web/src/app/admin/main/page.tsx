'use client';

import React from 'react';
import Link from 'next/link';
import { FaUsers, FaChartBar, FaHistory } from 'react-icons/fa'; // ใช้ไอคอนเพื่อความสวยงาม

/**
 * ส่วนประกอบย่อยสำหรับสร้างปุ่มเมนูแต่ละอัน
 */
const MenuButton = ({ href, icon, title, description }: { href: string; icon: React.ReactNode; title: string; description: string; }) => (
  <Link href={href} passHref>
    <div className="bg-white p-6 rounded-lg shadow-md hover:shadow-xl hover:scale-105 transition-all duration-300 cursor-pointer flex items-start gap-4">
      <div className="text-3xl text-[#4FB7B3]">
        {icon}
      </div>
      <div>
        <h3 className="text-xl font-bold text-[#223248] mb-1">{title}</h3>
        <p className="text-sm text-gray-600">{description}</p>
      </div>
    </div>
  </Link>
);

/**
 * หน้าหลักสำหรับส่วนของผู้ดูแลระบบ (Admin)
 */
export default function AdminMainPage() {
  return (
    <div className="min-h-screen flex font-be-vietnam-pro">
      {/* --- ฝั่งซ้าย: เหมือนเป็น Header หลัก --- */}
      <div className="flex-1 bg-teal-500 flex flex-col items-center justify-center p-8 text-center text-white">
        <div className="max-w-md">
          <h1 className="text-6xl font-bold mb-4 text-shadow">
            Admin Panel
          </h1>
          <p className="text-xl text-[#C7DCDE]">
            ศูนย์กลางการจัดการสำหรับผู้ดูแลระบบ MoneyLab
          </p>
        </div>
      </div>

      {/* --- ฝั่งขวา: ส่วนของเมนูตัวเลือก --- */}
      <div className="flex-1 bg-[#C7DCDE] flex items-center justify-center p-8">
        <div className="w-full max-w-lg">
          <h2 className="text-4xl font-semibold text-[#223248] mb-10 text-center">
            กรุณาเลือกเมนู
          </h2>

          <div className="space-y-6">
            {/* ปุ่มที่ 1: จัดการผู้ใช้งาน */}
            <MenuButton
              href="/admin/ShowregisterUser"
              icon={<FaUsers />}
              title="จัดการผู้ใช้งาน"
              description="ดูรายชื่อ, ระงับ, หรือลบบัญชีผู้ใช้ทั้งหมดในระบบ"
            />

            {/* ปุ่มที่ 2: แดชบอร์ดสรุปข้อมูล */}
            <MenuButton
              href="/admin/UserSummaryDashboard"
              icon={<FaChartBar />}
              title="แดชบอร์ดสรุปข้อมูล"
              description="ดูภาพรวมของระบบในรูปแบบกราฟและสถิติทางการเงิน"
            />

            {/* ปุ่มที่ 3: ประวัติการใช้งาน (Logs) */}
            <MenuButton
              href="/admin/log"
              icon={<FaHistory />}
              title="ประวัติการใช้งาน (Logs)"
              description="ตรวจสอบการกระทำต่างๆ ที่เกิดขึ้นในระบบโดยผู้ใช้และผู้ดูแล"
            />
          </div>
        </div>
      </div>

      {/* --- CSS สำหรับ Text Shadow (เสริมความสวยงาม) --- */}
      <style jsx>{`
        .text-shadow {
          text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.2);
        }
      `}</style>
    </div>
  );
}