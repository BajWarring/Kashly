import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_history.freezed.dart';
part 'transaction_history.g.dart';

@freezed
class TransactionHistory with _$TransactionHistory {
  const factory TransactionHistory(
    { 
      required String id,
      required String transactionId,
      required String fieldName,
      required String oldValue,
      required String newValue,
      required String changedBy,
      required DateTime changedAt,
    } 
  ) = _TransactionHistory;

  factory TransactionHistory.fromJson(Map<String, Object?> json) => _$TransactionHistoryFromJson(json);
}
