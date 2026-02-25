import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kashly/data/datasources/local_datasource.dart';
import 'package:kashly/data/repositories/cashbook_repository_impl.dart';
import 'package:kashly/domain/entities/cashbook.dart';

class MockLocalDatasource extends Mock implements LocalDatasource {}

void main() {
  late CashbookRepositoryImpl repo;
  late MockLocalDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockLocalDatasource();
    repo = CashbookRepositoryImpl(mockDatasource);
  });

  final testCashbook = Cashbook(
    id: 'test-id',
    name: 'Test Book',
    currency: 'USD',
    openingBalance: 1000.0,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    syncStatus: SyncStatus.pending,
    backupSettings: const BackupSettings(
      autoBackupEnabled: false,
      includeAttachments: false,
    ),
  );

  group('CashbookRepository', () {
    test('createCashbook calls datasource insertCashbook', () async {
      when(() => mockDatasource.insertCashbook(testCashbook)).thenAnswer((_) async {});
      await repo.createCashbook(testCashbook);
      verify(() => mockDatasource.insertCashbook(testCashbook)).called(1);
    });

    test('getCashbooks returns list from datasource', () async {
      when(() => mockDatasource.getCashbooks()).thenAnswer((_) async => [testCashbook]);
      final result = await repo.getCashbooks();
      expect(result, [testCashbook]);
    });

    test('deleteCashbook calls datasource delete', () async {
      when(() => mockDatasource.deleteCashbook('test-id')).thenAnswer((_) async {});
      await repo.deleteCashbook('test-id');
      verify(() => mockDatasource.deleteCashbook('test-id')).called(1);
    });

    test('getCashbookById returns null when not found', () async {
      when(() => mockDatasource.getCashbookById('missing')).thenAnswer((_) async => null);
      final result = await repo.getCashbookById('missing');
      expect(result, isNull);
    });
  });
}
