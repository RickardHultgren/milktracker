class AppSettings {
  final int canCapacityMl;
  final int milkPriceOrePerLiter;
  final int paymentThresholdOre;

  const AppSettings({
    required this.canCapacityMl,
    required this.milkPriceOrePerLiter,
    required this.paymentThresholdOre,
  });

  const AppSettings.defaults()
      : canCapacityMl = 3000,
        milkPriceOrePerLiter = 700,
        paymentThresholdOre = 50000;

  AppSettings copyWith({
    int? canCapacityMl,
    int? milkPriceOrePerLiter,
    int? paymentThresholdOre,
  }) {
    return AppSettings(
      canCapacityMl: canCapacityMl ?? this.canCapacityMl,
      milkPriceOrePerLiter:
          milkPriceOrePerLiter ?? this.milkPriceOrePerLiter,
      paymentThresholdOre:
          paymentThresholdOre ?? this.paymentThresholdOre,
    );
  }

  Map<String, dynamic> toJson() => {
        'canCapacityMl': canCapacityMl,
        'milkPriceOrePerLiter': milkPriceOrePerLiter,
        'paymentThresholdOre': paymentThresholdOre,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      canCapacityMl: json['canCapacityMl'] as int? ?? 3000,
      milkPriceOrePerLiter:
          json['milkPriceOrePerLiter'] as int? ?? 700,
      paymentThresholdOre:
          json['paymentThresholdOre'] as int? ?? 50000,
    );
  }
}
