import 'package:dartz/dartz.dart';
import 'package:kashly/domain/repositories/transaction_repository.dart';
import 'package:kashly/domain/entities/transaction.dart';
import 'package:kashly/core/error/exceptions.dart';
import 'package:kashly/core/error/failures.dart';

class CreateTransactionUseCase {
  final TransactionRepository repository;
  CreateTransactionUseCase(this.repository);

  Future<Either<Failure, void>> call(Transaction transaction) async {
    try {
      if (transaction.amount <= 0) {
        return const Left(ValidationFailure('Amount must be positive'));
      }
      await repository.createTransaction(transaction);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }
}
