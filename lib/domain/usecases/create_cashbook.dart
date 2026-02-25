import 'package:kashly/domain/repositories/cashbook_repository.dart';
import 'package:kashly/domain/entities/cashbook.dart';
import 'package:kashly/core/error/exceptions.dart';
import 'package:kashly/core/error/failures.dart';
import 'package:dartz/dartz.dart'; // Add dartz to pubspec for Either if not already (dev_dependencies)

class CreateCashbookUseCase {
  final CashbookRepository repository;

  CreateCashbookUseCase(this.repository);

  Future<Either<Failure, void>> call(Cashbook cashbook) async {
    try {
      await repository.createCashbook(cashbook);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on Exception catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }
}
