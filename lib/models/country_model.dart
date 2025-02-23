class Country {
  final int? id;
  final String countryName;
  final String alpha2Code;
  final String zipCodeDigit1;
  final String zipCodeDigit2;
  final String zipCodeText;
  final String currency;
  final double currencyAgainstIQD;
  final bool hasAgent;



  Country({
    this.id,
    required this.countryName,
    required this.alpha2Code,
    required this.zipCodeDigit1,
    required this.zipCodeDigit2,
    required this.zipCodeText,
    required this.currency,
    required this.currencyAgainstIQD,
    required this.hasAgent,
   

  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'countryName': countryName,
      'alpha2Code': alpha2Code,
      'zipCodeDigit1': zipCodeDigit1,
      'zipCodeDigit2': zipCodeDigit2,
      'zipCodeText': zipCodeText,
      'currency': currency,
      'currencyAgainstIQD': currencyAgainstIQD,
      'hasAgent': hasAgent ? 1 : 0,
     
    
    };
  }

  factory Country.fromMap(Map<String, dynamic> map) {
    return Country(
      id: map['id'],
      countryName: map['countryName'],
      alpha2Code: map['alpha2Code'],
      zipCodeDigit1: map['zipCodeDigit1'],
      zipCodeDigit2: map['zipCodeDigit2'],
      zipCodeText: map['zipCodeText'],
      currency: map['currency'],
      currencyAgainstIQD: map['currencyAgainstIQD'],
      hasAgent: map['hasAgent'] == 1,
     
  
    );
  }
}
