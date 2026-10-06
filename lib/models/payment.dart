class Payment {
  final String id;
  final DateTime dateTime;
  final int amountOre;
  final List<String> clearedEntryIds;

  const Payment({
    required this.id,
    required this.dateTime,
    required this.amountOre,
    required this.clearedEntryIds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateTime': dateTime.toUtc().toIso8601String(),
        'amountOre': amountOre,
        'clearedEntryIds': clearedEntryIds,
      };

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String).toUtc(),
      amountOre: json['amountOre'] as int,
      clearedEntryIds:
          (json['clearedEntryIds'] as List<dynamic>).cast<String>(),
    );
  }
}
