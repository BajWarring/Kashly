import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme.dart';
import 'screens/dashboard/dashboard_main.dart';

void main() {
  // Ensures Flutter is fully initialized before setting system styles
  WidgetsFlutterBinding.ensureInitialized();
  
  // Makes the top status bar transparent for a clean, modern UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const KashlyApp());
}

class KashlyApp extends StatelessWidget {
  const KashlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kashly',
      debugShowCheckedModeBanner: false, // Removes the red "DEBUG" banner
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
        // Make default card styling match our custom theme
        cardTheme: CardTheme(
          color: cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: borderCol),
          ),
        ),
      ),
      // Set our custom dashboard as the starting screen
      home: const DashboardScreen(), 
    );
  }
}
