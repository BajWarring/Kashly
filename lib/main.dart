import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: KashlyApp()));
}

class KashlyApp extends ConsumerWidget {
  const KashlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Kashly',
      theme: AppTheme.lightTheme,      // corporate_fintech
      darkTheme: AppTheme.darkTheme,   // Material3 dark
      themeMode: ThemeMode.dark,       // as per spec
      routerConfig: ref.watch(goRouterProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}
