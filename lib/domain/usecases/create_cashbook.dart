import 'package:dartz/dartz.dart';
import 'package:kashly/domain/repositories/cashbook_repository.dart';
import 'package:kashly/domain/entities/cashbook.dart';
import 'package:kashly/core/error/exceptions.dart';
import 'package:kashly/core/error/failures.dart';

class CreateCashbookUseCase {
  final CashbookRepository repository;
  CreateCashbookUseCase(this.repository);

  Future<Either<Failure, void>> call(Cashbook cashbook) async {
    try {
      await repository.createCashbook(cashbook);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }
}
