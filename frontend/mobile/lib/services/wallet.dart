// lib/services/wallet.dart
class Wallet {
  final int walletId;
  final String walletName;
  final String currency;
  final double balance;
  
  // (คุณสามารถเพิ่ม totals ได้ ถ้าต้องการ)

  Wallet({
    required this.walletId,
    required this.walletName,
    required this.currency,
    required this.balance,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      walletId: json['wallet_id'],
      walletName: json['wallet_name'],
      currency: json['currency'],
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}