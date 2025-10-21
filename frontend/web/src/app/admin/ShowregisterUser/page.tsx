// 1. Importing Dependencies
'use client'
import React, { useState, useEffect, useCallback } from 'react';
import axios from 'axios';

// 2. Type Definitions
interface User {
  user_id: number;
  username: string;
  email: string;
  phone_number: string | null;
  role: string;
  last_login_at: string | null;
  created_at: string;
  updated_at: string;
}

interface Pagination {
  total: number;
  limit: number;
  offset: number;
  nextOffset: number | null;
  prevOffset: number | null;
}

interface UsersResponse {
  status: boolean;
  message: string;
  data: User[];
  pagination: Pagination;
  filter: { role?: string } | null;
}

// 3. Constants
const LIMIT = 10;
const API_ENDPOINT = '/api/users';

// 4. Creating and Exporting Component
export default function ShowUserPage() {
  // 4.1 State Management
  const [users, setUsers] = useState<User[]>([]);
  const [pagination, setPagination] = useState<Pagination | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>('');
  const [currentOffset, setCurrentOffset] = useState<number>(0);
  const [showModal, setShowModal] = useState<boolean>(false);
  const [modalAction, setModalAction] = useState<'suspend' | 'delete' | null>(null);
  const [selectedUserId, setSelectedUserId] = useState<number | null>(null);
  const [selectedUsername, setSelectedUsername] = useState<string>('');
  const [actionLoading, setActionLoading] = useState<boolean>(false);
  const [successMessage, setSuccessMessage] = useState<string>('');

  // 4.2 Fetch Users Function with useCallback to prevent infinite loops
  const fetchUsers = useCallback(
    async (offset: number = 0) => {
      setLoading(true);
      setError('');

      try {
        // Validate token exists
        const token = localStorage.getItem('token');
        if (!token) {
          setError('การรับรองความถูกต้องจำเป็น กรุณาเข้าสู่ระบบ');
          setLoading(false);
          return;
        }

        // Get API URL from environment variables
        const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';

        // Build query parameters using URLSearchParams for better maintainability
        const params = new URLSearchParams({
          limit: LIMIT.toString(),
          offset: offset.toString(),
        });

        const url = `${apiUrl}${API_ENDPOINT}?${params.toString()}`;

        // Make API request
        const response = await axios.get<UsersResponse>(url, {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        });

        const result = response.data;

        if (result.status) {
          setUsers(result.data);
          setPagination(result.pagination);
        } else {
          setError(result.message || 'ไม่สามารถดึงข้อมูลผู้ใช้ได้');
        }
      } catch (err: any) {
        console.error('Fetch users error:', err);

        // Handle different error types
        if (err.response?.status === 401) {
          setError('หมดเวลาการเข้าสู่ระบบ กรุณาเข้าสู่ระบบอีกครั้ง');
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
    []
  );

  // 4.3 useEffect - Load data on component mount and when dependencies change
  useEffect(() => {
    fetchUsers(currentOffset);
  }, [currentOffset, fetchUsers]);

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
  const openModal = (action: 'suspend' | 'delete', userId: number, username: string) => {
    setModalAction(action);
    setSelectedUserId(userId);
    setSelectedUsername(username);
    setShowModal(true);
  };

  // 4.7 Close Modal
  const closeModal = () => {
    setShowModal(false);
    setModalAction(null);
    setSelectedUserId(null);
    setSelectedUsername('');
  };

  // 4.8 Suspend User Function
  const handleSuspendUser = async () => {
    if (!selectedUserId) return;

    setActionLoading(true);
    setError('');

    try {
      const token = localStorage.getItem('token');
      if (!token) {
        setError('การรับรองความถูกต้องจำเป็น กรุณาเข้าสู่ระบบ');
        setActionLoading(false);
        return;
      }

      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';
      const response = await axios.put(
        `${apiUrl}/api/users/${selectedUserId}/suspend`,
        {},
        {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      if (response.data.status) {
        setSuccessMessage(`ระงับบัญชี ${selectedUsername} สำเร็จ`);
        closeModal();
        fetchUsers(currentOffset);
        setTimeout(() => setSuccessMessage(''), 3000);
      } else {
        setError(response.data.message || 'ไม่สามารถระงับบัญชีได้');
      }
    } catch (err: any) {
      console.error('Suspend user error:', err);
      if (err.response?.status === 401) {
        setError('หมดเวลาการเข้าสู่ระบบ กรุณาเข้าสู่ระบบอีกครั้ง');
      } else if (err.response?.status === 403) {
        setError('คุณไม่มีสิทธิ์เข้าถึง');
      } else {
        setError(err.response?.data?.message || 'ไม่สามารถระงับบัญชีได้ กรุณาลองอีกครั้ง');
      }
    } finally {
      setActionLoading(false);
    }
  };

  // 4.9 Delete User Function
  const handleDeleteUser = async () => {
    if (!selectedUserId) return;

    setActionLoading(true);
    setError('');

    try {
      const token = localStorage.getItem('token');
      if (!token) {
        setError('การรับรองความถูกต้องจำเป็น กรุณาเข้าสู่ระบบ');
        setActionLoading(false);
        return;
      }

      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';
      const response = await axios.delete(
        `${apiUrl}/api/users/${selectedUserId}`,
        {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      if (response.data.status) {
        setSuccessMessage(`ลบบัญชี ${selectedUsername} สำเร็จ`);
        closeModal();
        fetchUsers(currentOffset);
        setTimeout(() => setSuccessMessage(''), 3000);
      } else {
        setError(response.data.message || 'ไม่สามารถลบบัญชีได้');
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
    }
  };

  // 4.6 Render UI
  return (
    <div className="min-h-screen bg-[#C7DCDE] p-8">
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
                            <button
                              type="button"
                              onClick={() => openModal('suspend', user.user_id, user.username)}
                              className="px-3 py-1 bg-yellow-500 text-white rounded-md hover:bg-yellow-600 transition-colors font-be-vietnam-pro font-semibold text-xs"
                            >
                              ระงับ
                            </button>
                            <button
                              type="button"
                              onClick={() => openModal('delete', user.user_id, user.username)}
                              className="px-3 py-1 bg-red-500 text-white rounded-md hover:bg-red-600 transition-colors font-be-vietnam-pro font-semibold text-xs"
                            >
                              ลบ
                            </button>
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

      {/* Confirmation Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-lg p-8 max-w-md w-full mx-4">
            <h2 className="text-2xl font-bold text-[#223248] mb-4 font-be-vietnam-pro">
              {modalAction === 'suspend' ? 'ยืนยันการระงับบัญชี' : 'ยืนยันการลบบัญชี'}
            </h2>
            <p className="text-gray-700 mb-6 font-be-vietnam-pro">
              {modalAction === 'suspend'
                ? `คุณแน่ใจหรือไม่ว่าต้องการระงับบัญชี ${selectedUsername}?`
                : `คุณแน่ใจหรือไม่ว่าต้องการลบบัญชี ${selectedUsername}? การกระทำนี้ไม่สามารถยกเลิกได้`}
            </p>
            <div className="flex gap-4">
              <button
                type="button"
                onClick={closeModal}
                disabled={actionLoading}
                className="flex-1 px-4 py-2 bg-gray-300 text-gray-700 rounded-md hover:bg-gray-400 transition-colors font-be-vietnam-pro font-semibold disabled:opacity-50"
              >
                ยกเลิก
              </button>
              <button
                type="button"
                onClick={modalAction === 'suspend' ? handleSuspendUser : handleDeleteUser}
                disabled={actionLoading}
                className={`flex-1 px-4 py-2 text-white rounded-md transition-colors font-be-vietnam-pro font-semibold disabled:opacity-50 ${
                  modalAction === 'suspend'
                    ? 'bg-yellow-500 hover:bg-yellow-600'
                    : 'bg-red-500 hover:bg-red-600'
                }`}
              >
                {actionLoading
                  ? 'กำลังดำเนิน...'
                  : modalAction === 'suspend'
                  ? 'ระงับบัญชี'
                  : 'ลบบัญชี'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
