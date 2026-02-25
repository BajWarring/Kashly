import 'package:kashly/domain/repositories/cashbook_repository.dart';
import 'package:kashly/domain/entities/cashbook.dart';

class CreateCashbookUseCase {
  final CashbookRepository repository;

  CreateCashbookUseCase(this.repository);

  Future<void> call(Cashbook cashbook) async {
    await repository.createCashbook(cashbook);
  }
}
