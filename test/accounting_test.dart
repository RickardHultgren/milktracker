import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/models/app_settings.dart';
import 'package:milk_tracker/models/milk_entry.dart';
import 'package:milk_tracker/models/payment.dart';
import 'package:milk_tracker/services/formatters.dart';
import 'package:milk_tracker/services/ledger_service.dart';

void main() {
  const settings = AppSettings.defaults();

  test('default business settings are exact integers', () {
    expect(settings.canCapacityMl, 3000);
    expect(settings.milkPriceOrePerLiter, 700);
    expect(settings.paymentThresholdOre, 50000);
    expect((settings.canCapacityMl + 1) ~/ 2, 1500);
  });

  test('half and full can costs are exact', () {
    expect(
      calculateCostOre(amountMl: 1500, priceOrePerLiter: 700),
      1050,
    );
    expect(
      calculateCostOre(amountMl: 3000, priceOrePerLiter: 700),
      2100,
    );
  });

  test('decimal input converts directly to integer units', () {
    expect(parseDecimalToScaledInt('1.5', 3), 1500);
    expect(parseDecimalToScaledInt('1,500', 3), 1500);
    expect(parseDecimalToScaledInt('7.00', 2), 700);
    expect(parseDecimalToScaledInt('500', 2), 50000);
    expect(parseDecimalToScaledInt('1.2345', 3), isNull);
    expect(parseDecimalToScaledInt('7.001', 2), isNull);
  });

  test('504 SEK unpaid records a 504 SEK payment, not 500 SEK', () {
    final entries = [
      MilkEntry(
        id: 'a',
        dateTime: DateTime(2026, 10, 1),
        amountMl: 72000,
        costOre: 50400,
      ),
    ];

    final unpaid = LedgerService.unpaidOre(
      milkEntries: entries,
      payments: const [],
    );

    expect(unpaid, 50400);
    expect(unpaid >= settings.paymentThresholdOre, isTrue);

    final payment = Payment(
      id: 'p1',
      dateTime: DateTime(2026, 10, 2),
      amountOre: unpaid,
      clearedEntryIds: entries.map((e) => e.id).toList(),
    );

    expect(payment.amountOre, 50400);
    expect(
      LedgerService.unpaidOre(
        milkEntries: entries,
        payments: [payment],
      ),
      0,
    );
    expect(entries.single.costOre, 50400);
  });

  test('payment clears only entries that existed when payment was recorded', () {
    final beforePayment = MilkEntry(
      id: 'old',
      dateTime: DateTime(2026, 10, 1),
      amountMl: 72000,
      costOre: 50400,
    );
    final payment = Payment(
      id: 'p1',
      dateTime: DateTime(2026, 10, 2),
      amountOre: 50400,
      clearedEntryIds: const ['old'],
    );
    final afterPayment = MilkEntry(
      id: 'new',
      dateTime: DateTime(2026, 10, 3),
      amountMl: 3000,
      costOre: 2100,
    );

    expect(
      LedgerService.unpaidOre(
        milkEntries: [beforePayment, afterPayment],
        payments: [payment],
      ),
      2100,
    );
    expect(
      LedgerService.unpaidMl(
        milkEntries: [beforePayment, afterPayment],
        payments: [payment],
      ),
      3000,
    );
  });

  test('old entry cost does not change when current price changes', () {
    final oldEntry = MilkEntry(
      id: 'old',
      dateTime: DateTime(2026, 10, 1),
      amountMl: 3000,
      costOre: 2100,
    );
    const newPriceOrePerLiter = 900;

    expect(oldEntry.costOre, 2100);
    expect(
      calculateCostOre(
        amountMl: oldEntry.amountMl,
        priceOrePerLiter: newPriceOrePerLiter,
      ),
      2700,
    );
    expect(oldEntry.costOre, 2100);
  });
}
