import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

String calculateMd5(File file) {
  final bytes = file.readAsBytesSync();
  return md5.convert(bytes).toString();
}

String calculateMd5FromBytes(List<int> bytes) {
  return md5.convert(bytes).toString();
}

String formatDateTime(DateTime dt) {
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
}

String formatDate(DateTime dt) {
  return DateFormat('MMM dd, yyyy').format(dt);
}

String formatDateShort(DateTime dt) {
  return DateFormat('dd/MM/yy').format(dt);
}

String formatCurrency(double amount, String currency) {
  final format = NumberFormat.currency(symbol: currency, decimalDigits: 2);
  return format.format(amount);
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

String generateUuid() {
  final random = DateTime.now().millisecondsSinceEpoch.toString();
  final hash = md5.convert(utf8.encode(random)).toString();
  return '${hash.substring(0, 8)}-${hash.substring(8, 12)}-${hash.substring(12, 16)}-${hash.substring(16, 20)}-${hash.substring(20, 32)}';
}

bool isNetworkError(Exception e) {
  return e.toString().contains('SocketException') ||
      e.toString().contains('NetworkException') ||
      e.toString().contains('TimeoutException');
}

String truncate(String text, {int maxLength = 30}) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}...';
}
