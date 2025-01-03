class Branch {
  final int? id;
  final String branchName;
  final String contactPersonName;
  final String branchCompany;
  final String phoneNo1;
  final String phoneNo2;
  final String address;
  final String city;
  final String charactersPrefix;
  final String yearPrefix;
  final int numberOfDigits;
  final String codeStyle;
  final String invoiceLanguage;

  Branch({
    this.id,
    required this.branchName,
    required this.contactPersonName,
    required this.branchCompany,
    required this.phoneNo1,
    required this.phoneNo2,
    required this.address,
    required this.city,
    required this.charactersPrefix,
    required this.yearPrefix,
    required this.numberOfDigits,
    required this.codeStyle,
    required this.invoiceLanguage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'branchName': branchName,
      'contactPersonName': contactPersonName,
      'branchCompany': branchCompany,
      'phoneNo1': phoneNo1,
      'phoneNo2': phoneNo2,
      'address': address,
      'city': city,
      'charactersPrefix': charactersPrefix,
      'yearPrefix': yearPrefix,
      'numberOfDigits': numberOfDigits,
      'codeStyle': codeStyle,
      'invoiceLanguage': invoiceLanguage,
    };
  }

  factory Branch.fromMap(Map<String, dynamic> map) {
    return Branch(
      id: map['id'],
      branchName: map['branchName'],
      contactPersonName: map['contactPersonName'],
      branchCompany: map['branchCompany'],
      phoneNo1: map['phoneNo1'],
      phoneNo2: map['phoneNo2'],
      address: map['address'],
      city: map['city'],
      charactersPrefix: map['charactersPrefix'],
      yearPrefix: map['yearPrefix'],
      numberOfDigits: map['numberOfDigits'],
      codeStyle: map['codeStyle'],
      invoiceLanguage: map['invoiceLanguage'],
    );
  }
}
