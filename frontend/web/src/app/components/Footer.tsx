// 1. Importing Dependencies
'use client'; // ต้องใช้เพราะใช้ useState และ window, localStorage
import React from 'react'
import axios from "axios";

export default function Footer() {
    return (
        <div>
             {/* Footer */}
                <footer className="bg-teal-500 text-[#223248] text-center py-4 mt-auto">
                    <p className="text-sm font-be-vietnam-pro font-semibold"
                    >
                        Copyright 2025 © RMUTTO © MONEY LAB
                    </p>
                </footer>
        </div>
    )
}