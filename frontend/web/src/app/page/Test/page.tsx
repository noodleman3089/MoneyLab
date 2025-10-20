'use client';
import React, { useState } from 'react';
import axios from "axios";
import Navbar from '@/app/components/Navbar';
import Footer from '@/app/components/Footer';

export default function TestPage() {

    return (
        // Background
        <div className="min-h-screen bg-white flex flex-col">
            <Navbar />
                {/* Center */}
                <main className="container mx-auto px-4 py-auto min-h-screen">
                    <h1 className = "text-6xl text-black text-center py-16 px-16">
                        ไก่
                    </h1>
                </main>
            <Footer />
        </div>
    );
}