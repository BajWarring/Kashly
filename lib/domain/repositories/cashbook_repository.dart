import 'package:kashly/domain/entities/cashbook.dart';

abstract class CashbookRepository {
  Future<void> createCashbook(Cashbook cashbook);
  Future<List<Cashbook>> getCashbooks();
  Future<Cashbook?> getCashbookById(String id);
  Future<void> updateCashbook(Cashbook cashbook);
  Future<void> deleteCashbook(String id);
  Future<void> archiveCashbook(String id, bool archived);
  Future<double> getBalance(String cashbookId);
  Future<double> getTotalIn(String cashbookId);
  Future<double> getTotalOut(String cashbookId);
  Future<double> getReconciledAmount(String cashbookId);
}
