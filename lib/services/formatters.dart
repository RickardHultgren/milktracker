String formatSek(int ore) {
  final negative = ore < 0;
  final absolute = ore.abs();
  final kronor = absolute ~/ 100;
  final cents = absolute % 100;
  return '${negative ? '-' : ''}$kronor.${cents.toString().padLeft(2, '0')} SEK';
}

String formatLiters(int ml) {
  final negative = ml < 0;
  final absolute = ml.abs();
  final liters = absolute ~/ 1000;
  final remainder = absolute % 1000;

  String fraction;
  if (remainder == 0) {
    fraction = '0';
  } else {
    fraction = remainder.toString().padLeft(3, '0');
    while (fraction.endsWith('0')) {
      fraction = fraction.substring(0, fraction.length - 1);
    }
  }

  return '${negative ? '-' : ''}$liters.$fraction L';
}

String formatMlForInput(int ml) => _formatScaledInteger(ml, 3, minDecimals: 1);

String formatOreForInput(int ore) => _formatScaledInteger(ore, 2, minDecimals: 2);

String _formatScaledInteger(
  int value,
  int decimalPlaces, {
  int minDecimals = 0,
}) {
  final negative = value < 0;
  final absolute = value.abs();
  final scale = _pow10(decimalPlaces);
  final whole = absolute ~/ scale;
  var fraction = (absolute % scale).toString().padLeft(decimalPlaces, '0');

  while (fraction.length > minDecimals && fraction.endsWith('0')) {
    fraction = fraction.substring(0, fraction.length - 1);
  }

  final prefix = negative ? '-' : '';
  return fraction.isEmpty ? '$prefix$whole' : '$prefix$whole.$fraction';
}

String formatDate(DateTime dateTime) {
  dateTime = dateTime.toLocal();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
}

String formatDateTime(DateTime dateTime) {
  dateTime = dateTime.toLocal();
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '${formatDate(dateTime)} · $hour:$minute';
}

/// Parses a non-negative decimal string directly into an integer scaled by
/// [decimalPlaces], without passing through binary floating point.
///
/// Examples:
///   parseDecimalToScaledInt('1.5', 3) == 1500
///   parseDecimalToScaledInt('7.00', 2) == 700
///   parseDecimalToScaledInt('500', 2) == 50000
///
/// Values with more fractional digits than can be represented exactly are
/// rejected rather than silently rounded.
int? parseDecimalToScaledInt(String input, int decimalPlaces) {
  var normalized = input.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;

  var negative = false;
  if (normalized.startsWith('-')) {
    negative = true;
    normalized = normalized.substring(1);
  } else if (normalized.startsWith('+')) {
    normalized = normalized.substring(1);
  }

  if (normalized.isEmpty) return null;

  final parts = normalized.split('.');
  if (parts.length > 2) return null;

  final wholePart = parts[0].isEmpty ? '0' : parts[0];
  final fractionPart = parts.length == 2 ? parts[1] : '';

  if (!_digitsOnly(wholePart) || !_digitsOnly(fractionPart)) return null;
  if (fractionPart.length > decimalPlaces) return null;

  final whole = int.tryParse(wholePart);
  if (whole == null) return null;

  final scale = _pow10(decimalPlaces);
  final paddedFraction = fractionPart.padRight(decimalPlaces, '0');
  final fraction = paddedFraction.isEmpty ? 0 : int.parse(paddedFraction);

  final scaled = whole * scale + fraction;
  return negative ? -scaled : scaled;
}

bool _digitsOnly(String value) {
  if (value.isEmpty) return true;
  for (final codeUnit in value.codeUnits) {
    if (codeUnit < 48 || codeUnit > 57) return false;
  }
  return true;
}

int _pow10(int exponent) {
  var value = 1;
  for (var i = 0; i < exponent; i++) {
    value *= 10;
  }
  return value;
}

int calculateCostOre({
  required int amountMl,
  required int priceOrePerLiter,
}) {
  if (amountMl < 0 || priceOrePerLiter < 0) {
    throw ArgumentError('Milk amount and price must be non-negative.');
  }

  // Exact integer arithmetic. The numerator has units ml·öre/L.
  // Since 1 L = 1000 ml, divide by 1000 and round half-up to the
  // nearest whole öre. No binary floating-point value is created.
  final numerator = amountMl * priceOrePerLiter;
  return (numerator + 500) ~/ 1000;
}
