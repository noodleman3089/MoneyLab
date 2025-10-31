// 1. Importing Dependencies
'use client' // ต้องใช้เพราะใช้ useState และ window, localStorage
import React, { useState, FormEvent } from 'react';
import axios from "axios";

// 2. Types
interface SavingGoal {
  id: string;
  name: string;
  emoji: string;
  saved: number;
  target: number;
  duration: number;
  unit: 'day' | 'week' | 'month' | 'year';
  plan: 'ประจำวัน' | 'ลงทุน';
  investMode?: 'recommend' | 'custom' | 'none';
  symbols?: string;
  progress: number;
  perPeriod: number;
  perDay: number;
}

// 3. Creating and Exporting a Component
export default function SaveMoneyPage() {

  // 3.1 Defining Variables, States, and Handlers
  const [goals, setGoals] = useState<SavingGoal[]>([
    {
      id: '1',
      name: 'ทริปทะเลภูเก็ต',
      emoji: '🏖️',
      saved: 6000,
      target: 15000,
      duration: 2,
      unit: 'month',
      plan: 'ประจำวัน',
      investMode: 'none',
      progress: 40,
      perPeriod: 4500,
      perDay: 150
    },
    {
      id: '2',
      name: 'โทรศัพท์ใหม่',
      emoji: '📱',
      saved: 3400,
      target: 10000,
      duration: 4,
      unit: 'week',
      plan: 'ประจำวัน',
      investMode: 'none',
      progress: 34,
      perPeriod: 1650,
      perDay: 237
    },
    {
      id: '3',
      name: 'ค่าเทอม',
      emoji: '📈',
      saved: 3000,
      target: 5000,
      duration: 20,
      unit: 'day',
      plan: 'ลงทุน',
      investMode: 'recommend',
      progress: 60,
      perPeriod: 100,
      perDay: 100
    }
  ]);

  // Modal states
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showDetailDrawer, setShowDetailDrawer] = useState(false);
  const [showContribModal, setShowContribModal] = useState(false);

  // Form states for Create Goal
  const [goalName, setGoalName] = useState('');
  const [goalAmount, setGoalAmount] = useState('');
  const [goalDuration, setGoalDuration] = useState('');
  const [goalUnit, setGoalUnit] = useState<'day' | 'week' | 'month' | 'year'>('month');
  const [goalPlan, setGoalPlan] = useState<'ประจำวัน' | 'ลงทุน'>('ประจำวัน');
  const [investMode, setInvestMode] = useState<'recommend' | 'custom'>('recommend');
  const [symbols, setSymbols] = useState('');

  // Current goal for editing/viewing
  const [currentGoal, setCurrentGoal] = useState<SavingGoal | null>(null);

  // Contribution form
  const [contribAmount, setContribAmount] = useState('');

  // Helper functions
  const unitLabel = (unit: string) => {
    switch(unit) {
      case 'day': return 'วัน';
      case 'week': return 'สัปดาห์';
      case 'month': return 'เดือน';
      case 'year': return 'ปี';
      default: return 'เดือน';
    }
  };

  const unitDays = (unit: string) => {
    switch(unit) {
      case 'day': return 1;
      case 'week': return 7;
      case 'month': return 30;
      case 'year': return 365;
      default: return 30;
    }
  };

  const calculateProgress = (saved: number, target: number) => {
    if (target <= 0) return 0;
    return Math.round(Math.max(0, Math.min(100, (saved / target) * 100)));
  };

  const calculatePerPeriod = (target: number, saved: number, duration: number) => {
    const remain = Math.max(0, target - saved);
    return duration > 0 ? Math.ceil(remain / duration) : remain;
  };

  // Calculate summary
  const totalGoals = goals.length;
  const totalSaved = goals.reduce((sum, g) => sum + g.saved, 0);
  const totalTarget = goals.reduce((sum, g) => sum + g.target, 0);
  const overallProgress = totalTarget > 0 ? Math.round((totalSaved / totalTarget) * 100) : 0;

  // Handle Create Goal
  const handleCreateGoal = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    if (!goalName.trim() || !goalAmount || !goalDuration) {
      alert('กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }

    const target = parseFloat(goalAmount);
    const duration = parseInt(goalDuration, 10);

    const newGoal: SavingGoal = {
      id: Date.now().toString(),
      name: goalName.trim(),
      emoji: goalPlan === 'ลงทุน' ? '📈' : '💰',
      saved: 0,
      target,
      duration,
      unit: goalUnit,
      plan: goalPlan,
      investMode: goalPlan === 'ลงทุน' ? investMode : 'none',
      symbols: goalPlan === 'ลงทุน' && investMode === 'custom' ? symbols : '',
      progress: 0,
      perPeriod: calculatePerPeriod(target, 0, duration),
      perDay: Math.ceil(calculatePerPeriod(target, 0, duration) / unitDays(goalUnit))
    };

    try {
      // API call (optional - comment out if not ready)
      // const response = await axios.post("http://localhost:4000/api/saving-goals", newGoal);

      setGoals([newGoal, ...goals]);
      setShowCreateModal(false);
      resetCreateForm();
      alert('สร้างเป้าหมายออมเงินสำเร็จ!');
    } catch (error) {
      console.error('Error creating goal:', error);
      alert('เกิดข้อผิดพลาดในการสร้างเป้าหมาย');
    }
  };

  const resetCreateForm = () => {
    setGoalName('');
    setGoalAmount('');
    setGoalDuration('');
    setGoalUnit('month');
    setGoalPlan('ประจำวัน');
    setInvestMode('recommend');
    setSymbols('');
  };

  // Handle Edit Goal
  const handleEditGoal = () => {
    if (!currentGoal) return;

    const updatedGoals = goals.map(g => {
      if (g.id === currentGoal.id) {
        const perPeriod = calculatePerPeriod(g.target, g.saved, g.duration);
        return {
          ...g,
          ...currentGoal,
          progress: calculateProgress(g.saved, currentGoal.target),
          perPeriod,
          perDay: Math.ceil(perPeriod / unitDays(currentGoal.unit))
        };
      }
      return g;
    });

    setGoals(updatedGoals);
    setShowEditModal(false);
    alert('แก้ไขเป้าหมายสำเร็จ!');
  };

  // Handle Delete Goal
  const handleDeleteGoal = (id: string) => {
    if (confirm('คุณต้องการลบเป้าหมายนี้หรือไม่?')) {
      setGoals(goals.filter(g => g.id !== id));
    }
  };

  // Handle Add Contribution
  const handleAddContribution = () => {
    if (!currentGoal) return;

    const amount = parseFloat(contribAmount);
    if (isNaN(amount) || amount <= 0) {
      alert('กรุณาใส่จำนวนเงินที่ถูกต้อง');
      return;
    }

    const updatedGoals = goals.map(g => {
      if (g.id === currentGoal.id) {
        const newSaved = g.saved + amount;
        const progress = calculateProgress(newSaved, g.target);
        const perPeriod = calculatePerPeriod(g.target, newSaved, g.duration);
        return {
          ...g,
          saved: newSaved,
          progress,
          perPeriod,
          perDay: Math.ceil(perPeriod / unitDays(g.unit))
        };
      }
      return g;
    });

    setGoals(updatedGoals);
    const updatedGoal = updatedGoals.find(g => g.id === currentGoal.id);
    if (updatedGoal) setCurrentGoal(updatedGoal);
    setContribAmount('');
    setShowContribModal(false);
    alert(`เพิ่มเงินออม ${amount.toLocaleString()} บาท สำเร็จ!`);
  };

  // Handle Back
  const handleBack = () => {
    window.location.href = "/page/Main";
  };

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
          <div>
            <h1 className="text-2xl font-bold font-be-vietnam-pro">My Saving Goals</h1>
            <p className="text-[#223248] text-sm font-be-vietnam-pro">ตั้งเป้าหมายออมเงิน เห็นความคืบหน้าแบบไม่ต้องเดา</p>
          </div>
        </div>
        <button
          onClick={() => setShowCreateModal(true)}
          className="bg-white hover:bg-[#B8D4D6] text-[#223248] px-4 py-2 rounded-lg font-bold shadow-md hover:shadow-lg transition-all duration-200 font-be-vietnam-pro"
        >
          + Create Goal
        </button>
      </header>

      {/* Summary Bar */}
      <section className="container mx-auto px-4 py-6">
        <div className="bg-[#B8D4D6] rounded-lg p-4 shadow-md">
          <div className="flex gap-4 items-center flex-wrap justify-center">
            <div className="bg-white/50 px-4 py-2 rounded-full text-sm text-[#223248] font-semibold font-be-vietnam-pro">
              รวม {totalGoals} เป้าหมาย
            </div>
            <div className="bg-white/50 px-4 py-2 rounded-full text-sm text-[#223248] font-semibold font-be-vietnam-pro">
              ออมแล้ว {totalSaved.toLocaleString()} / {totalTarget.toLocaleString()} บาท
            </div>
            <div className="bg-white/50 px-4 py-2 rounded-full text-sm text-[#223248] font-semibold font-be-vietnam-pro">
              สำเร็จรวม ~ {overallProgress}%
            </div>
          </div>
        </div>
      </section>

      {/* Goals Grid */}
      <main className="container mx-auto px-4 pb-12 flex-1">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {goals.map(goal => (
            <article
              key={goal.id}
              className="bg-white rounded-lg p-4 shadow-lg cursor-pointer hover:shadow-xl transition-all duration-200 border-2 border-transparent hover:border-[#4FB7B3]"
              onClick={() => {
                setCurrentGoal(goal);
                setShowDetailDrawer(true);
              }}
            >
              <div className="flex items-center justify-between gap-3 mb-3">
                <div className="flex items-center gap-3">
                  <div className="text-2xl">{goal.emoji}</div>
                  <div>
                    <h3 className="font-bold text-sm text-[#223248] font-be-vietnam-pro">{goal.name}</h3>
                    <p className="text-gray-600 text-xs font-be-vietnam-pro">
                      เก็บแล้ว {goal.saved.toLocaleString()} / {goal.target.toLocaleString()} บาท • เหลือ {goal.duration} {unitLabel(goal.unit)}
                    </p>
                  </div>
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      setCurrentGoal(goal);
                      setShowEditModal(true);
                    }}
                    className="bg-[#B8D4D6] hover:bg-[#4FB7B3] text-[#223248] hover:text-white px-2 py-1 rounded text-xs transition-colors duration-200 font-be-vietnam-pro"
                  >
                    Edit
                  </button>
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      handleDeleteGoal(goal.id);
                    }}
                    className="bg-red-100 hover:bg-red-500 text-red-600 hover:text-white px-2 py-1 rounded text-xs transition-colors duration-200 font-be-vietnam-pro"
                  >
                    Delete
                  </button>
                </div>
              </div>

              {/* Progress Bar */}
              <div className="h-3 bg-[#C7DCDE] rounded-full overflow-hidden mb-3">
                <div
                  className="h-full bg-gradient-to-r from-[#4FB7B3] to-[#3a9793] transition-all duration-300"
                  style={{ width: `${goal.progress}%` }}
                />
              </div>

              <div className="flex items-center justify-between gap-2 text-gray-600 text-xs font-be-vietnam-pro">
                <span>ตัดออมทุก: {unitLabel(goal.unit)} • ~ {goal.perPeriod.toLocaleString()} บาท/{unitLabel(goal.unit)}</span>
                <span>~ {goal.perDay.toLocaleString()} บาท/วัน</span>
              </div>
            </article>
          ))}
        </div>
      </main>

      {/* Create Goal Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 bg-black/30 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg w-full max-w-xl shadow-2xl">
            <div className="flex items-center justify-between p-4 border-b border-gray-200 bg-teal-500 rounded-t-lg">
              <h2 className="font-bold text-lg text-[#223248] font-be-vietnam-pro">สร้างเป้าหมายออมเงิน</h2>
              <button
                onClick={() => setShowCreateModal(false)}
                className="text-[#223248] hover:text-white text-2xl font-bold transition-colors duration-200"
              >
                ×
              </button>
            </div>

            <form onSubmit={handleCreateGoal} className="p-6 space-y-4">
              <div>
                <label className="text-sm text-[#223248] font-semibold block mb-1 font-be-vietnam-pro">เป้าหมาย</label>
                <input
                  type="text"
                  value={goalName}
                  onChange={(e) => setGoalName(e.target.value)}
                  placeholder="เช่น ทริปญี่ปุ่น / กองทุนฉุกเฉิน"
                  className="w-full bg-white border border-gray-300 text-[#223248] px-3 py-2 rounded outline-none focus:ring-4 focus:ring-[#4FB7B3] focus:border-[#4FB7B3] transition-all duration-200 font-be-vietnam-pro"
                  required
                />
              </div>

              <div className="flex gap-3">
                <div className="flex-1">
                  <label className="text-sm text-[#223248] font-semibold block mb-1 font-be-vietnam-pro">จำนวนเงินที่ต้องการเก็บ (บาท)</label>
                  <input
                    type="number"
                    value={goalAmount}
                    onChange={(e) => setGoalAmount(e.target.value)}
                    placeholder="10000"
                    min="0"
                    className="w-full bg-white border border-gray-300 text-[#223248] px-3 py-2 rounded outline-none focus:ring-4 focus:ring-[#4FB7B3] focus:border-[#4FB7B3] transition-all duration-200 font-be-vietnam-pro"
                    required
                  />
                </div>
                <div className="flex-1">
                  <label className="text-sm text-[#223248] font-semibold block mb-1 font-be-vietnam-pro">ระยะเวลา</label>
                  <div className="flex gap-2">
                    <input
                      type="number"
                      value={goalDuration}
                      onChange={(e) => setGoalDuration(e.target.value)}
                      placeholder="3"
                      min="1"
                      className="flex-1 bg-white border border-gray-300 text-[#223248] px-3 py-2 rounded outline-none focus:ring-4 focus:ring-[#4FB7B3] focus:border-[#4FB7B3] transition-all duration-200 font-be-vietnam-pro"
                      required
                    />
                    <select
                      value={goalUnit}
                      onChange={(e) => setGoalUnit(e.target.value as any)}
                      className="flex-1 bg-white border border-gray-300 text-[#223248] px-3 py-2 rounded outline-none focus:ring-4 focus:ring-[#4FB7B3] focus:border-[#4FB7B3] transition-all duration-200 font-be-vietnam-pro"
                    >
                      <option value="day">วัน</option>
                      <option value="week">สัปดาห์</option>
                      <option value="month">เดือน</option>
                      <option value="year">ปี</option>
                    </select>
                  </div>
                </div>
              </div>

              <div>
                <label className="text-sm text-[#223248] font-semibold block mb-2 font-be-vietnam-pro">แผน</label>
                <div className="flex gap-2 flex-wrap">
                  <label className="flex items-center gap-2 bg-[#C7DCDE] border border-gray-300 px-3 py-2 rounded cursor-pointer hover:bg-[#B8D4D6] transition-colors duration-200">
                    <input
                      type="radio"
                      name="plan"
                      value="ประจำวัน"
                      checked={goalPlan === 'ประจำวัน'}
                      onChange={() => setGoalPlan('ประจำวัน')}
                      className="accent-[#4FB7B3]"
                    />
                    <span className="text-sm text-[#223248] font-be-vietnam-pro">ประจำวัน</span>
                  </label>
                  <label className="flex items-center gap-2 bg-[#C7DCDE] border border-gray-300 px-3 py-2 rounded cursor-pointer hover:bg-[#B8D4D6] transition-colors duration-200">
                    <input
                      type="radio"
                      name="plan"
                      value="ลงทุน"
                      checked={goalPlan === 'ลงทุน'}
                      onChange={() => setGoalPlan('ลงทุน')}
                      className="accent-[#4FB7B3]"
                    />
                    <span className="text-sm text-[#223248] font-be-vietnam-pro">ลงทุน (สมมติผลตอบแทน)</span>
                  </label>
                </div>
              </div>

              {goalPlan === 'ลงทุน' && (
                <div>
                  <label className="text-sm text-[#223248] font-semibold block mb-2 font-be-vietnam-pro">สำหรับแผนลงทุน คุณอยากให้ระบบทำอะไร?</label>
                  <div className="flex gap-2 flex-wrap mb-2">
                    <label className="flex items-center gap-2 bg-[#C7DCDE] border border-gray-300 px-3 py-2 rounded cursor-pointer hover:bg-[#B8D4D6] transition-colors duration-200">
                      <input
                        type="radio"
                        name="investMode"
                        value="recommend"
                        checked={investMode === 'recommend'}
                        onChange={() => setInvestMode('recommend')}
                        className="accent-[#4FB7B3]"
                      />
                      <span className="text-sm text-[#223248] font-be-vietnam-pro">แนะนำหุ้น/กองทุนให้</span>
                    </label>
                    <label className="flex items-center gap-2 bg-[#C7DCDE] border border-gray-300 px-3 py-2 rounded cursor-pointer hover:bg-[#B8D4D6] transition-colors duration-200">
                      <input
                        type="radio"
                        name="investMode"
                        value="custom"
                        checked={investMode === 'custom'}
                        onChange={() => setInvestMode('custom')}
                        className="accent-[#4FB7B3]"
                      />
                      <span className="text-sm text-[#223248] font-be-vietnam-pro">ฉันมีรายการในใจอยู่แล้ว</span>
                    </label>
                  </div>
                  {investMode === 'custom' && (
                    <div>
                      <label className="text-sm text-[#223248] font-semibold block mb-1 font-be-vietnam-pro">ใส่สัญลักษณ์หรือชื่อ (คั่นด้วยเครื่องหมายจุลภาค)</label>
                      <input
                        type="text"
                        value={symbols}
                        onChange={(e) => setSymbols(e.target.value)}
                        placeholder="เช่น SET:PTT, SET:BBL, กองทุน ABC"
                        className="w-full bg-white border border-gray-300 text-[#223248] px-3 py-2 rounded outline-none focus:ring-4 focus:ring-[#4FB7B3] focus:border-[#4FB7B3] transition-all duration-200 font-be-vietnam-pro"
                      />
                    </div>
                  )}
                </div>
              )}

              <div className="flex justify-end gap-2 pt-4 border-t border-gray-200">
                <button
                  type="button"
                  onClick={() => setShowCreateModal(false)}
                  className="bg-gray-200 hover:bg-gray-300 text-[#223248] px-6 py-2 rounded font-semibold transition-colors duration-200 font-be-vietnam-pro"
                >
                  ยกเลิก
                </button>
                <button
                  type="submit"
                  className="bg-[#4FB7B3] hover:bg-[#3a9793] text-white px-6 py-2 rounded font-bold shadow-md hover:shadow-lg transition-all duration-200 font-be-vietnam-pro"
                >
                  Save Goal
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Edit Goal Modal */}
      {showEditModal && currentGoal && (
        <div className="fixed inset-0 bg-black/30 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg w-full max-w-xl shadow-2xl">
            <div className="flex items-center justify-between p-4 border-b border-gray-200 bg-teal-500 rounded-t-lg">
              <h2 className="font-bold text-lg text-[#223248] font-be-vietnam-pro">แก้ไขเป้าหมาย</h2>
              <button
                onClick={() => setShowEditModal(false)}
                className="text-[#223248] hover:text-white text-2xl font-bold transition-colors duration-200"
              >
                ×
              </button>
            </div>

            <div className="p-6 space-y-4">
              <div>
                <label className="text-sm text-[#223248] font-semibold block mb-1 font-be-vietnam-pro">ชื่อเป้าหมาย</label>
                <input
                  type="text"
                  value={currentGoal.name}
                  onChange={(e) => setCurrentGoal({...currentGoal, name: e.target.value})}
                  className="w-full bg-white border border-gray-300 text-[#223248] px-3 py-2 rounded outline-none focus:ring-4 focus:ring-[#4FB7B3] focus:border-[#4FB7B3] transition-all duration-200 font-be-vietnam-pro"
                />
              </div>

              <div className="flex gap-3">
                <div className="flex-1">
                  <label className="text-sm text-[#223248] font-semibold block mb-1 font-be-vietnam-pro">ยอดเป้าหมาย (บาท)</label>
                  <input
                    type="number"
                    value={currentGoal.target}
                    onChange={(e) => setCurrentGoal({...currentGoal, target: parseFloat(e.target.value)})}
                    min="0"
                    className="w-full bg-white border border-gray-300 text-[#223248] px-3 py-2 rounded outline-none focus:ring-4 focus:ring-[#4FB7B3] focus:border-[#4FB7B3] transition-all duration-200 font-be-vietnam-pro"
                  />
                </div>
                <div className="flex-1">
                  <label className="text-sm text-[#223248] font-semibold block mb-1 font-be-vietnam-pro">ระยะเวลา</label>
                  <div className="flex gap-2">
                    <input
                      type="number"
                      value={currentGoal.duration}
                      onChange={(e) => setCurrentGoal({...currentGoal, duration: parseInt(e.target.value, 10)})}
                      min="1"
                      className="flex-1 bg-white border border-gray-300 text-[#223248] px-3 py-2 rounded outline-none focus:ring-4 focus:ring-[#4FB7B3] focus:border-[#4FB7B3] transition-all duration-200 font-be-vietnam-pro"
                    />
                    <select
                      value={currentGoal.unit}
                      onChange={(e) => setCurrentGoal({...currentGoal, unit: e.target.value as any})}
                      className="flex-1 bg-white border border-gray-300 text-[#223248] px-3 py-2 rounded outline-none focus:ring-4 focus:ring-[#4FB7B3] focus:border-[#4FB7B3] transition-all duration-200 font-be-vietnam-pro"
                    >
                      <option value="day">วัน</option>
                      <option value="week">สัปดาห์</option>
                      <option value="month">เดือน</option>
                      <option value="year">ปี</option>
                    </select>
                  </div>
                </div>
              </div>

              <div className="flex justify-end gap-2 pt-4 border-t border-gray-200">
                <button
                  onClick={() => setShowEditModal(false)}
                  className="bg-gray-200 hover:bg-gray-300 text-[#223248] px-6 py-2 rounded font-semibold transition-colors duration-200 font-be-vietnam-pro"
                >
                  ยกเลิก
                </button>
                <button
                  onClick={handleEditGoal}
                  className="bg-[#4FB7B3] hover:bg-[#3a9793] text-white px-6 py-2 rounded font-bold shadow-md hover:shadow-lg transition-all duration-200 font-be-vietnam-pro"
                >
                  Save Changes
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Detail Drawer */}
      {showDetailDrawer && currentGoal && (
        <>
          <div
            className="fixed inset-0 bg-black/30 z-40"
            onClick={() => setShowDetailDrawer(false)}
          />
          <aside className={`fixed right-0 top-0 h-full w-full max-w-[560px] bg-white shadow-2xl z-50 flex flex-col transition-transform duration-300 ${showDetailDrawer ? 'translate-x-0' : 'translate-x-full'}`}>
            <div className="flex items-center justify-between p-4 border-b border-gray-200 bg-teal-500">
              <h2 className="font-bold text-lg text-[#223248] font-be-vietnam-pro">{currentGoal.name}</h2>
              <button
                onClick={() => setShowDetailDrawer(false)}
                className="text-[#223248] hover:text-white text-2xl font-bold transition-colors duration-200"
              >
                ×
              </button>
            </div>

            <div className="p-6 overflow-auto flex-1 space-y-4 bg-[#C7DCDE]">
              <div className="bg-white rounded-lg p-4 space-y-3">
                <div className="grid grid-cols-[140px_1fr] gap-2 text-sm">
                  <div className="text-gray-600 font-be-vietnam-pro">ยอดเป้าหมาย</div>
                  <div className="text-[#223248] font-semibold font-be-vietnam-pro">{currentGoal.target.toLocaleString()} บาท</div>
                </div>
                <div className="grid grid-cols-[140px_1fr] gap-2 text-sm">
                  <div className="text-gray-600 font-be-vietnam-pro">ออมแล้ว</div>
                  <div className="text-[#223248] font-semibold font-be-vietnam-pro">{currentGoal.saved.toLocaleString()} บาท</div>
                </div>
                <div className="grid grid-cols-[140px_1fr] gap-2 text-sm">
                  <div className="text-gray-600 font-be-vietnam-pro">ความคืบหน้า</div>
                  <div className="text-[#223248] font-semibold font-be-vietnam-pro">{currentGoal.progress} %</div>
                </div>
                <div className="grid grid-cols-[140px_1fr] gap-2 text-sm">
                  <div className="text-gray-600 font-be-vietnam-pro">ช่วงตัดออม</div>
                  <div className="text-[#223248] font-semibold font-be-vietnam-pro">{currentGoal.duration} {unitLabel(currentGoal.unit)}</div>
                </div>
                <div className="grid grid-cols-[140px_1fr] gap-2 text-sm">
                  <div className="text-gray-600 font-be-vietnam-pro">ยอดตัดออมต่อช่วง</div>
                  <div className="text-[#223248] font-semibold font-be-vietnam-pro">{currentGoal.perPeriod.toLocaleString()} บาท/{unitLabel(currentGoal.unit)}</div>
                </div>
                <div className="grid grid-cols-[140px_1fr] gap-2 text-sm">
                  <div className="text-gray-600 font-be-vietnam-pro">แผน</div>
                  <div>
                    <span className="inline-block bg-[#B8D4D6] px-3 py-1 rounded-full text-xs text-[#223248] font-semibold font-be-vietnam-pro">
                      {currentGoal.plan}
                    </span>
                  </div>
                </div>
                {currentGoal.plan === 'ลงทุน' && (
                  <>
                    <div className="grid grid-cols-[140px_1fr] gap-2 text-sm">
                      <div className="text-gray-600 font-be-vietnam-pro">โหมดการลงทุน</div>
                      <div>
                        <span className="inline-block bg-[#B8D4D6] px-3 py-1 rounded-full text-xs text-[#223248] font-semibold font-be-vietnam-pro">
                          {currentGoal.investMode === 'recommend' ? 'ระบบแนะนำ' : 'ผู้ใช้กำหนดเอง'}
                        </span>
                      </div>
                    </div>
                    {currentGoal.investMode === 'custom' && currentGoal.symbols && (
                      <div className="grid grid-cols-[140px_1fr] gap-2 text-sm">
                        <div className="text-gray-600 font-be-vietnam-pro">รายการที่ระบุ</div>
                        <div className="text-[#223248] font-semibold font-be-vietnam-pro">{currentGoal.symbols}</div>
                      </div>
                    )}
                  </>
                )}
              </div>

              <div className="bg-[#4FB7B3] border-l-4 border-[#3a9793] p-4 rounded-lg text-white text-sm font-be-vietnam-pro shadow-md">
                {currentGoal.progress >= 100
                  ? 'เยี่ยมมาก! เป้าหมายนี้สำเร็จแล้ว 🎉'
                  : `เหลือ ${(currentGoal.target - currentGoal.saved).toLocaleString()} บาท (${currentGoal.duration * unitDays(currentGoal.unit)} วัน) แนะนำตัดออม ~ ${currentGoal.perPeriod.toLocaleString()} บาท/ต่อ ${unitLabel(currentGoal.unit)}`
                }
              </div>
            </div>

            <div className="p-4 border-t border-gray-200 bg-white flex gap-2 justify-end">
              <button
                onClick={() => {
                  setShowDetailDrawer(false);
                  setShowContribModal(true);
                }}
                className="bg-[#B8D4D6] hover:bg-[#4FB7B3] text-[#223248] hover:text-white px-4 py-2 rounded font-bold transition-all duration-200 font-be-vietnam-pro"
              >
                + ใส่เงินออม
              </button>
              <button
                onClick={() => {
                  setShowDetailDrawer(false);
                  setShowEditModal(true);
                }}
                className="bg-[#4FB7B3] hover:bg-[#3a9793] text-white px-4 py-2 rounded font-bold shadow-md hover:shadow-lg transition-all duration-200 font-be-vietnam-pro"
              >
                แก้ไขเป้าหมาย
              </button>
            </div>
          </aside>
        </>
      )}

      {/* Add Contribution Modal */}
      {showContribModal && currentGoal && (
        <div className="fixed inset-0 bg-black/30 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg w-full max-w-md shadow-2xl">
            <div className="flex items-center justify-between p-4 border-b border-gray-200 bg-teal-500 rounded-t-lg">
              <h2 className="font-bold text-lg text-[#223248] font-be-vietnam-pro">ใส่เงินออมเข้าด้วยตัวเอง</h2>
              <button
                onClick={() => setShowContribModal(false)}
                className="text-[#223248] hover:text-white text-2xl font-bold transition-colors duration-200"
              >
                ×
              </button>
            </div>

            <div className="p-6 space-y-4">
              <div>
                <label className="text-sm text-[#223248] font-semibold block mb-1 font-be-vietnam-pro">จำนวนเงิน (บาท)</label>
                <input
                  type="number"
                  value={contribAmount}
                  onChange={(e) => setContribAmount(e.target.value)}
                  placeholder="500"
                  min="1"
                  className="w-full bg-white border border-gray-300 text-[#223248] px-3 py-2 rounded outline-none focus:ring-4 focus:ring-[#4FB7B3] focus:border-[#4FB7B3] transition-all duration-200 font-be-vietnam-pro"
                />
              </div>

              <p className="text-gray-600 text-sm font-be-vietnam-pro">
                เพิ่มเงินออมสำหรับเป้าหมาย "{currentGoal.name}"
              </p>

              <div className="flex justify-end gap-2 pt-4 border-t border-gray-200">
                <button
                  onClick={() => setShowContribModal(false)}
                  className="bg-gray-200 hover:bg-gray-300 text-[#223248] px-6 py-2 rounded font-semibold transition-colors duration-200 font-be-vietnam-pro"
                >
                  ยกเลิก
                </button>
                <button
                  onClick={handleAddContribution}
                  className="bg-[#4FB7B3] hover:bg-[#3a9793] text-white px-6 py-2 rounded font-bold shadow-md hover:shadow-lg transition-all duration-200 font-be-vietnam-pro"
                >
                  Add
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Footer */}
      <footer className="bg-teal-500 text-[#223248] text-center py-4 mt-auto">
        <p className="text-sm font-be-vietnam-pro font-semibold">Copyright 2025 © RMUTTO © MONEY LAB</p>
      </footer>
    </div>
  );
}