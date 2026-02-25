import 'package:kashly/domain/entities/cashbook.dart';

abstract class CashbookRepository {
  Future<void> createCashbook(Cashbook cashbook);
  Future<List<Cashbook>> getCashbooks();
  // Add more
}
