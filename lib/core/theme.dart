import 'package:flutter/material.dart';

// --- COLORS ---
const Color appBg = Color(0xFFF1F5F9);
const Color cardBg = Color(0xFFFFFFFF);
const Color textDark = Color(0xFF0F172A);
const Color textMuted = Color(0xFF64748B);
const Color textLight = Color(0xFF94A3B8);
const Color accent = Color(0xFF4F46E5);
const Color accentLight = Color(0xFFEEF2FF);
const Color danger = Color(0xFFE11D48);
const Color dangerLight = Color(0xFFFFF1F2);
const Color success = Color(0xFF10B981);
const Color successLight = Color(0xFFECFDF5);
const Color borderCol = Color(0xFFE2E8F0);

// --- CURRENCIES ---
class Currency {
  final String code, name, symbol;
  Currency(this.code, this.name, this.symbol);
}

final List<Currency> worldCurrencies = [
  Currency('INR', 'Indian Rupee', '₹'),
  Currency('USD', 'US Dollar', '\$'),
  Currency('EUR', 'Euro', '€'),
  Currency('GBP', 'British Pound', '£'),
  Currency('AED', 'UAE Dirham', 'د.إ'),
];

// --- ICONS ---
final Map<String, IconData> availableIcons = {
  'wallet': Icons.account_balance_wallet,
  'briefcase': Icons.work,
  'plane': Icons.flight,
  'coffee': Icons.local_cafe,
  'cart': Icons.shopping_cart,
  'zap': Icons.flash_on,
  'home': Icons.home,
};
