import 'dart:convert';

/// Result returned by [BackupSerializer.validate].
class ValidationResult {
  final bool isValid;
  final String message;
  const ValidationResult(this.isValid, this.message);
}

class BackupSerializer {
  // ── Schema contract ────────────────────────────────────────────────────────
  static const int currentSchemaVersion = 3;
  static const String appVersion = '2.0.4';

  // Tables that MUST be present for a backup to be considered valid.
  static const List<String> _requiredTables = ['cashbooks', 'entries'];

  // All tables we know about – used for a looser "known tables" check.
  static const List<String> _knownTables = [
    'cashbooks',
    'entries',
    'custom_fields',
    'field_options',
    'edit_logs',
  ];

  // ── Encode ─────────────────────────────────────────────────────────────────

  /// Wraps raw table data in a versioned metadata envelope and encodes to JSON.
  static String encode(Map<String, List<Map<String, dynamic>>> data) {
    final now = DateTime.now();
    final payload = <String, dynamic>{
      'schemaVersion': currentSchemaVersion,
      'appVersion': appVersion,
      'generatedAt': now.toIso8601String(),
      'lastExported': now.millisecondsSinceEpoch,
      // Embed a simple integrity hint: total record counts per table.
      'recordCounts': {
        for (final e in data.entries) e.key: e.value.length,
      },
      ...data,
    };
    return jsonEncode(payload);
  }

  // ── Decode ─────────────────────────────────────────────────────────────────

  /// Decodes a JSON string. Returns null on any parse failure.
  static Map<String, dynamic>? decode(String jsonString) {
    if (jsonString.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) return null;
      return decoded;
    } catch (_) {
      return null;
    }
  }

  // ── Validate ───────────────────────────────────────────────────────────────

  /// Full structural and semantic validation of a decoded backup map.
  ///
  /// Call this before applying any merge or restore to the local database.
  static ValidationResult validate(Map<String, dynamic> data) {
    // 1. schemaVersion must exist and be an integer.
    final schemaVersion = data['schemaVersion'];
    if (schemaVersion == null) {
      return const ValidationResult(
        false,
        'Backup is missing the required "schemaVersion" field. '
        'This file may be corrupted or from an unsupported source.',
      );
    }
    if (schemaVersion is! int) {
      return const ValidationResult(
        false,
        '"schemaVersion" must be an integer.',
      );
    }

    // 2. Future schema → user must update the app.
    if (schemaVersion > currentSchemaVersion) {
      return ValidationResult(
        false,
        'This backup was created with a newer version of Kashly '
        '(schema v$schemaVersion). '
        'Please update the app before restoring.',
      );
    }

    // 3. All required tables must be present and be JSON arrays.
    for (final table in _requiredTables) {
      if (!data.containsKey(table)) {
        return ValidationResult(
          false,
          'Backup is missing required table "$table". The file may be incomplete.',
        );
      }
      if (data[table] is! List) {
        return ValidationResult(
          false,
          'Table "$table" has an unexpected format. Expected a JSON array.',
        );
      }
    }

    // 4. Any table that IS present must be a List.
    for (final table in _knownTables) {
      if (data.containsKey(table) && data[table] is! List) {
        return ValidationResult(
          false,
          'Table "$table" has an unexpected format (not a JSON array).',
        );
      }
    }

    // 5. Integrity hint: verify record counts when the field is present.
    final recordCounts = data['recordCounts'];
    if (recordCounts is Map) {
      for (final entry in recordCounts.entries) {
        final table = entry.key as String;
        final expected = entry.value as int? ?? -1;
        final tableData = data[table];
        if (tableData is List && tableData.length != expected) {
          return ValidationResult(
            false,
            'Record count mismatch for "$table": '
            'expected $expected but found ${tableData.length}. '
            'The backup file may be truncated.',
          );
        }
      }
    }

    // 6. Spot-check that every cashbook record has a non-null "id".
    final cashbooks = data['cashbooks'] as List;
    for (int i = 0; i < cashbooks.length; i++) {
      final record = cashbooks[i];
      if (record is! Map || record['id'] == null) {
        return ValidationResult(
          false,
          'Cashbook record at index $i is missing a required "id" field.',
        );
      }
    }

    return const ValidationResult(true, 'Backup is valid.');
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Extracts the human-readable appVersion string from a decoded backup,
  /// falling back to 'unknown' if the field is absent (older backups).
  static String extractAppVersion(Map<String, dynamic> data) {
    return (data['appVersion'] as String?) ?? 'unknown';
  }

  /// Extracts the generatedAt ISO string from a decoded backup.
  static String? extractGeneratedAt(Map<String, dynamic> data) {
    return data['generatedAt'] as String?;
  }
}
