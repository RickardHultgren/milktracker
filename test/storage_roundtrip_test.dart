import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/models/app_settings.dart';
import 'package:milk_tracker/models/milk_entry.dart';
import 'package:milk_tracker/models/payment.dart';
import 'package:milk_tracker/services/ledger_service.dart';
import 'package:milk_tracker/services/storage_service.dart';

void main() {
  group('StoredData serialization and restart reconstruction', () {
    test('Case A: three milk entries survive encode/decode', () {
      final state = StoredData(
        milkEntries: [
          MilkEntry(
            id: 'milk-1',
            dateTime: DateTime(2026, 10, 1, 8),
            amountMl: 3000,
            costOre: 2100,
          ),
          MilkEntry(
            id: 'milk-2',
            dateTime: DateTime(2026, 10, 2, 8),
            amountMl: 1500,
            costOre: 1050,
          ),
          MilkEntry(
            id: 'milk-3',
            dateTime: DateTime(2026, 10, 3, 8),
            amountMl: 3000,
            costOre: 2100,
          ),
        ],
        payments: const [],
        settings: const AppSettings.defaults(),
      );

      final restored = StoredData.decode(state.encode());

      expect(restored.milkEntries.length, 3);
      expect(LedgerService.unpaidMl(
        milkEntries: restored.milkEntries,
        payments: restored.payments,
      ), 7500);
      expect(LedgerService.unpaidOre(
        milkEntries: restored.milkEntries,
        payments: restored.payments,
      ), 5250);
      expect(restored.settings.milkPriceOrePerLiter, 700);
      expect(restored.settings.canCapacityMl, 3000);
      expect(restored.settings.paymentThresholdOre, 50000);
    });

    test('Case B: payment survives restart and clears current balance', () {
      final entries = List.generate(
        24,
        (index) => MilkEntry(
          id: 'milk-$index',
          dateTime: DateTime(2026, 9, 1).add(Duration(days: index)),
          amountMl: 3000,
          costOre: 2100,
        ),
      );

      // 24 full cans = 50,400 öre.
      final payment = Payment(
        id: 'payment-1',
        dateTime: DateTime(2026, 9, 25),
        amountOre: 50400,
        clearedEntryIds: entries.map((entry) => entry.id).toList(),
      );

      final restored = StoredData.decode(
        StoredData(
          milkEntries: entries,
          payments: [payment],
          settings: const AppSettings.defaults(),
        ).encode(),
      );

      expect(restored.milkEntries.length, 24);
      expect(restored.payments.length, 1);
      expect(restored.payments.single.amountOre, 50400);
      expect(LedgerService.unpaidOre(
        milkEntries: restored.milkEntries,
        payments: restored.payments,
      ), 0);
      expect(LedgerService.unpaidMl(
        milkEntries: restored.milkEntries,
        payments: restored.payments,
      ), 0);
    });

    test('Case C: only post-payment milk is unpaid after restart', () {
      final oldEntry = MilkEntry(
        id: 'old-milk',
        dateTime: DateTime(2026, 9, 1),
        amountMl: 3000,
        costOre: 2100,
      );
      final payment = Payment(
        id: 'payment-1',
        dateTime: DateTime(2026, 9, 2),
        amountOre: 2100,
        clearedEntryIds: const ['old-milk'],
      );
      final newEntry = MilkEntry(
        id: 'new-milk',
        dateTime: DateTime(2026, 9, 3),
        amountMl: 1500,
        costOre: 1050,
      );

      final restored = StoredData.decode(
        StoredData(
          milkEntries: [oldEntry, newEntry],
          payments: [payment],
          settings: const AppSettings.defaults(),
        ).encode(),
      );

      final unpaid = LedgerService.unpaidEntries(
        milkEntries: restored.milkEntries,
        payments: restored.payments,
      );

      expect(unpaid.map((entry) => entry.id).toList(), ['new-milk']);
      expect(LedgerService.unpaidOre(
        milkEntries: restored.milkEntries,
        payments: restored.payments,
      ), 1050);
      expect(LedgerService.unpaidMl(
        milkEntries: restored.milkEntries,
        payments: restored.payments,
      ), 1500);
    });

    test('settings survive serialization with non-default values', () {
      const settings = AppSettings(
        canCapacityMl: 2500,
        milkPriceOrePerLiter: 825,
        paymentThresholdOre: 62000,
      );

      final restored = StoredData.decode(
        const StoredData(
          milkEntries: [],
          payments: [],
          settings: settings,
        ).encode(),
      );

      expect(restored.settings.canCapacityMl, 2500);
      expect(restored.settings.milkPriceOrePerLiter, 825);
      expect(restored.settings.paymentThresholdOre, 62000);
    });

    test('malformed complete state is rejected rather than partially restored', () {
      expect(
        () => StoredData.decode(
          '{"schemaVersion":1,"milkEntries":"broken","payments":[],"settings":{}}',
        ),
        throwsFormatException,
      );
    });
  });
}
