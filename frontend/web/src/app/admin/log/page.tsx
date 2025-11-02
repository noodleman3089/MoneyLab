'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { Log, Pagination, fetchLogs } from '@/app/services/logService';

const LIMIT = 20; // แสดง 20 รายการต่อหน้า

export default function LogPage() {
  const router = useRouter();
  
  // --- State Management ---
  const [logs, setLogs] = useState<Log[]>([]);
  const [pagination, setPagination] = useState<Pagination | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>('');
  const [currentOffset, setCurrentOffset] = useState<number>(0);
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  // --- Modal State ---
  const [showModal, setShowModal] = useState(false);
  const [selectedLog, setSelectedLog] = useState<Log | null>(null);

  // --- Data Fetching ---
  const getLogs = useCallback(async (offset: number = 0) => {
    setLoading(true);
    setError('');
    try {
      const result = await fetchLogs(LIMIT, offset);
      if (result.status) {
        setLogs(result.data);
        setPagination(result.pagination);
      } else {
        setError(result.message || 'ไม่สามารถดึงข้อมูล Log ได้');
      }
    } catch (err: any) {
      if (err.response?.status === 401) {
        setError('เซสชันหมดอายุ กรุณาล็อกอินอีกครั้ง');
        router.push('/page/login');
      } else {
        setError(err.message || 'เกิดข้อผิดพลาดในการเชื่อมต่อ');
      }
    } finally {
      setLoading(false);
    }
  }, [router]);

  useEffect(() => {
    getLogs(currentOffset);
  }, [currentOffset, getLogs]);

  // --- Handlers ---
  const handleNextPage = () => {
    if (pagination && pagination.nextOffset !== null) setCurrentOffset(pagination.nextOffset);
  };
  const handlePrevPage = () => {
    if (pagination && pagination.prevOffset !== null) setCurrentOffset(pagination.prevOffset);
  };
  const openLogDetail = (log: Log) => {
    setSelectedLog(log);
    setShowModal(true);
  };
  const formatDate = (dateString: string) => new Date(dateString).toLocaleString('th-TH', { dateStyle: 'medium', timeStyle: 'medium' });

  // Helper function to format JSON values for display
  const formatJsonValue = (value: any) => {
    if (value === null || value === undefined) {
      return 'null';
    }
    try {
      // If the value is a stringified JSON, parse it first.
      const parsed = typeof value === 'string' ? JSON.parse(value) : value;
      // Then stringify it with pretty printing.
      return JSON.stringify(parsed, null, 2);
    } catch (e) {
      // If it's not a valid JSON string, just return it as is.
      return String(value);
    }
  };

  // --- Render ---
  return (
    <div className="min-h-screen bg-[#C7DCDE]">
      {/* Navbar */}
      <header className="bg-teal-500 text-white p-4 flex justify-between items-center relative shadow-md">
        <Link href="/admin/main" className="text-2xl font-bold font-be-vietnam-pro hover:text-teal-200">MONEY LAB</Link>
        <div className="flex items-center gap-4">
          <button type="button" className="text-2xl p-2 rounded-full hover:bg-teal-600" onClick={() => setIsMenuOpen(!isMenuOpen)}>☰</button>
          {isMenuOpen && (
            <div className="absolute top-16 right-4 bg-white rounded-md shadow-lg w-64 z-10 text-gray-800 font-be-vietnam-pro">
              <ul className="py-2">
                <li><Link href="/admin/main" className="block px-4 py-2 hover:bg-gray-100">หน้าหลัก Admin</Link></li>
                <li><Link href="/admin/UserSummaryDashboard" className="block px-4 py-2 hover:bg-gray-100">แดชบอร์ด</Link></li>
                <li><Link href="/admin/ShowregisterUser" className="block px-4 py-2 hover:bg-gray-100">จัดการผู้ใช้งาน</Link></li>
              </ul>
            </div>
          )}
        </div>
      </header>

      {/* Main Content */}
      <main className="p-8">
        <div className="max-w-7xl mx-auto">
          <h1 className="text-[#223248] text-4xl font-bold mb-8 font-be-vietnam-pro">Audit Log</h1>

          {error && <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">{error}</div>}

          {loading ? (
            <div className="text-center py-20">กำลังโหลดข้อมูล...</div>
          ) : (
            <>
              <div className="bg-white rounded-lg shadow-lg overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead className="bg-[#4FB7B3] text-white">
                      <tr>
                        <th className="p-3 text-left text-sm font-semibold">Timestamp</th>
                        <th className="p-3 text-left text-sm font-semibold">Actor</th>
                        <th className="p-3 text-left text-sm font-semibold">Action</th>
                        <th className="p-3 text-left text-sm font-semibold">Description</th>
                        <th className="p-3 text-left text-sm font-semibold">Details</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200">
                      {logs.map((log) => (
                        <tr key={log.log_id} className="hover:bg-gray-50">
                          <td className="p-3 text-sm text-gray-700">{formatDate(log.created_at)}</td>
                          <td className="p-3 text-sm text-gray-700">{log.actor_type} (ID: {log.actor_id || 'N/A'})</td>
                          <td className="p-3 text-sm text-gray-700 font-semibold">{log.action}</td>
                          <td className="p-3 text-sm text-gray-700 truncate max-w-xs">{log.description || '-'}</td>
                          <td className="p-3 text-sm">
                            <button onClick={() => openLogDetail(log)} className="text-blue-600 hover:underline">ดู JSON</button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* Pagination */}
              {pagination && pagination.total > LIMIT && (
                <div className="mt-6 flex justify-between items-center">
                  <div className="text-sm text-gray-700">
                    แสดง {currentOffset + 1} - {Math.min(currentOffset + LIMIT, pagination.total)} จาก {pagination.total}
                  </div>
                  <div className="flex gap-2">
                    <button
                      onClick={handlePrevPage}
                      disabled={pagination.prevOffset === null}
                      className={`px-4 py-2 rounded-md font-be-vietnam-pro font-semibold transition-colors text-sm ${
                        pagination.prevOffset === null
                          ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
                          : 'bg-[#4FB7B3] text-white hover:bg-[#008170]'
                      }`}
                    >ก่อนหน้า</button>
                    <button
                      onClick={handleNextPage}
                      disabled={pagination.nextOffset === null}
                      className={`px-4 py-2 rounded-md font-be-vietnam-pro font-semibold transition-colors text-sm ${
                        pagination.nextOffset === null
                          ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
                          : 'bg-[#4FB7B3] text-white hover:bg-[#008170]'
                      }`}
                    >ถัดไป</button>
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      </main>

      {/* Log Detail Modal */}
      {showModal && selectedLog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg shadow-2xl w-full max-w-2xl max-h-[80vh] flex flex-col">
            <div className="flex justify-between items-center p-4 border-b">
              <h3 className="text-xl font-bold text-[#223248]">Log Details (ID: {selectedLog.log_id})</h3>
              <button onClick={() => setShowModal(false)} className="text-gray-500 hover:text-red-600 text-2xl">&times;</button>
            </div>
            <div className="p-6 overflow-y-auto">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-3 text-sm text-gray-800">
                <div><strong className="text-gray-500">Action:</strong> {selectedLog.action}</div>
                <div><strong className="text-gray-500">Actor Type:</strong> {selectedLog.actor_type}</div>
                <div><strong className="text-gray-500">Actor ID:</strong> {selectedLog.actor_id || 'N/A'}</div>
                <div><strong className="text-gray-500">Timestamp:</strong> {formatDate(selectedLog.created_at)}</div>
                <div><strong className="text-gray-500">Table:</strong> {selectedLog.table_name || 'N/A'}</div>
                <div><strong className="text-gray-500">Record ID:</strong> {selectedLog.record_id || 'N/A'}</div>
                <div className="md:col-span-2"><strong className="text-gray-500">IP Address:</strong> {selectedLog.ip_address || 'N/A'}</div>
                <div className="md:col-span-2"><strong className="text-gray-500">User Agent:</strong> {selectedLog.user_agent || 'N/A'}</div>
              </div>
              
              <div className="mt-6 grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <h4 className="font-bold mb-2 text-red-600">Old Value</h4>
                  <pre className="bg-gray-100 p-3 rounded-md text-xs overflow-auto max-h-60 text-gray-900">
                    {formatJsonValue(selectedLog.old_value)}
                  </pre>
                </div>
                <div>
                  <h4 className="font-bold mb-2 text-green-600">New Value</h4>
                  <pre className="bg-gray-100 p-3 rounded-md text-xs overflow-auto max-h-60 text-gray-900">
                    {formatJsonValue(selectedLog.new_value)}
                  </pre>
                </div>
              </div>
            </div>
            <div className="p-4 border-t text-right">
              <button onClick={() => setShowModal(false)} className="px-4 py-2 bg-gray-300 text-gray-800 rounded-md hover:bg-gray-400">
                ปิด
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
