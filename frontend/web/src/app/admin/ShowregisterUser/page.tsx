// 1. Importing Dependencies
'use client'
import React, { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation'; // 👈 1. Import useRouter
import Link from 'next/link'; // 👈 1. Import Link สำหรับทำเมนู
import { User, Pagination, UserDetails } from '@/app/services/user.types'; // 👈 1. Import types ทั้งหมดจากตำแหน่งที่ถูกต้อง
import {
  fetchUsers as fetchUsersService,
  hardDeleteUser, softDeleteUser, fetchUserDetails,
  promoteUser // 👈 1. Import service ใหม่
} from '@/app/services/userService';

// 3. Constants
const LIMIT = 10;

// 4. Creating and Exporting Component
export default function ShowUserPage() {
  const router = useRouter(); // 👈 2. สร้าง instance ของ router
  // 4.1 State Management
  const [users, setUsers] = useState<User[]>([]);
  const [pagination, setPagination] = useState<Pagination | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>('');
  const [currentOffset, setCurrentOffset] = useState<number>(0);
  const [selectedUserId, setSelectedUserId] = useState<number | null>(null);
  const [selectedUsername, setSelectedUsername] = useState<string>('');
  // --- States for Detail Modal ---
  const [showDetailModal, setShowDetailModal] = useState<boolean>(false);
  const [detailLoading, setDetailLoading] = useState<boolean>(false);
  const [selectedUserDetails, setSelectedUserDetails] = useState<UserDetails | null>(null);
  const [showDeleteConfirmModal, setShowDeleteConfirmModal] = useState<boolean>(false);

  const [actionLoading, setActionLoading] = useState<boolean>(false);
  const [successMessage, setSuccessMessage] = useState<string>('');
  // --- State for Role Filter ---
  const [filterRole, setFilterRole] = useState<'all' | 'user' | 'admin'>('all');
  const [isMenuOpen, setIsMenuOpen] = useState(false); // 👈 2. เพิ่ม State สำหรับเปิด/ปิดเมนู

  // 4.2 Fetch Users Function with useCallback to prevent infinite loops
  const fetchUsers = useCallback(
    async (offset: number = 0, roleToFetch: 'all' | 'user' | 'admin' = 'all') => {
      setLoading(true);
      setError('');

      // 3. [REFACTORED] เรียกใช้ Service function
      try {
        const result = await fetchUsersService(LIMIT, offset, roleToFetch === 'all' ? null : roleToFetch);
        if (result.status) {
          setUsers(result.data);
          setPagination(result.pagination);
        } else {
          setError(result.message || 'ไม่สามารถดึงข้อมูลผู้ใช้ได้');
        }
      } catch (err: any) {
        console.error('Fetch users error:', err);
        // --- 3. [THE FIX] ---
        // ดักจับ Error 401 แล้วส่งผู้ใช้กลับไปหน้า Login
        if (err.response?.status === 401) {
          setError('เซสชันหมดอายุ กรุณาล็อกอินอีกครั้ง');
          // ล้าง token เก่า (ถ้ามี)
          localStorage.removeItem('token');
          router.push('/page/login'); // ไปหน้า login
        } else if (err.response?.status === 403) {
          setError('คุณไม่มีสิทธิ์เข้าถึง');
        } else {
          setError(
            err.response?.data?.message || 'ไม่สามารถดึงข้อมูลผู้ใช้ได้ กรุณาลองอีกครั้ง'
          );
        }
      } finally {
        setLoading(false);
      }
    },
    [router] // เพิ่ม router เป็น dependency
  );

  // 4.3 useEffect - Load data on component mount and when dependencies change
  useEffect(() => {
    fetchUsers(currentOffset, filterRole);
  }, [currentOffset, filterRole, fetchUsers]);

  // 4.4 Pagination Handlers
  const handleNextPage = () => {
    if (pagination && pagination.nextOffset !== null) {
      setCurrentOffset(pagination.nextOffset);
    }
  };

  const handlePrevPage = () => {
    if (pagination && pagination.prevOffset !== null) {
      setCurrentOffset(pagination.prevOffset);
    }
  };

  const handleFirstPage = () => {
    setCurrentOffset(0);
  };

  // --- Handler for changing filter ---
  const handleFilterChange = (role: 'all' | 'user' | 'admin') => {
    setFilterRole(role);
    setCurrentOffset(0); // Reset to first page when filter changes
  };

  // 4.5 Format Date Function
  const formatDate = (dateString: string | null) => {
    if (!dateString) return 'ยังไม่เคยเข้าสู่ระบบ';
    const date = new Date(dateString);
    return date.toLocaleString('th-TH', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  // 4.6 Open Modal for Suspend/Delete Action
  const openModal = (action: 'delete', userId: number, username: string) => { // 👈 4. [REMOVED] เอา suspend ออกจาก parameter
    setSelectedUserId(userId);
    setSelectedUsername(username);
    setShowDeleteConfirmModal(true); // 👈 [CHANGED] เปิด Modal ยืนยันการลบแบบใหม่แทน
  };

  // 4.7 Close Modal (ถูกรวมเข้ากับ closeDetailModal และการปิด modal ย่อย)
  // --- Detail Modal Handlers ---
  const openDetailModal = async (userId: number) => {
    setShowDetailModal(true);
    setDetailLoading(true);
    setError('');
    // 👈 3. [REFACTORED] เรียกใช้ Service function
    try {
      const result = await fetchUserDetails(userId);
      if (result.status) {
        setSelectedUserDetails(result.data);
      } else {
        setError('ไม่สามารถดึงข้อมูลรายละเอียดผู้ใช้ได้');
        closeDetailModal();
      }
    } catch (err) {
      setError('เกิดข้อผิดพลาดในการดึงข้อมูลรายละเอียด');
      closeDetailModal();
    } finally {
      setDetailLoading(false);
    }
  };

  const closeDetailModal = () => {
    setShowDetailModal(false);
    setSelectedUserDetails(null);
    // ปิด modal ยืนยันการลบด้วย ถ้าเปิดอยู่
    setShowDeleteConfirmModal(false);
  };

  // 4.9 Delete User Function
  const handleDeleteUser = async (deleteType: 'soft' | 'hard') => {
    if (!selectedUserId) return;

    const usernameToDelete = selectedUserDetails?.user.username || selectedUsername;

    setActionLoading(true);
    setError('');

    try {
      // 👈 4. [REFACTORED] เรียก service ที่ถูกต้องตามประเภทการลบ
      const result = deleteType === 'soft'
        ? await softDeleteUser(selectedUserId)
        : await hardDeleteUser(selectedUserId);

      if (result.status) {
        setSuccessMessage(`ลบบัญชี ${usernameToDelete} สำเร็จ (${deleteType} delete)`);
        closeDetailModal(); // ปิด modal ใหญ่
        setShowDeleteConfirmModal(false); // ปิด modal ยืนยันการลบ
        fetchUsers(currentOffset);
        setTimeout(() => setSuccessMessage(''), 3000);
      } else {
        setError(result.message || `ไม่สามารถลบบัญชี (${deleteType} delete) ได้`);
      }
    } catch (err: any) {
      console.error('Delete user error:', err);
      if (err.response?.status === 401) {
        setError('หมดเวลาการเข้าสู่ระบบ กรุณาเข้าสู่ระบบอีกครั้ง');
      } else if (err.response?.status === 403) {
        setError('คุณไม่มีสิทธิ์เข้าถึง');
      } else {
        setError(err.response?.data?.message || 'ไม่สามารถลบบัญชีได้ กรุณาลองอีกครั้ง');
      }
    } finally {
      setActionLoading(false);
      setShowDeleteConfirmModal(false); // ปิด modal ยืนยันเสมอ
    }
  };

  // --- Promote User Function ---
  const handlePromoteUser = async () => {
    if (!selectedUserDetails) return;

    const userId = selectedUserDetails.user.user_id;
    const username = selectedUserDetails.user.username;

    setActionLoading(true);
    setError('');

    try {
      const result = await promoteUser(userId);
      if (result.status) {
        setSuccessMessage(`เลื่อนขั้น ${username} เป็น Admin สำเร็จ`);
        // อัปเดตข้อมูลใน State ทันทีเพื่อให้ UI เปลี่ยนแปลง
        setSelectedUserDetails(prev => prev ? { ...prev, user: { ...prev.user, role: 'admin' } } : null);
        // โหลดข้อมูลใหม่เพื่อให้ตารางอัปเดต
        fetchUsers(currentOffset, filterRole);
        setTimeout(() => setSuccessMessage(''), 4000);
      } else {
        setError(result.message || 'ไม่สามารถเลื่อนขั้นผู้ใช้ได้');
      }
    } catch (err: any) {
      console.error('Promote user error:', err);
      setError(err.response?.data?.message || 'เกิดข้อผิดพลาดในการเลื่อนขั้น');
    } finally {
      setActionLoading(false);
    }
  };

  // 4.6 Render UI
  return (
    <div className="min-h-screen bg-[#C7DCDE]">
      {/* 👈 3. [NEW] Navbar */}
      <header className="bg-teal-500 text-white p-4 flex justify-between items-center relative shadow-md">
        <Link href="/admin/main" className="text-2xl font-bold font-be-vietnam-pro hover:text-teal-200 transition-colors">
          MONEY LAB
        </Link>
        <div className="flex items-center gap-4">
          <button
            type="button"
            className="text-2xl p-2 rounded-full hover:bg-teal-600"
            onClick={() => setIsMenuOpen(!isMenuOpen)}
          >
            ☰
          </button>

          {isMenuOpen && (
            <div className="absolute top-16 right-4 bg-white rounded-md shadow-lg w-64 z-10 text-gray-800 font-be-vietnam-pro">
              <ul className="py-2">
                <li>
                  <Link href="/admin/main" className="block px-4 py-2 hover:bg-gray-100">หน้าหลัก Admin</Link>
                </li>
                <li>
                  <Link href="/admin/UserSummaryDashboard" className="block px-4 py-2 hover:bg-gray-100">แดชบอร์ดสรุปข้อมูล</Link>
                </li>
                {/* สามารถเพิ่มเมนูอื่นๆ ได้ที่นี่ */}
              </ul>
            </div>
          )}
        </div>
      </header>

      {/* 👈 4. [CHANGED] ครอบเนื้อหาเดิมด้วย div ใหม่เพื่อให้มี padding */}
      <main className="p-8">
        <div className="max-w-7xl mx-auto">

          {/* Header */}
          <div className="mb-8">
            <h1 className="text-[#223248] text-4xl font-bold mb-4 font-be-vietnam-pro">
              รายชื่อผู้ใช้งาน
            </h1>

            {/* Total Count */}
            {pagination && (
              <p className="text-[#223248] font-be-vietnam-pro">
                ทั้งหมด: <span className="font-bold">{pagination.total}</span> คน
              </p>
            )}
          </div>

          {/* Filter Buttons */}
          <div className="mb-6 flex gap-2">
            {(['all', 'user', 'admin'] as const).map((role) => (
              <button
                key={role}
                onClick={() => handleFilterChange(role)}
                className={`px-4 py-2 rounded-md font-be-vietnam-pro font-semibold transition-colors text-sm ${
                  filterRole === role
                    ? 'bg-[#223248] text-white shadow-md'
                    : 'bg-white text-[#223248] hover:bg-gray-200'
                }`}
              >
                {
                  {
                    all: 'ทั้งหมด',
                    user: 'ผู้ใช้ทั่วไป',
                    admin: 'ผู้ดูแลระบบ'
                  }[role]
                }
              </button>
            ))}
          </div>


          {/* Error Message */}
          {error && (
            <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
              {error}
            </div>
          )}

          {/* Success Message */}
          {successMessage && (
            <div className="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
              {successMessage}
            </div>
          )}

          {/* Loading State */}
          {loading ? (
            <div className="flex justify-center items-center py-20">
              <div className="text-[#223248] text-xl font-be-vietnam-pro">กำลังโหลดข้อมูล...</div>
            </div>
          ) : (
            <>
              {/* Users Table */}
              <div className="bg-white rounded-lg shadow-lg overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead className="bg-[#4FB7B3] text-white">
                      <tr>
                        <th className="px-6 py-3 text-left text-sm font-semibold font-be-vietnam-pro">ID</th>
                        <th className="px-6 py-3 text-left text-sm font-semibold font-be-vietnam-pro">ชื่อผู้ใช้</th>
                        <th className="px-6 py-3 text-left text-sm font-semibold font-be-vietnam-pro">อีเมล</th>
                        <th className="px-6 py-3 text-left text-sm font-semibold font-be-vietnam-pro">เบอร์โทร</th>
                        <th className="px-6 py-3 text-left text-sm font-semibold font-be-vietnam-pro">เข้าสู่ระบบล่าสุด</th>
                        <th className="px-6 py-3 text-left text-sm font-semibold font-be-vietnam-pro">วันที่สมัคร</th>
                        <th className="px-6 py-3 text-left text-sm font-semibold font-be-vietnam-pro">การจัดการ</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200">
                      {users.length === 0 ? (
                        <tr>
                          <td colSpan={7} className="px-6 py-8 text-center text-gray-500 font-be-vietnam-pro">
                            ไม่พบข้อมูลผู้ใช้
                          </td>
                        </tr>
                      ) : (
                        users.map((user) => (
                          <tr key={user.user_id} className="hover:bg-gray-50 transition-colors">
                            <td className="px-6 py-4 text-sm text-[#223248] font-be-vietnam-pro">{user.user_id}</td>
                            <td className="px-6 py-4 text-sm text-[#223248] font-semibold font-be-vietnam-pro">{user.username}</td>
                            <td className="px-6 py-4 text-sm text-[#223248] font-be-vietnam-pro">{user.email}</td>
                            <td className="px-6 py-4 text-sm text-[#223248] font-be-vietnam-pro">{user.phone_number || '-'}</td>
                            <td className="px-6 py-4 text-sm text-[#223248] font-be-vietnam-pro">{formatDate(user.last_login_at)}</td>
                            <td className="px-6 py-4 text-sm text-[#223248] font-be-vietnam-pro">{formatDate(user.created_at)}</td>
                            <td className="px-6 py-4 text-sm flex gap-2">
                              {/* 👇 2. เปลี่ยนเป็นปุ่มเปิด Modal */}
                              <button
                                onClick={() => openDetailModal(user.user_id)}
                                className="px-3 py-1 bg-blue-500 text-white rounded-md hover:bg-blue-600 transition-colors font-be-vietnam-pro font-semibold text-xs"
                              >
                                ดูรายละเอียด
                              </button>
                              {/* 👈 5. [REMOVED] ลบปุ่ม "ระงับ" ออก */}
                              {user.role !== 'admin' && ( // 👈 [THE FIX] ซ่อนปุ่มลบถ้าเป็น admin
                                <button
                                  type="button"
                                  onClick={() => openModal('delete', user.user_id, user.username)}
                                  className="px-3 py-1 bg-red-500 text-white rounded-md hover:bg-red-600 transition-colors font-be-vietnam-pro font-semibold text-xs"
                                >
                                  ลบ
                                </button>
                              )}
                            </td>
                          </tr>
                        ))
                      )}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* Pagination Controls */}
              {pagination && pagination.total > LIMIT && (
                <div className="mt-6 flex justify-between items-center">
                  <div className="text-[#223248] font-be-vietnam-pro">
                    แสดง {currentOffset + 1} - {Math.min(currentOffset + LIMIT, pagination.total)} จาก {pagination.total}
                  </div>

                  <div className="flex gap-2">
                    <button
                      type="button"
                      onClick={handleFirstPage}
                      disabled={currentOffset === 0}
                      className={`px-4 py-2 rounded-md font-be-vietnam-pro font-semibold transition-colors ${
                        currentOffset === 0
                          ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
                          : 'bg-[#4FB7B3] text-white hover:bg-[#008170]'
                      }`}
                    >
                      หน้าแรก
                    </button>

                    <button
                      type="button"
                      onClick={handlePrevPage}
                      disabled={pagination.prevOffset === null}
                      className={`px-4 py-2 rounded-md font-be-vietnam-pro font-semibold transition-colors ${
                        pagination.prevOffset === null
                          ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
                          : 'bg-[#4FB7B3] text-white hover:bg-[#008170]'
                      }`}
                    >
                      ก่อนหน้า
                    </button>

                    <button
                      type="button"
                      onClick={handleNextPage}
                      disabled={pagination.nextOffset === null}
                      className={`px-4 py-2 rounded-md font-be-vietnam-pro font-semibold transition-colors ${
                        pagination.nextOffset === null
                          ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
                          : 'bg-[#4FB7B3] text-white hover:bg-[#008170]'
                      }`}
                    >
                      ถัดไป
                    </button>
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      </main>

      {/* --- User Detail Modal --- */}
      {showDetailModal && (
        <div className="fixed inset-0 bg-black bg-opacity-60 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg shadow-2xl w-full max-w-4xl max-h-[90vh] flex flex-col font-be-vietnam-pro">
            {/* Modal Header */}
            <div className="flex justify-between items-center p-4 border-b">
              <h2 className="text-2xl font-bold text-[#223248] truncate">
                รายละเอียดผู้ใช้: {selectedUserDetails?.user.username}
              </h2>
              <button onClick={closeDetailModal} className="text-gray-500 hover:text-red-600 text-2xl">&times;</button>
            </div>

            {/* Modal Body */}
            <div className="p-6 overflow-y-auto">
              {detailLoading ? (
                <div className="text-center py-10">กำลังโหลดข้อมูล...</div>
              ) : selectedUserDetails ? (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  {/* User Info */}
                  <div className="bg-gray-50 p-4 rounded-lg border border-gray-200">
                    <h3 className="font-bold text-[#223248] mb-3">ข้อมูลบัญชี</h3>
                    <p className="text-gray-800"><strong>ID:</strong> {selectedUserDetails.user.user_id}</p>
                    <p className="text-gray-800"><strong>Email:</strong> {selectedUserDetails.user.email}</p>
                    <p className="text-gray-800"><strong>Role:</strong> {selectedUserDetails.user.role}</p>
                    <p className="text-gray-800"><strong>สมัครเมื่อ:</strong> {formatDate(selectedUserDetails.user.created_at)}</p>
                  </div>
                  {/* Profile Info */}
                  <div className="bg-gray-50 p-4 rounded-lg border border-gray-200">
                    <h3 className="font-bold text-[#223248] mb-3">โปรไฟล์การเงิน</h3>
                    {selectedUserDetails.profile ? (
                      <>
                        <p className="text-gray-800"><strong>รายได้หลัก:</strong> {Number(selectedUserDetails.profile.main_income_amount).toLocaleString()} บาท</p>
                        <p className="text-gray-800"><strong>รายได้เสริม:</strong> {Number(selectedUserDetails.profile.side_income_amount).toLocaleString()} บาท</p>
                      </>
                    ) : <p className="text-gray-500">ไม่มีข้อมูลโปรไฟล์</p>}
                  </div>
                  {/* Debts */}
                  <div className="md:col-span-2 bg-gray-50 p-4 rounded-lg border border-gray-200">
                    <h3 className="font-bold text-[#223248] mb-3">หนี้สิน ({selectedUserDetails.debts.length})</h3>
                    {selectedUserDetails.debts.length > 0 ? (
                      <ul className="list-disc list-inside text-gray-800">
                        {selectedUserDetails.debts.map(d => <li key={d.debt_id}>{d.debt_type}: {Number(d.debt_amount).toLocaleString()} บาท</li>)}
                      </ul>
                    ) : <p className="text-gray-500">ไม่มีข้อมูลหนี้สิน</p>}
                  </div>
                </div>
              ) : null}
            </div>

            {/* Modal Footer with Delete Button */}
            <div className="flex justify-end items-center p-4 border-t gap-4">
              <button onClick={closeDetailModal} className="px-4 py-2 bg-gray-200 text-gray-800 rounded-md hover:bg-gray-300">ปิด</button>
              {/* 👈 [THE FIX] ปุ่ม Promote to Admin */}
              {selectedUserDetails?.user.role === 'user' && (
                <button
                  onClick={handlePromoteUser}
                  disabled={actionLoading}
                  className="px-4 py-2 bg-green-500 text-white rounded-md hover:bg-green-600 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {actionLoading ? '...' : 'Promote to Admin'}
                </button>
              )}
              {selectedUserDetails?.user.role !== 'admin' && ( // 👈 [THE FIX] ซ่อนปุ่มลบถ้าเป็น admin
                <button
                  onClick={() => {
                    setSelectedUserId(selectedUserDetails?.user.user_id ?? null); // 👈 5. ตั้งค่า ID ที่จะลบ
                    setShowDeleteConfirmModal(true);
                  }}
                  className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700"
                >
                  ลบบัญชีผู้ใช้นี้
                </button>
              )}
            </div>
          </div>
        </div>
      )}

      {/* --- Universal Delete Confirmation Modal --- */}
      {showDeleteConfirmModal && (
        <div className="fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-[60]">
          <div className="bg-white rounded-lg shadow-xl p-6 max-w-lg w-full mx-4 font-be-vietnam-pro">
            <h3 className="text-2xl font-bold text-red-800 mb-4">ยืนยันการลบบัญชี</h3>
            <p className="mb-6 text-gray-700">
              กรุณาเลือกวิธีการลบบัญชีของผู้ใช้ <span className="font-bold text-black">{selectedUsername || selectedUserDetails?.user.username}</span>:
            </p>
            
            <div className="space-y-4 mb-8">
              <div className="border border-red-200 bg-red-50 p-4 rounded-md">
                <h4 className="font-bold text-red-600">1. Hard Delete (ลบถาวร)</h4>
                <p className="text-sm text-gray-600 mt-1">
                  ข้อมูลผู้ใช้และข้อมูลที่เกี่ยวข้องทั้งหมดจะถูกลบออกจากฐานข้อมูลอย่างถาวร **ไม่สามารถกู้คืนได้**
                </p>
              </div>
              <div className="border border-yellow-300 bg-yellow-50 p-4 rounded-md">
                <h4 className="font-bold text-yellow-700">2. Soft Delete (ลบแบบไม่เปิดเผยตัวตน)</h4>
                <p className="text-sm text-gray-600 mt-1">
                  ข้อมูลส่วนตัว (ชื่อ, อีเมล, เบอร์โทร) จะถูกลบและแทนที่ด้วยข้อมูลสุ่ม แต่ข้อมูลธุรกรรมยังคงอยู่เพื่อการวิเคราะห์ภาพรวมของระบบ
                </p>
              </div>
            </div>

            <div className="flex justify-end gap-4">
              <button onClick={() => setShowDeleteConfirmModal(false)} className="px-4 py-2 bg-gray-300 text-gray-800 rounded-md hover:bg-gray-400 font-semibold">ยกเลิก</button>
              <button disabled={actionLoading} onClick={() => handleDeleteUser('soft')} className="px-4 py-2 bg-yellow-500 text-white rounded-md hover:bg-yellow-600 font-semibold disabled:opacity-50 disabled:cursor-not-allowed">{actionLoading ? '...' : 'Soft Delete'}</button>
              <button disabled={actionLoading} onClick={() => handleDeleteUser('hard')} className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 font-semibold disabled:opacity-50 disabled:cursor-not-allowed">{actionLoading ? '...' : 'Hard Delete'}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
