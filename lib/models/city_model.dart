class City {
  final int? id;
  final String cityName;
  final String country;
  final bool hasAgent;
  final double doorToDoorPrice;
  final double priceKg;
  final double minimumPrice;
  final double boxPrice;

  City({
    this.id,
    required this.cityName,
    required this.country,
    required this.hasAgent,
    required this.doorToDoorPrice,
    required this.priceKg,
    required this.minimumPrice,
    required this.boxPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cityName': cityName,
      'country': country,
      'hasAgent': hasAgent ? 1 : 0,
      'doorToDoorPrice': doorToDoorPrice,
      'priceKg': priceKg,
      'minimumPrice': minimumPrice,
      'boxPrice': boxPrice,
    };
  }

  factory City.fromMap(Map<String, dynamic> map) {
    return City(
      id: map['id'],
      cityName: map['cityName'],
      country: map['country'],
      hasAgent: map['hasAgent'] == 1,
      doorToDoorPrice: map['doorToDoorPrice'],
      priceKg: map['priceKg'],
      minimumPrice: map['minimumPrice'],
      boxPrice: map['boxPrice'],
    );
  }
}
