import 'package:kashly/domain/repositories/cashbook_repository.dart';
import 'package:kashly/data/datasources/local_datasource.dart';
import 'package:kashly/domain/entities/cashbook.dart';

class CashbookRepositoryImpl implements CashbookRepository {
  final LocalDatasource localDatasource;

  CashbookRepositoryImpl(this.localDatasource);

  @override
  Future<void> createCashbook(Cashbook cashbook) async {
    await localDatasource.insertCashbook(cashbook);
  }

  @override
  Future<List<Cashbook>> getCashbooks() async {
    return await localDatasource.getCashbooks();
  }

  // Add edit, delete, etc.
}
