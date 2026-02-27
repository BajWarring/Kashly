import 'package:kashly/domain/repositories/cashbook_repository.dart';
import 'package:kashly/data/datasources/local_datasource.dart';
import 'package:kashly/domain/entities/cashbook.dart';
import 'package:kashly/core/error/exceptions.dart';

class CashbookRepositoryImpl implements CashbookRepository {
  final LocalDatasource localDatasource;

  CashbookRepositoryImpl(this.localDatasource);

  @override
  Future<void> createCashbook(Cashbook cashbook) async {
    try {
      await localDatasource.insertCashbook(cashbook);
    } catch (e) {
      throw CacheException('Failed to create cashbook: $e');
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

  @override
  Future<Cashbook?> getCashbookById(String id) async {
    try {
      return await localDatasource.getCashbookById(id);
    } catch (e) {
      throw CacheException('Failed to fetch cashbook: $e');
    }
  }

  @override
  Future<void> updateCashbook(Cashbook cashbook) async {
    try {
      await localDatasource.updateCashbook(cashbook);
    } catch (e) {
      throw CacheException('Failed to update cashbook: $e');
    }
  }

  @override
  Future<void> deleteCashbook(String id) async {
    try {
      await localDatasource.deleteCashbook(id);
    } catch (e) {
      throw CacheException('Failed to delete cashbook: $e');
    }
  }

  @override
  Future<void> archiveCashbook(String id, bool archived) async {
    try {
      final cb = await localDatasource.getCashbookById(id);
      if (cb == null) throw const CacheException('Cashbook not found');
      await localDatasource.updateCashbook(cb.copyWith(isArchived: archived));
    } catch (e) {
      throw CacheException('Failed to archive cashbook: $e');
    }
  }

  @override
  Future<double> getBalance(String cashbookId) async {
    try {
      return await localDatasource.getCashbookBalance(cashbookId);
    } catch (e) {
      throw CacheException('Failed to get balance: $e');
    }
  }

  @override
  Future<double> getTotalIn(String cashbookId) async {
    return await localDatasource.getTotalIn(cashbookId);
  }

  @override
  Future<double> getTotalOut(String cashbookId) async {
    return await localDatasource.getTotalOut(cashbookId);
  }

  @override
  Future<double> getReconciledAmount(String cashbookId) async {
    return await localDatasource.getReconciledAmount(cashbookId);
  }
}
