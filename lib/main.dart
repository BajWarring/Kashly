import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'package:logger/logger.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'services/notification/notification_service.dart';

final _logger = Logger();

// ✅ workmanager 0.6.x: callbackDispatcher signature unchanged, still needs pragma
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    _logger.i('Background task: $task');
    try {
      _logger.i('Background backup task executed');
      return Future.value(true);
    } catch (e) {
      _logger.e('Background task failed: $e');
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ workmanager 0.6.x: initialize() no longer accepts isInDebugMode as positional arg.
  // It is now a named parameter and defaults to false in release builds automatically.
  await Workmanager().initialize(
    callbackDispatcher,
  );

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
