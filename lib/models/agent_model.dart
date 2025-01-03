class Agent {
  final int? id;
  final String agentName;
  final String countryName;
  final String contactPersonName;
  final String companyName;
  final String cityName;
  final String address;
  final String phoneNo1;
  final String phoneNo2;
  final double priceKG;
  final double minimumPrice;
  final double doorToDoorPrice;

  Agent({
    this.id,
    required this.agentName,
    required this.countryName,
    required this.contactPersonName,
    required this.companyName,
    required this.cityName,
    required this.address,
    required this.phoneNo1,
    required this.phoneNo2,
    required this.priceKG,
    required this.minimumPrice,
    required this.doorToDoorPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'agentName': agentName,
      'countryName': countryName,
      'contactPersonName': contactPersonName,
      'companyName': companyName,
      'cityName': cityName,
      'address': address,
      'phoneNo1': phoneNo1,
      'phoneNo2': phoneNo2,
      'priceKG': priceKG,
      'minimumPrice': minimumPrice,
      'doorToDoorPrice': doorToDoorPrice,
    };
  }

  factory Agent.fromMap(Map<String, dynamic> map) {
    return Agent(
      id: map['id'],
      agentName: map['agentName'],
      countryName: map['countryName'],
      contactPersonName: map['contactPersonName'],
      companyName: map['companyName'],
      cityName: map['cityName'],
      address: map['address'],
      phoneNo1: map['phoneNo1'],
      phoneNo2: map['phoneNo2'],
      priceKG: map['priceKG'],
      minimumPrice: map['minimumPrice'],
      doorToDoorPrice: map['doorToDoorPrice'],
    );
  }
}
