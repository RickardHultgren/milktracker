import '../models/milk_entry.dart';
import '../models/payment.dart';

class LedgerService {
  static Set<String> clearedEntryIds(List<Payment> payments) {
    return payments.expand((p) => p.clearedEntryIds).toSet();
  }

  static List<MilkEntry> unpaidEntries({
    required List<MilkEntry> milkEntries,
    required List<Payment> payments,
  }) {
    final cleared = clearedEntryIds(payments);
    return milkEntries.where((entry) => !cleared.contains(entry.id)).toList();
  }

  static int unpaidOre({
    required List<MilkEntry> milkEntries,
    required List<Payment> payments,
  }) {
    return unpaidEntries(
      milkEntries: milkEntries,
      payments: payments,
    ).fold(0, (sum, entry) => sum + entry.costOre);
  }

  static int unpaidMl({
    required List<MilkEntry> milkEntries,
    required List<Payment> payments,
  }) {
    return unpaidEntries(
      milkEntries: milkEntries,
      payments: payments,
    ).fold(0, (sum, entry) => sum + entry.amountMl);
  }

  static int totalMilkMl(List<MilkEntry> milkEntries) {
    return milkEntries.fold(0, (sum, entry) => sum + entry.amountMl);
  }

  static int totalMilkCostOre(List<MilkEntry> milkEntries) {
    return milkEntries.fold(0, (sum, entry) => sum + entry.costOre);
  }

  static int totalPaymentsOre(List<Payment> payments) {
    return payments.fold(0, (sum, payment) => sum + payment.amountOre);
  }
}
