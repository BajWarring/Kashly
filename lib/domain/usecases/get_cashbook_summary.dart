import 'package:dartz/dartz.dart';
import 'package:kashly/domain/repositories/cashbook_repository.dart';
import 'package:kashly/core/error/exceptions.dart';
import 'package:kashly/core/error/failures.dart';

class CashbookSummary {
  final double balance;
  final double totalIn;
  final double totalOut;
  final double reconciledAmount;

  const CashbookSummary({
    required this.balance,
    required this.totalIn,
    required this.totalOut,
    required this.reconciledAmount,
  });
}

class GetCashbookSummaryUseCase {
  final CashbookRepository repository;
  GetCashbookSummaryUseCase(this.repository);

  Future<Either<Failure, CashbookSummary>> call(String cashbookId) async {
    try {
      final balance = await repository.getBalance(cashbookId);
      final totalIn = await repository.getTotalIn(cashbookId);
      final totalOut = await repository.getTotalOut(cashbookId);
      final reconciled = await repository.getReconciledAmount(cashbookId);
      return Right(CashbookSummary(
        balance: balance,
        totalIn: totalIn,
        totalOut: totalOut,
        reconciledAmount: reconciled,
      ));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
