import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';

/// Detects Android battery optimisation restrictions and prompts the user to
/// disable them so WorkManager can run background sync reliably.
///
/// The dialog is shown **only once** (first app launch after sign-in) and only
/// when the system has marked Kashly as battery-optimised.
///
/// Usage — call from [DashboardScreen.initState]:
/// ```dart
/// WidgetsBinding.instance.addPostFrameCallback((_) {
///   BackgroundPermissionHelper.checkAndPrompt(context);
/// });
/// ```
class BackgroundPermissionHelper {
  BackgroundPermissionHelper._();

  static const String _prefKey = 'battery_opt_dialog_shown';

  // ── Entry point ────────────────────────────────────────────────────────────

  /// Checks battery optimisation status and, if needed, shows the guidance
  /// dialog. No-ops on iOS or if the dialog was already shown before.
  static Future<void> checkAndPrompt(BuildContext context) async {
    // Only relevant on Android.
    if (!Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefKey) == true) return; // Already handled.

    // [isGranted] on ignoreBatteryOptimizations == true means the app is
    // already excluded from optimisation (unrestricted). Nothing to do.
    final alreadyUnrestricted =
        await Permission.ignoreBatteryOptimizations.isGranted;

    await prefs.setBool(_prefKey, true); // Mark as shown regardless.

    if (alreadyUnrestricted) return;

    if (!context.mounted) return;
    await _showDialog(context);
  }

  // ── Dialog ─────────────────────────────────────────────────────────────────

  static Future<void> _showDialog(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        title: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: accentLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.battery_saver_rounded,
                color: accent,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enable Background Sync',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: textDark,
              ),
            ),
          ],
        ),
        content: const Text(
          'To keep your financial data safely synced even when Kashly is '
          'closed or the phone restarts, please allow background activity '
          'and disable battery restrictions for Kashly.',
          textAlign: TextAlign.center,
          style: TextStyle(color: textMuted, fontSize: 13, height: 1.6),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actions: [
          // ── Later ──────────────────────────────────────────────────────────
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: textMuted,
              side: const BorderSide(color: borderCol),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Later'),
          ),
          const SizedBox(width: 12),
          // ── Open Settings ──────────────────────────────────────────────────
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // On Android, [request()] on this permission navigates the user
              // directly to the battery optimisation settings for this app.
              await Permission.ignoreBatteryOptimizations.request();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
