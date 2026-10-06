import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/milk_entry.dart';
import '../models/payment.dart';

class StoredData {
  static const int currentSchemaVersion = 1;

  final List<MilkEntry> milkEntries;
  final List<Payment> payments;
  final AppSettings settings;

  const StoredData({
    required this.milkEntries,
    required this.payments,
    required this.settings,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': currentSchemaVersion,
        'milkEntries': milkEntries.map((entry) => entry.toJson()).toList(),
        'payments': payments.map((payment) => payment.toJson()).toList(),
        'settings': settings.toJson(),
      };

  String encode() => jsonEncode(toJson());

  factory StoredData.fromJson(Map<String, dynamic> json) {
    final schemaVersion = _readInt(json['schemaVersion']);
    if (schemaVersion != currentSchemaVersion) {
      throw const FormatException('Unsupported storage schema version.');
    }

    final milkRaw = json['milkEntries'];
    final paymentsRaw = json['payments'];
    final settingsRaw = json['settings'];

    if (milkRaw is! List || paymentsRaw is! List || settingsRaw is! Map) {
      throw const FormatException('Invalid stored application state.');
    }

    return StoredData(
      milkEntries: milkRaw
          .map(
            (item) => MilkEntry.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      payments: paymentsRaw
          .map(
            (item) => Payment.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      settings: AppSettings.fromJson(
        Map<String, dynamic>.from(settingsRaw),
      ),
    );
  }

  factory StoredData.decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Stored application state is not an object.');
    }
    return StoredData.fromJson(Map<String, dynamic>.from(decoded));
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    throw const FormatException('Expected integer value.');
  }
}

class StorageService {
  // Current format: the complete ledger and settings are persisted together.
  static const _stateKey = 'app_state_v1';
  static const _backupStateKey = 'app_state_v1_backup';

  // Legacy keys from the first app version. They are read only for migration.
  static const _legacyMilkEntriesKey = 'milk_entries_v1';
  static const _legacyPaymentsKey = 'payments_v1';
  static const _legacySettingsKey = 'settings_v1';

  Future<StoredData> load() async {
    final prefs = await SharedPreferences.getInstance();

    final primaryRaw = prefs.getString(_stateKey);
    final backupRaw = prefs.getString(_backupStateKey);
    final hadSnapshotData = primaryRaw != null || backupRaw != null;
    final hadLegacyData =
        prefs.containsKey(_legacyMilkEntriesKey) ||
        prefs.containsKey(_legacyPaymentsKey) ||
        prefs.containsKey(_legacySettingsKey);

    if (primaryRaw != null) {
      final primary = _tryDecode(primaryRaw);
      if (primary != null) return primary;
    }

    if (backupRaw != null) {
      final backup = _tryDecode(backupRaw);
      if (backup != null) {
        // Repair the primary snapshot from the known-good backup.
        await prefs.setString(_stateKey, backup.encode());
        return backup;
      }
    }

    final legacy = _tryLoadLegacy(prefs);
    if (legacy != null) {
      // Migrate old installations to the single-snapshot format.
      await saveAll(
        milkEntries: legacy.milkEntries,
        payments: legacy.payments,
        settings: legacy.settings,
      );
      return legacy;
    }

    if (hadSnapshotData || hadLegacyData) {
      throw StateError(
        'Stored milk-tracker data exists but could not be decoded or migrated. '
        'The app will not replace it with an empty ledger.',
      );
    }

    return const StoredData(
      milkEntries: <MilkEntry>[],
      payments: <Payment>[],
      settings: AppSettings.defaults(),
    );
  }

  Future<void> saveAll({
    required List<MilkEntry> milkEntries,
    required List<Payment> payments,
    required AppSettings settings,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final nextState = StoredData(
      milkEntries: List<MilkEntry>.unmodifiable(milkEntries),
      payments: List<Payment>.unmodifiable(payments),
      settings: settings,
    );
    final encoded = nextState.encode();

    // Preserve the last valid full snapshot before replacing the primary.
    final currentRaw = prefs.getString(_stateKey);
    if (currentRaw != null && _tryDecode(currentRaw) != null) {
      final backupSaved = await prefs.setString(_backupStateKey, currentRaw);
      if (!backupSaved) {
        throw StateError('Could not save storage backup.');
      }
    }

    final primarySaved = await prefs.setString(_stateKey, encoded);
    if (!primarySaved) {
      throw StateError('Could not save application data.');
    }

    // On the very first save there is no previous snapshot to preserve.
    // Seed the backup with the same known-good state so recovery is still
    // possible if the primary value later becomes unreadable.
    if (currentRaw == null) {
      final backupSaved = await prefs.setString(_backupStateKey, encoded);
      if (!backupSaved) {
        throw StateError('Could not initialize storage backup.');
      }
    }
  }

  StoredData? _tryDecode(String raw) {
    try {
      return StoredData.decode(raw);
    } catch (_) {
      return null;
    }
  }

  StoredData? _tryLoadLegacy(SharedPreferences prefs) {
    final milkRaw = prefs.getString(_legacyMilkEntriesKey);
    final paymentsRaw = prefs.getString(_legacyPaymentsKey);
    final settingsRaw = prefs.getString(_legacySettingsKey);

    // No legacy data means a genuinely new installation.
    if (milkRaw == null && paymentsRaw == null && settingsRaw == null) {
      return null;
    }

    try {
      final milkEntries = milkRaw == null
          ? <MilkEntry>[]
          : _decodeLegacyList(milkRaw, MilkEntry.fromJson);
      final payments = paymentsRaw == null
          ? <Payment>[]
          : _decodeLegacyList(paymentsRaw, Payment.fromJson);
      final settings = settingsRaw == null
          ? const AppSettings.defaults()
          : AppSettings.fromJson(
              Map<String, dynamic>.from(jsonDecode(settingsRaw) as Map),
            );

      return StoredData(
        milkEntries: milkEntries,
        payments: payments,
        settings: settings,
      );
    } catch (_) {
      // Do not silently accept a partially decoded legacy ledger.
      return null;
    }
  }

  List<T> _decodeLegacyList<T>(
    String raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Legacy list is invalid.');
    }

    return decoded
        .map(
          (item) => fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }
}
