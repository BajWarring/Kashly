import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';

import 'core/theme.dart';
import 'core/services/sync_work_manager_service.dart';
import 'screens/dashboard/dashboard_main.dart';

void main() async {
  // Must be called before any plugin or async code in main().
  WidgetsFlutterBinding.ensureInitialized();

  // Transparent status bar — keeps the UI clean and modern.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // ── WorkManager initialisation ─────────────────────────────────────────────
  //
  // [callbackDispatcher] is the top-level entry-point defined in
  // sync_work_manager_service.dart. WorkManager launches a separate Dart
  // isolate and calls it when a scheduled task fires — even if the app has
  // been swiped away from recents or the phone has rebooted.
  //
  // isInDebugMode: set to true during development to see verbose WorkManager
  // logs in Android Studio. Switch to false before releasing.
  

  runApp(const KashlyApp());
}

class KashlyApp extends StatelessWidget {
  const KashlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kashly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: appBg,
        primaryColor: accent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          primary: accent,
          error: danger,
          surface: appBg,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: textDark),
          titleTextStyle: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        cardTheme: CardThemeData(
          color: cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: borderCol),
          ),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
