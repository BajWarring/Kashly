import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'package:logger/logger.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'services/notification/notification_service.dart';

final _logger = Logger();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    _logger.i('Background task: $task');
    try {
      // Note: In full production, use a ProviderContainer with proper setup
      // For now we log and return success
      _logger.i('Background backup task executed');
      return true;
    } catch (e) {
      _logger.e('Background task failed: $e');
      return false;
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize WorkManager for background tasks
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // Initialize notifications
  await NotificationService().init();

  runApp(const ProviderScope(child: KashlyApp()));
}

class KashlyApp extends ConsumerWidget {
  const KashlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Kashly',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
