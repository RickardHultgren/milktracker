# Final compatibility review

- Flutter null safety: yes; SDK constraint starts at Dart 3.4.
- UI: Material 3 via `ThemeData(useMaterial3: true)`.
- Persistence: `shared_preferences` only; no Firebase, backend, network client, or authentication.
- SharedPreferences is initialized only after `WidgetsFlutterBinding.ensureInitialized()`.
- Ledger state is stored as one versioned JSON snapshot with a backup and legacy migration.
- Current unpaid balance is derived from milk transactions and payment-cleared entry IDs; it is not stored as an authoritative balance.
- Money is integer öre; milk is integer milliliters.
- Dates are serialized as UTC ISO-8601 strings and displayed in the Android device's local timezone.
- No platform-specific Dart APIs are used.
- Only external runtime dependency: `shared_preferences: 2.3.3`.
- `LinearProgressIndicator.borderRadius` was removed to avoid depending on a newer Flutter Material API.

The container used for this review does not include the Flutter/Dart SDK, so a real `flutter analyze` / Android compile could not be run locally. The source was reviewed statically and should be verified once with FlutLab's Analyzer and Android builder.
