import 'package:flutter/material.dart';

import 'models/app_settings.dart';
import 'models/milk_entry.dart';
import 'models/payment.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'services/formatters.dart';
import 'services/ledger_service.dart';
import 'services/storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MilkTrackerApp());
}

class MilkTrackerApp extends StatefulWidget {
  const MilkTrackerApp({super.key});

  @override
  State<MilkTrackerApp> createState() => _MilkTrackerAppState();
}

class _MilkTrackerAppState extends State<MilkTrackerApp> {
  final StorageService _storage = StorageService();

  List<MilkEntry> _milkEntries = [];
  List<Payment> _payments = [];
  AppSettings _settings = const AppSettings.defaults();

  bool _loading = true;
  Object? _loadError;
  int _idCounter = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }

    try {
      final data = await _storage.load();

      if (!mounted) return;

      setState(() {
        _milkEntries = data.milkEntries;
        _payments = data.payments;
        _settings = data.settings;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  Future<void> _persist() {
    return _storage.saveAll(
      milkEntries: _milkEntries,
      payments: _payments,
      settings: _settings,
    );
  }

  String _newId(String prefix) {
    _idCounter += 1;
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_idCounter';
  }

  List<MilkEntry> get _unpaidEntries => LedgerService.unpaidEntries(
        milkEntries: _milkEntries,
        payments: _payments,
      );

  int get _unpaidOre => LedgerService.unpaidOre(
        milkEntries: _milkEntries,
        payments: _payments,
      );

  int get _unpaidMl => LedgerService.unpaidMl(
        milkEntries: _milkEntries,
        payments: _payments,
      );

  Future<void> _requestAddMilk(BuildContext context, int amountMl) async {
    if (amountMl <= 0) return;

    final costOre = calculateCostOre(
      amountMl: amountMl,
      priceOrePerLiter: _settings.milkPriceOrePerLiter,
    );

    // Fast path for normal farm use: add immediately, then offer a reliable
    // undo action. Persistence completes before the Snackbar is shown.
    final entry = MilkEntry(
      id: _newId('milk'),
      dateTime: DateTime.now(),
      amountMl: amountMl,
      costOre: costOre,
    );

    setState(() {
      _milkEntries = [..._milkEntries, entry];
    });
    await _persist();

    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 7),
        content: Text(
          '${formatLiters(entry.amountMl)} added — ${formatSek(entry.costOre)}',
        ),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            final undone = await _undoMilkEntry(entry.id);
            if (!context.mounted || undone) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Cannot undo this entry because it has already been included in a recorded payment.',
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<bool> _undoMilkEntry(String id) async {
    final exists = _milkEntries.any((entry) => entry.id == id);
    if (!exists) return false;

    final hasBeenPaid = _payments.any(
      (payment) => payment.clearedEntryIds.contains(id),
    );
    if (hasBeenPaid) return false;

    setState(() {
      _milkEntries =
          _milkEntries.where((entry) => entry.id != id).toList();
    });
    await _persist();
    return true;
  }

  Future<void> _requestRecordPayment(BuildContext context) async {
    final amount = _unpaidOre;
    final entriesToClear = _unpaidEntries;

    if (amount < _settings.paymentThresholdOre || entriesToClear.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('Record payment of ${formatSek(amount)}?'),
            content: const Text(
              'This will mark the current milk balance as paid.\n'
              'Your milk history will be kept.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Record payment'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final payment = Payment(
      id: _newId('payment'),
      dateTime: DateTime.now(),
      amountOre: amount,
      clearedEntryIds: entriesToClear.map((entry) => entry.id).toList(),
    );

    setState(() {
      _payments = [..._payments, payment];
    });
    await _persist();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment recorded: ${formatSek(amount)}'),
      ),
    );
  }

  Future<bool> _requestDeleteMilkEntry(
    BuildContext context,
    MilkEntry entry,
  ) async {
    final hasBeenPaid = _payments.any(
      (payment) => payment.clearedEntryIds.contains(entry.id),
    );

    if (hasBeenPaid) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Paid entry cannot be deleted'),
          content: Text(
            '${formatDateTime(entry.dateTime)}\n'
            '${formatLiters(entry.amountMl)} · ${formatSek(entry.costOre)}\n\n'
            'This entry is part of a recorded payment. Keeping it prevents the payment history from becoming inconsistent.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete milk entry?'),
            content: Text(
              '${formatDateTime(entry.dateTime)}\n'
              '${formatLiters(entry.amountMl)} · ${formatSek(entry.costOre)}\n\n'
              'This permanently removes the entry and changes the current unpaid balance.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete permanently'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return false;

    setState(() {
      _milkEntries =
          _milkEntries.where((item) => item.id != entry.id).toList();
    });
    await _persist();
    return true;
  }

  Future<void> _saveSettings(AppSettings settings) async {
    setState(() {
      _settings = settings;
    });
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Milk Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: _loading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : _loadError != null
              ? Scaffold(
                  appBar: AppBar(title: const Text('Milk Tracker')),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'Saved data could not be loaded safely.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'The app has not replaced your stored ledger. '
                            'Try loading again before making any changes.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Builder(
              builder: (homeContext) => HomeScreen(
                settings: _settings,
                unpaidMl: _unpaidMl,
                unpaidOre: _unpaidOre,
                onAddMilk: (amountMl) =>
                    _requestAddMilk(homeContext, amountMl),
                onRecordPayment: () =>
                    _requestRecordPayment(homeContext),
                onOpenHistory: () async {
                  await Navigator.push(
                    homeContext,
                    MaterialPageRoute(
                      builder: (historyContext) => HistoryScreen(
                        milkEntries: _milkEntries,
                        payments: _payments,
                        onDeleteMilkEntry: (entry) =>
                            _requestDeleteMilkEntry(historyContext, entry),
                      ),
                    ),
                  );
                  if (mounted) setState(() {});
                },
                onOpenSettings: () async {
                  await Navigator.push(
                    homeContext,
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(
                        settings: _settings,
                        onSave: _saveSettings,
                      ),
                    ),
                  );
                  if (mounted) setState(() {});
                },
              ),
            ),
    );
  }
}
