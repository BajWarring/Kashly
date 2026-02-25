import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'services/backup/backup_service.dart';

void main() {
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true); // For background tasks
  runApp(const ProviderScope(child: KashlyApp()));
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    // Handle background backups/sync
    final backupService = BackupService(); // Inject if needed
    backupService.performScheduledBackup();
    return Future.value(true);
  });
}

class KashlyApp extends ConsumerWidget {
  const KashlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Kashly',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: ref.watch(goRouterProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}
