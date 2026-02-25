import 'package:kashly/domain/repositories/cashbook_repository.dart';
import 'package:kashly/data/datasources/local_datasource.dart';
import 'package:kashly/domain/entities/cashbook.dart';
import 'package:kashly/core/error/exceptions.dart'; // Integrated exceptions

class CashbookRepositoryImpl implements CashbookRepository {
  final LocalDatasource localDatasource;

  CashbookRepositoryImpl(this.localDatasource);

  @override
  Future<void> createCashbook(Cashbook cashbook) async {
    try {
      await localDatasource.insertCashbook(cashbook);
    } catch (e) {
      throw CacheException('Failed to insert cashbook: $e'); // Use CacheException for DB errors
    }
  }

  @override
  Future<List<Cashbook>> getCashbooks() async {
    try {
      return await localDatasource.getCashbooks();
    } catch (e) {
      throw CacheException('Failed to fetch cashbooks: $e');
    }
  }

  // Add edit, delete, etc. with similar try-catch
}
