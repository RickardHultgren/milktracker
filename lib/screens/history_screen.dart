import 'package:flutter/material.dart';

import '../models/milk_entry.dart';
import '../models/payment.dart';
import '../services/formatters.dart';
import '../services/ledger_service.dart';

class HistoryScreen extends StatefulWidget {
  final List<MilkEntry> milkEntries;
  final List<Payment> payments;
  final Future<bool> Function(MilkEntry entry) onDeleteMilkEntry;

  const HistoryScreen({
    super.key,
    required this.milkEntries,
    required this.payments,
    required this.onDeleteMilkEntry,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late List<MilkEntry> _milkEntries;

  @override
  void initState() {
    super.initState();
    _milkEntries = List<MilkEntry>.from(widget.milkEntries);
  }

  @override
  Widget build(BuildContext context) {
    final unpaidOre = LedgerService.unpaidOre(
      milkEntries: _milkEntries,
      payments: widget.payments,
    );

    final events = <_HistoryEvent>[
      ..._milkEntries.map(_HistoryEvent.milk),
      ...widget.payments.map(_HistoryEvent.payment),
    ]..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(
            totalMilkMl: LedgerService.totalMilkMl(_milkEntries),
            totalCostOre: LedgerService.totalMilkCostOre(_milkEntries),
            totalPaymentsOre:
                LedgerService.totalPaymentsOre(widget.payments),
            unpaidOre: unpaidOre,
          ),
          const SizedBox(height: 18),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No transactions yet.')),
            )
          else
            ...events.map(
              (event) => event.milkEntry != null
                  ? _MilkTile(
                      entry: event.milkEntry!,
                      onDelete: () => _deleteEntry(event.milkEntry!),
                    )
                  : _PaymentTile(payment: event.payment!),
            ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry(MilkEntry entry) async {
    final deleted = await widget.onDeleteMilkEntry(entry);

    if (!mounted || !deleted) return;

    setState(() {
      _milkEntries.removeWhere((item) => item.id == entry.id);
    });
  }

}

class _SummaryCard extends StatelessWidget {
  final int totalMilkMl;
  final int totalCostOre;
  final int totalPaymentsOre;
  final int unpaidOre;

  const _SummaryCard({
    required this.totalMilkMl,
    required this.totalCostOre,
    required this.totalPaymentsOre,
    required this.unpaidOre,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _row('Total milk', formatLiters(totalMilkMl)),
            _row('Total cost', formatSek(totalCostOre)),
            _row('Total payments', formatSek(totalPaymentsOre)),
            const Divider(),
            _row('Current unpaid', formatSek(unpaidOre), bold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style =
        bold ? const TextStyle(fontWeight: FontWeight.bold) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _MilkTile extends StatelessWidget {
  final MilkEntry entry;
  final VoidCallback onDelete;

  const _MilkTile({
    required this.entry,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.local_drink_outlined),
        ),
        title: Text(
          '${formatLiters(entry.amountMl)} · ${formatSek(entry.costOre)}',
        ),
        subtitle: Text(formatDateTime(entry.dateTime)),
        trailing: IconButton(
          tooltip: 'Delete milk entry',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Payment payment;

  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final noun =
        payment.clearedEntryIds.length == 1 ? 'entry' : 'entries';

    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.payments_outlined),
        ),
        title: Text(
          'PAYMENT · ${formatSek(payment.amountOre)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${formatDateTime(payment.dateTime)}\n'
          'Cleared ${payment.clearedEntryIds.length} milk $noun',
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _HistoryEvent {
  final DateTime dateTime;
  final MilkEntry? milkEntry;
  final Payment? payment;

  const _HistoryEvent._({
    required this.dateTime,
    this.milkEntry,
    this.payment,
  });

  factory _HistoryEvent.milk(MilkEntry entry) {
    return _HistoryEvent._(
      dateTime: entry.dateTime,
      milkEntry: entry,
    );
  }

  factory _HistoryEvent.payment(Payment payment) {
    return _HistoryEvent._(
      dateTime: payment.dateTime,
      payment: payment,
    );
  }
}
