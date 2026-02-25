import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashly/data/repositories/cashbook_repository_impl.dart';
import 'package:kashly/domain/repositories/cashbook_repository.dart';
import 'package:kashly/data/datasources/local_datasource.dart';
import 'package:kashly/services/backup/backup_service.dart';
import 'package:kashly/services/sync_engine/sync_service.dart';
import 'package:kashly/features/auth/auth_provider.dart';

// Datasources
final localDatasourceProvider = Provider<LocalDatasource>((ref) => LocalDatasource());

// Repositories
final cashbookRepositoryProvider = Provider<CashbookRepository>((ref) => CashbookRepositoryImpl(ref.watch(localDatasourceProvider)));

// Services
final backupServiceProvider = Provider<BackupService>((ref) => BackupService());
final syncServiceProvider = Provider<SyncService>((ref) => SyncService());

// Auth
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

// Add more for transactions, etc.
