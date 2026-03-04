import 'package:workmanager/workmanager.dart';

/// Utility that manages all WorkManager task registration for Kashly.
///
/// Three task types:
///   • [schedulePeriodic] — runs every 15 min regardless of app state.
///   • [scheduleOneTime]  — fires once, as soon as network is available;
///                          registered after every local DB write so data is
///                          never lost if the app is killed before the
///                          foreground 30-second debounce fires.
///   • [cancelOneTime]    — called after a successful foreground sync so the
///                          pending one-time task doesn't duplicate the work.
///   • [cancelAll]        — called on Google sign-out.
class SyncScheduler {
  SyncScheduler._();

  // ── Task identity constants ────────────────────────────────────────────────
  static const String _periodicUniqueName = 'kashly_periodic_sync';
  static const String _oneTimeUniqueName  = 'kashly_one_time_sync';

  /// Shared tag — used to cancel ALL Kashly tasks in one call.
  static const String taskTag = 'kashly_sync';

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Registers (or retains) the 15-minute periodic background sync.
  ///
  /// Safe to call on every app launch — [ExistingWorkPolicy.keep] means
  /// WorkManager ignores the call if an identical task already exists.
  static Future<void> schedulePeriodic() async {
    await Workmanager().registerPeriodicTask(
      _periodicUniqueName,
      _periodicUniqueName,
      tag: taskTag,
      // 15 minutes is the OS-enforced minimum on Android.
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      // Don't reset an already-scheduled periodic task on every app launch.
      existingWorkPolicy: ExistingWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 2),
    );
  }

  /// Schedules a one-time sync that runs as soon as the device has network.
  ///
  /// Called after every local write. [ExistingWorkPolicy.replace] ensures that
  /// rapid successive writes collapse into a single pending task rather than
  /// queuing duplicates.
  static Future<void> scheduleOneTime() async {
    await Workmanager().registerOneOffTask(
      _oneTimeUniqueName,
      _oneTimeUniqueName,
      tag: taskTag,
      constraints: Constraints(networkType: NetworkType.connected),
      // Replace the previous pending task — no duplicate queue build-up.
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 1),
    );
  }

  /// Cancels the pending one-time task.
  ///
  /// Call this after a successful *foreground* sync so the background task
  /// doesn't redo the same work moments later.
  static Future<void> cancelOneTime() async {
    await Workmanager().cancelByUniqueName(_oneTimeUniqueName);
  }

  /// Cancels every Kashly WorkManager task.
  ///
  /// Call this when the user signs out of Google Drive so background tasks
  /// stop running without valid credentials.
  static Future<void> cancelAll() async {
    await Workmanager().cancelByTag(taskTag);
  }
}
