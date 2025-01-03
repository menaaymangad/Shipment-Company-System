class Currency {
  final int? id;
  final String currencyName;
  final double currencyAgainst1IraqiDinar;

  Currency({
    this.id,
    required this.currencyName,
    required this.currencyAgainst1IraqiDinar,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'currencyName': currencyName,
      'currencyAgainst1IraqiDinar': currencyAgainst1IraqiDinar,
    };
  }

  factory Currency.fromMap(Map<String, dynamic> map) {
    return Currency(
      id: map['id'],
      currencyName: map['currencyName'],
      currencyAgainst1IraqiDinar: map['currencyAgainst1IraqiDinar'],
    );
  }
}
