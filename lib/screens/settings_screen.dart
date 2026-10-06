import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/formatters.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettings settings;
  final Future<void> Function(AppSettings settings) onSave;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onSave,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _capacityController;
  late final TextEditingController _priceController;
  late final TextEditingController _thresholdController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _capacityController = TextEditingController(
      text: formatMlForInput(widget.settings.canCapacityMl),
    );
    _priceController = TextEditingController(
      text: formatOreForInput(widget.settings.milkPriceOrePerLiter),
    );
    _thresholdController = TextEditingController(
      text: formatOreForInput(widget.settings.paymentThresholdOre),
    );
  }

  @override
  void dispose() {
    _capacityController.dispose();
    _priceController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _capacityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Can capacity',
              suffixText: 'liters',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Milk price',
              suffixText: 'SEK/liter',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _thresholdController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Payment threshold',
              suffixText: 'SEK',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving…' : 'Save settings'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Changing these values affects future milk entries only. '
            'Existing entries keep their original recorded cost.',
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final capacityMl = parseDecimalToScaledInt(_capacityController.text, 3);
    final priceOre = parseDecimalToScaledInt(_priceController.text, 2);
    final thresholdOre = parseDecimalToScaledInt(_thresholdController.text, 2);

    if (capacityMl == null ||
        capacityMl <= 0 ||
        priceOre == null ||
        priceOre <= 0 ||
        thresholdOre == null ||
        thresholdOre <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Use positive numbers. Capacity allows 3 decimals; money allows 2.',
          ),
        ),
      );
      return;
    }

    final newSettings = AppSettings(
      canCapacityMl: capacityMl,
      milkPriceOrePerLiter: priceOre,
      paymentThresholdOre: thresholdOre,
    );

    setState(() => _saving = true);
    await widget.onSave(newSettings);

    if (!mounted) return;
    Navigator.pop(context);
  }
}
