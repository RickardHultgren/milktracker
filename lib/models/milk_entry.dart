class MilkEntry {
  final String id;
  final DateTime dateTime;
  final int amountMl;
  final int costOre;

  const MilkEntry({
    required this.id,
    required this.dateTime,
    required this.amountMl,
    required this.costOre,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateTime': dateTime.toUtc().toIso8601String(),
        'amountMl': amountMl,
        'costOre': costOre,
      };

  factory MilkEntry.fromJson(Map<String, dynamic> json) {
    return MilkEntry(
      id: json['id'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String).toUtc(),
      amountMl: json['amountMl'] as int,
      costOre: json['costOre'] as int,
    );
  }
}
