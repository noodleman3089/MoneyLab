import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'UserProfilePage.dart';
import 'GoalPageState.dart';
import 'Additional.dart';
import 'DailyManagement.dart';
import 'SpendingSummary.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Financial App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 2; // เริ่มต้นที่ จัดการรายวัน

  final List<Widget> _pages = [
    const GoalPage(),
    const SpendingSummaryPage(),
    const DailyManagementPage(),
    const UserProfilePage(),
    const AdditionalPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            icon: '🎯',
            label: 'เป้าหมาย',
            gradient: const LinearGradient(
              colors: [Color(0xFFfa709a), Color(0xFFfee140)],
            ),
          ),
          _buildNavItem(
            index: 1,
            icon: '📊',
            label: 'สรุปรายรับ',
            gradient: const LinearGradient(
              colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
            ),
          ),
          _buildNavItem(
            index: 2,
            icon: '📋',
            label: 'จัดการรายวัน',
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
          _buildNavItem(
            index: 3,
            icon: '👤',
            label: 'โปรไฟล์',
            gradient: const LinearGradient(
              colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
            ),
          ),
          _buildNavItem(
            index: 4,
            icon: '...',
            label: 'เพิ่มเติม',
            gradient: const LinearGradient(
              colors: [Color(0xFF9E9E9E), Color(0xFF757575)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String icon,
    required String label,
    required Gradient gradient,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Indicator line
              Container(
                width: 20,
                height: 2,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1a7f7f) : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 2),
              // Icon
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: gradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Label
              Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF1a7f7f) : const Color(0xFF666666),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Sample Pages
class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สรุปรายรับรายจ่าย'),
        backgroundColor: const Color(0xFF1a7f7f),
      ),
      body: const Center(
        child: Text(
          'หน้าสรุปรายรับ',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มเติม'),
        backgroundColor: const Color(0xFF1a7f7f),
      ),
      body: const Center(
        child: Text(
          'หน้าเพิ่มเติม',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
