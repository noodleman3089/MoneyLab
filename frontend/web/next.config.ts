const path = require('path');

/** @type {import('next').NextConfig} */
const nextConfig = {
  // ตั้ง root ให้ชัดเจนเพื่อไม่ให้ Turbopack สับสนกับหลาย lockfile
  turbopack: {
    root: path.resolve(__dirname)
  },
  // (เลือก) ข้าม ESLint ขณะ build ถ้าต้องการผ่าน build ชั่วคราว
  eslint: {
    ignoreDuringBuilds: true
  }
};

module.exports = nextConfig;