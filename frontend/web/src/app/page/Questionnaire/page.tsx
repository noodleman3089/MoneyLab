// 1. Importing Dependencies
'use client' // ต้องใช้เพราะใช้ useState และ window, localStorage
import React, { useState, FormEvent } from 'react';
import axios from "axios";

// 2. Creating and Exporting a Component
export default function QuestionnairePage() {

  // 2.1 Defining Variables, States, and Handlers
  // สร้างตัวแปร state สำหรับเก็บคำตอบของแต่ละคำถาม (10 คำถาม)
  const [answers, setAnswers] = useState<{ [key: string]: string[] }>({
    q1: [],
    q2: [],
    q3: [],
    q4: [],
    q5: [],
    q6: [],
    q7: [],
    q8: [],
    q9: [],
    q10: []
  });

  // คำถามทั้งหมด
  const questions = [
    {
      id: 'q1',
      title: 'ไก่กับไข่อะไรเกิดก่อน',
      options: ['ไม่รู้', 'ไม่แน่ใจ', 'ไม่ตอบ', 'ไก่']
    },
    {
      id: 'q2',
      title: 'คำถามที่2',
      options: ['ตัวเลือกที่1', 'ตัวเลือกที่2', 'ตัวเลือกที่3', 'ตัวเลือกที่4']
    },
    {
      id: 'q3',
      title: 'คำถามที่3',
      options: ['ตัวเลือกที่1', 'ตัวเลือกที่2', 'ตัวเลือกที่3', 'ตัวเลือกที่4']
    },
    {
      id: 'q4',
      title: 'คำถามที่4',
      options: ['ตัวเลือกที่1', 'ตัวเลือกที่2', 'ตัวเลือกที่3', 'ตัวเลือกที่4']
    },
    {
      id: 'q5',
      title: 'คำถามที่5',
      options: ['ตัวเลือกที่1', 'ตัวเลือกที่2', 'ตัวเลือกที่3', 'ตัวเลือกที่4']
    },
    {
      id: 'q6',
      title: 'คำถามที่6',
      options: ['ตัวเลือกที่1', 'ตัวเลือกที่2', 'ตัวเลือกที่3', 'ตัวเลือกที่4']
    },
    {
      id: 'q7',
      title: 'คำถามที่7',
      options: ['ตัวเลือกที่1', 'ตัวเลือกที่2', 'ตัวเลือกที่3', 'ตัวเลือกที่4']
    },
    {
      id: 'q8',
      title: 'คำถามที่8',
      options: ['ตัวเลือกที่1', 'ตัวเลือกที่2', 'ตัวเลือกที่3', 'ตัวเลือกที่4']
    },
    {
      id: 'q9',
      title: 'คำถามที่9',
      options: ['ตัวเลือกที่1', 'ตัวเลือกที่2', 'ตัวเลือกที่3', 'ตัวเลือกที่4']
    },
    {
      id: 'q10',
      title: 'คำถามที่10',
      options: ['ตัวเลือกที่1', 'ตัวเลือกที่2', 'ตัวเลือกที่3', 'ตัวเลือกที่4']
    }
  ];

  // ฟังก์ชันจัดการการเปลี่ยนแปลง checkbox
  const handleCheckboxChange = (questionId: string, option: string) => {
    setAnswers(prev => {
      const currentAnswers = prev[questionId] || [];
      const isChecked = currentAnswers.includes(option);

      if (isChecked) {
        // ถ้าเลือกแล้ว ให้ลบออก
        return {
          ...prev,
          [questionId]: currentAnswers.filter(item => item !== option)
        };
      } else {
        // ถ้ายังไม่เลือก ให้เพิ่มเข้าไป
        return {
          ...prev,
          [questionId]: [...currentAnswers, option]
        };
      }
    });
  };

  // สร้างฟังก์ชันสำหรับจัดการการ submit form ไปยัง API
  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault(); // ป้องกัน reload หน้า

    try {
      // ใช้ axios เพื่อส่ง POST request ไปยัง API
      const response = await axios.post("http://localhost:4000/api/questionnaire", {
        answers
      });

      const result = response.data; // รับข้อมูลจาก API
      alert(result.message); // แสดงข้อความจาก API

      // ถ้าส่งแบบสอบถามสำเร็จ จะ redirect ไปหน้าแรก
      if (result.status === true) {
        window.location.href = "/page/Main"; // เปลี่ยนเป็นหน้า Main
      }
    } catch (error) {
      console.error("Questionnaire submission error:", error); // แสดงข้อผิดพลาดใน console
      alert("Failed to submit questionnaire. Please try again."); // แสดงข้อความเมื่อส่งไม่สำเร็จ
    }
  };

  const handleNextPage = () => {
    window.location.href = "/page/Main"; //เอาไว้ทดสอบการเปลี่ยนหน้า
  }
  
  return (
    <div className="min-h-screen bg-white flex flex-col">
      {/* Header */}
      <header className="bg-teal-500 text-[#223248] py-4 px-6 flex items-center justify-between">
        <div className="text-[32px] font-extrabold font-be-vietnam-pro">MONEY LAB</div>
        <div className="flex items-center gap-4">
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-4 py-8 max-w-3xl">
        <h1 className="text-[#223248] text-3xl font-semibold text-center mb-8 font-be-vietnam-pro">
          แบบสอบถามเรื่องการใช้งาน
        </h1>

        <form onSubmit={handleSubmit} className="bg-[#B8D4D6] rounded-lg p-6 shadow-lg">
          {/* Questions */}
          <div className="space-y-6">
            {questions.map((question) => (
              <div key={question.id} className="bg-white/30 rounded-lg p-4">
                <h2 className="text-[#223248] text-lg font-semibold mb-3 font-be-vietnam-pro">
                  {question.title}
                </h2>
                <div className="space-y-2">
                  {question.options.map((option, index) => (
                    <label
                      key={index}
                      className="flex items-center gap-3 text-[#223248] cursor-pointer hover:bg-white/20 p-2 rounded transition-colors duration-200 font-be-vietnam-pro"
                    >
                      <input
                        type="checkbox"
                        checked={answers[question.id]?.includes(option) || false}
                        onChange={() => handleCheckboxChange(question.id, option)}
                        className="w-4 h-4 text-[#4FB7B3] bg-white border-gray-300 rounded focus:ring-[#4FB7B3] focus:ring-2"
                      />
                      <span className="text-sm">{option}</span>
                    </label>
                  ))}
                </div>
              </div>
            ))}
          </div>

          {/* Submit Button */}
          <div className="mt-8 flex justify-center">
            <button
              type="submit"
              className="w-[155px] h-[40px] bg-[#4FB7B3] hover:bg-[#3a9793] text-white font-bold rounded-[20px] transition-colors duration-200 font-be-vietnam-pro flex items-center justify-center shadow-md"
            >
              Submit
            </button>

             {/* ปุ่มเปลี่ยนหน้าชั่วคราว */}
            <button
              type='button'
              onClick={handleNextPage}
              className='w-[155px] h-[40px] bg-[#4FB7B3] hover:bg-[#C7DCDE] text-white hover:text-[#008170] font-bold rounded-[20px] hover:border-2 hover:border-[#4FB7B3] hover:shadow-none mt-6 transition-colors duration-200 font-be-vietnam-pro mx-auto shadow-md'
            >
              Test Next Page
            </button>

          </div>
        </form>
      </main>

      {/* Footer */}
      <footer className="bg-teal-500 text-[#223248] text-center py-3 mt-auto">
        <p className="text-sm font-be-vietnam-pro font-semibold">Copyright 2025 © RMUTTO © MONEY LAB</p>
      </footer>
    </div>
  )
}
