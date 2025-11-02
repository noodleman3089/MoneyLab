import 'package:flutter/material.dart';

class DailySummary {
  final double dailyGoal;
  final double currentSpending;
  final List<Transaction> transactions;

  DailySummary({
    required this.dailyGoal,
    required this.currentSpending,
    required this.transactions,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    var transactionsList = json['transactions'] as List;
    List<Transaction> transactions =
        transactionsList.map((i) => Transaction.fromJson(i)).toList();

    return DailySummary(
      dailyGoal: (json['daily_goal'] as num?)?.toDouble() ?? 0.0,
      currentSpending: (json['current_spending'] as num?)?.toDouble() ?? 0.0,
      transactions: transactions,
    );
  }
}

class Transaction {
  final int id;
  final String description;
  final String category;
  final double amount;
  final String type;
  final DateTime transactionDate;

  Transaction({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.type,
    required this.transactionDate,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // สร้าง description จาก sender/receiver ถ้าไม่มี
    String desc = json['description'] ?? json['receiver_name'] ?? json['sender_name'] ?? 'ไม่มีรายละเอียด';

    return Transaction(
      id: json['transaction_id'],
      description: desc,
      category: json['category_name'] ?? 'ไม่ระบุ',
      amount: (json['amount'] as num).toDouble(),
      type: json['type'],
      transactionDate: DateTime.parse(json['transaction_date']),
    );
  }
}