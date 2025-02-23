class City {
  final int? id;
  final String cityName;
  final String country;
  final bool hasAgent;
  final bool isPost; // New field
  final double doorToDoorPrice;
  final double priceKg;
  final double minimumPrice;
  final double boxPrice;
  final String circularFlag;
  final String squareFlag;
    final double maxWeightKG;
  City({
    this.id,
    required this.cityName,
    required this.country,
    required this.hasAgent,
    required this.isPost, // New field
    required this.doorToDoorPrice,
    required this.priceKg,
    required this.minimumPrice,
    required this.boxPrice,
    required this.circularFlag,
    required this.squareFlag,
    required this.maxWeightKG,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cityName': cityName,
      'country': country,
      'hasAgent': hasAgent ? 1 : 0,
      'isPost': isPost ? 1 : 0, // New field
      'doorToDoorPrice': doorToDoorPrice,
      'priceKg': priceKg,
      'minimumPrice': minimumPrice,
      'boxPrice': boxPrice, 'circular_flag': circularFlag,
      'square_flag': squareFlag, 'maxWeightKG': maxWeightKG,
    };
  }

  factory City.fromMap(Map<String, dynamic> map) {
    return City(
      id: map['id'],
      cityName: map['cityName'],
      country: map['country'],
      hasAgent: map['hasAgent'] == 1,
      isPost: map['isPost'] == 1, // New field
      doorToDoorPrice: map['doorToDoorPrice'],
      priceKg: map['priceKg'],
      minimumPrice: map['minimumPrice'],
      boxPrice: map['boxPrice'], circularFlag: map['circular_flag'] ?? '',
      squareFlag: map['square_flag'] ?? '', maxWeightKG: map['maxWeightKG'],
    );
  }
}
