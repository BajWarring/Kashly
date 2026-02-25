import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kashly/data/datasources/local_datasource.dart';
import 'package:kashly/data/repositories/transaction_repository_impl.dart';
import 'package:kashly/domain/entities/transaction.dart';
import 'package:kashly/domain/entities/transaction_history.dart';

class MockLocalDatasource extends Mock implements LocalDatasource {}

void main() {
  late TransactionRepositoryImpl repo;
  late MockLocalDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockLocalDatasource();
    repo = TransactionRepositoryImpl(mockDatasource);
  });

  final testTx = Transaction(
    id: 'tx-1',
    cashbookId: 'cb-1',
    amount: 500.0,
    type: TransactionType.cashIn,
    category: 'Salary',
    remark: 'Monthly salary',
    method: 'Bank Transfer',
    date: DateTime(2024, 6, 1),
    createdAt: DateTime(2024, 6, 1),
    updatedAt: DateTime(2024, 6, 1),
    syncStatus: TransactionSyncStatus.pending,
    driveMeta: const DriveMeta(),
  );

  group('TransactionRepository', () {
    test('createTransaction calls datasource', () async {
      when(() => mockDatasource.insertTransaction(testTx)).thenAnswer((_) async {});
      await repo.createTransaction(testTx);
      verify(() => mockDatasource.insertTransaction(testTx)).called(1);
    });

    test('getTransactions returns list', () async {
      when(() => mockDatasource.getTransactions('cb-1')).thenAnswer((_) async => [testTx]);
      final result = await repo.getTransactions('cb-1');
      expect(result, [testTx]);
      expect(result.first.amount, 500.0);
    });

    test('getNonUploadedTransactions filters correctly', () async {
      when(() => mockDatasource.getNonUploadedTransactions()).thenAnswer((_) async => [testTx]);
      final result = await repo.getNonUploadedTransactions();
      expect(result.length, 1);
    });

    test('getHistory returns history list', () async {
      when(() => mockDatasource.getHistory('tx-1')).thenAnswer((_) async => []);
      final result = await repo.getHistory('tx-1');
      expect(result, isEmpty);
    });
  });
}
