import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

String calculateMd5(File file) {
  final bytes = file.readAsBytesSync();
  return md5.convert(bytes).toString();
}

String formatDateTime(DateTime dt) {
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
}

// More utils for encryption, etc.
