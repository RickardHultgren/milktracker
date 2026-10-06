import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/formatters.dart';

class HomeScreen extends StatelessWidget {
  final AppSettings settings;
  final int unpaidMl;
  final int unpaidOre;
  final Future<void> Function(int amountMl) onAddMilk;
  final Future<void> Function() onRecordPayment;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenSettings;

  const HomeScreen({
    super.key,
    required this.settings,
    required this.unpaidMl,
    required this.unpaidOre,
    required this.onAddMilk,
    required this.onRecordPayment,
    required this.onOpenHistory,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final threshold = settings.paymentThresholdOre;
    final timeToPay = unpaidOre >= threshold;
    final remaining = threshold > unpaidOre ? threshold - unpaidOre : 0;
    final progress = threshold <= 0
        ? 1.0
        : (unpaidOre / threshold).clamp(0.0, 1.0).toDouble();

    final halfCanMl = (settings.canCapacityMl + 1) ~/ 2;
    final fullCanMl = settings.canCapacityMl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Milk'),
        actions: [
          IconButton(
            tooltip: 'History',
            onPressed: onOpenHistory,
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            _BalanceCard(
              unpaidOre: unpaidOre,
              unpaidMl: unpaidMl,
              remainingOre: remaining,
              progress: progress,
              timeToPay: timeToPay,
            ),
            const SizedBox(height: 18),
            Text(
              'ADD MILK',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: 8),
            _QuickMilkButton(
              label: 'HALF CAN',
              amountText: formatLiters(halfCanMl),
              costText: formatSek(_cost(halfCanMl)),
              onPressed: () => onAddMilk(halfCanMl),
            ),
            const SizedBox(height: 12),
            _QuickMilkButton(
              label: 'FULL CAN',
              amountText: formatLiters(fullCanMl),
              costText: formatSek(_cost(fullCanMl)),
              onPressed: () => onAddMilk(fullCanMl),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showCustomAmountDialog(context),
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: const Text('Other amount'),
            ),
            const SizedBox(height: 10),
            if (timeToPay)
              FilledButton.icon(
                onPressed: onRecordPayment,
                icon: const Icon(Icons.payments_outlined),
                label: Text('Pay ${formatSek(unpaidOre)}'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              Text(
                'Payment at ${formatSek(threshold)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  int _cost(int amountMl) {
    return calculateCostOre(
      amountMl: amountMl,
      priceOrePerLiter: settings.milkPriceOrePerLiter,
    );
  }

  Future<void> _showCustomAmountDialog(BuildContext context) async {
    final controller = TextEditingController();

    final amountMl = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Other amount'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Liters',
              hintText: 'e.g. 2.25',
              suffixText: 'L',
              helperText: 'Up to 3 decimal places',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final valueMl = parseDecimalToScaledInt(controller.text, 3);
                if (valueMl == null || valueMl <= 0 || valueMl > 1000000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter a valid amount above 0 L with at most 3 decimals.',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, valueMl);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (amountMl == null || !context.mounted) return;
    await onAddMilk(amountMl);
  }
}

class _BalanceCard extends StatelessWidget {
  final int unpaidOre;
  final int unpaidMl;
  final int remainingOre;
  final double progress;
  final bool timeToPay;

  const _BalanceCard({
    required this.unpaidOre,
    required this.unpaidMl,
    required this.remainingOre,
    required this.progress,
    required this.timeToPay,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              timeToPay ? 'TIME TO PAY' : 'OWED',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatSek(unpaidOre),
                maxLines: 1,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${formatLiters(unpaidMl)} unpaid',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Text(
                  timeToPay
                      ? 'Pay now'
                      : '${formatSek(remainingOre)} left',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickMilkButton extends StatelessWidget {
  final String label;
  final String amountText;
  final String costText;
  final VoidCallback onPressed;

  const _QuickMilkButton({
    required this.label,
    required this.amountText,
    required this.costText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(128),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            amountText,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            costText,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
