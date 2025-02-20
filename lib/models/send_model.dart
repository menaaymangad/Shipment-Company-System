// send_record_model.dart
import 'package:app/pages/main_pages/send_page/id_type_selector.dart';

class SendRecord {
  // Shipment Details
  int? id;
  String? date;
  String? truckNumber;
  String? codeNumber;

  // Sender Information
  String? senderName;
  String? senderPhone;
  String? senderIdNumber;
  String? goodsDescription;
String?notes;
  // Item Details
  int? boxNumber;
  int? palletNumber;
  double? realWeightKg;
  double? length;
  double? width;
  double? height;
  bool? isDimensionCalculated;
  double? additionalKg;
  double? totalWeightKg;

  // Agent Information
  String? agentName;
  String? branchName;
  // String? agentCode;

  // Receiver Information
  String? receiverName;
  String? receiverPhone;
  String? receiverCountry;
  String? receiverCity;

  // Postal Details
  String? streetName;
  // String? apartmentNumber;
  String? zipCode;
  // String? postalCity;
  // String? postalCountry;

  // Pricing and Costs
  double? doorToDoorPrice;
  double? pricePerKg;
  double? minimumPrice;
  double? insurancePercent;
  double? goodsValue;
  // double? agentCommission;

  // Additional Costs
  double? insuranceAmount;
  double? customsCost;
  
  double? boxPackingCost;
  double? doorToDoorCost;
  double? postSubCost;
  double? discountAmount;
  double? totalPostCost;
  double? totalPostCostPaid;
  double? unpaidAmount;
  double? totalCostEuroCurrency;
  double? unpaidAmountEuro;
IdType? idType;
  SendRecord({
    this.id,
    this.date,
    this.idType,
    this.truckNumber,
    this.codeNumber,
    this.senderName,
    this.senderPhone,
    this.senderIdNumber,
    this.goodsDescription,
    this.boxNumber,
    this.palletNumber,
    this.realWeightKg,
    this.length,
    this.width,
    this.height,
    this.isDimensionCalculated,
    this.additionalKg,
    this.totalWeightKg,
    this.agentName,
    this.branchName,
    // this.agentCode,
    this.receiverName,
    this.receiverPhone,
    this.receiverCountry,
    this.receiverCity,
    this.streetName,
    this.notes,
    this.zipCode,
    // this.postalCity,
    // this.postalCountry,
    this.doorToDoorPrice,
    this.pricePerKg,
    this.minimumPrice,
    this.insurancePercent,
    this.goodsValue,
    // this.agentCommission,
    this.insuranceAmount,
    this.customsCost,
  this.boxPackingCost,
    this.doorToDoorCost,
    this.postSubCost,
    this.discountAmount,
    this.totalPostCost,
    this.totalPostCostPaid,
    this.unpaidAmount,
    this.totalCostEuroCurrency,
    this.unpaidAmountEuro,
  });

 Map<String, dynamic> toMap() {
    // Validate required fields
    if (truckNumber == null || truckNumber!.isEmpty) {
      throw ArgumentError('Truck number is required');
    }
    if (codeNumber == null || codeNumber!.isEmpty) {
      throw ArgumentError('Code number is required');
    }
    if (senderName == null || senderName!.isEmpty) {
      throw ArgumentError('Sender name is required');
    }
    if (receiverName == null || receiverName!.isEmpty) {
      throw ArgumentError('Receiver name is required');
    }

    // Return the map of fields
    return {
      'date': date,
      'truckNumber': truckNumber,
      'codeNumber': codeNumber,
      'senderName': senderName,
      'senderPhone': senderPhone,
      'senderIdNumber': senderIdNumber,
      'goodsDescription': goodsDescription,
      'notes': notes,
      'boxNumber': boxNumber,
      'palletNumber': palletNumber,
      'realWeightKg': realWeightKg,
      'length': length,
      'width': width,
      'height': height,
      'isDimensionCalculated': isDimensionCalculated == true ? 1 : 0,
      'additionalKg': additionalKg,
      'totalWeightKg': totalWeightKg,
      'agentName': agentName,
      'branchName': branchName,
      // 'agentCode': agentCode,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'receiverCountry': receiverCountry,
      'receiverCity': receiverCity,
      'streetName': streetName,
     
      'zipCode': zipCode,
      // 'postalCity': postalCity,
      // 'postalCountry': postalCountry,
      'doorToDoorPrice': doorToDoorPrice,
      'pricePerKg': pricePerKg,
      'minimumPrice': minimumPrice,
      'insurancePercent': insurancePercent,
      'goodsValue': goodsValue,
      // 'agentCommission': agentCommission,
      'insuranceAmount': insuranceAmount,
      'customsCost': customsCost,
    
      'boxPackingCost': boxPackingCost,
      'doorToDoorCost': doorToDoorCost,
      'postSubCost': postSubCost,
      'discountAmount': discountAmount,
      'totalPostCost': totalPostCost,
      'totalPostCostPaid': totalPostCostPaid,
      'unpaidAmount': unpaidAmount,
      'totalCostEuroCurrency': totalCostEuroCurrency,
      'unpaidAmountEuro': unpaidAmountEuro,
    };
  }
  factory SendRecord.fromMap(Map<String, dynamic> map) {
    return SendRecord(
      id: map['id'],
      date: map['date'],
      idType: map['idType'] != null ? IdType.values[map['idType']] : null,
      truckNumber: map['truckNumber'],
      codeNumber: map['codeNumber'],
      senderName: map['senderName'],
      senderPhone: map['senderPhone'],
      senderIdNumber: map['senderIdNumber'],
      goodsDescription: map['goodsDescription'],
      notes: map['notes'],
      boxNumber: map['boxNumber'],
      palletNumber: map['palletNumber'],
      realWeightKg: map['realWeightKg'],
      length: map['length'],
      width: map['width'],
      height: map['height'],
      isDimensionCalculated: map['isDimensionCalculated'] == 1,
      additionalKg: map['additionalKg'],
      totalWeightKg: map['totalWeightKg'],
      agentName: map['agentName'],
      branchName: map['branchName'],
      // agentCode: map['agentCode'],
      receiverName: map['receiverName'],
      receiverPhone: map['receiverPhone'],
      receiverCountry: map['receiverCountry'],
      receiverCity: map['receiverCity'],
      streetName: map['streetName'],
      
      zipCode: map['zipCode'],
      // postalCity: map['postalCity'],
      // postalCountry: map['postalCountry'],
      doorToDoorPrice: map['doorToDoorPrice'],
      pricePerKg: map['pricePerKg'],
      minimumPrice: map['minimumPrice'],
      insurancePercent: map['insurancePercent'],
      goodsValue: map['goodsValue'],
      // agentCommission: map['agentCommission'],
      insuranceAmount: map['insuranceAmount'],
      customsCost: map['customsCost'],
 
      boxPackingCost: map['boxPackingCost'],
      doorToDoorCost: map['doorToDoorCost'],
      postSubCost: map['postSubCost'],
      discountAmount: map['discountAmount'],
      totalPostCost: map['totalPostCost'],
      totalPostCostPaid: map['totalPostCostPaid'],
      unpaidAmount: map['unpaidAmount'],
      totalCostEuroCurrency: map['totalCostEuroCurrency'],
      unpaidAmountEuro: map['unpaidAmountEuro'],
    );
  }
   SendRecord copyWith({
    int? id,
    String? date,
    String? truckNumber,
    String? codeNumber,
    String? senderName,
    String? senderPhone,
    String? senderIdNumber,
    String? goodsDescription,
    String? notes,
    int? boxNumber,
    int? palletNumber,
    double? realWeightKg,
    double? length,
    double? width,
    double? height,
    bool? isDimensionCalculated,
    double? additionalKg,
    double? totalWeightKg,
    String? agentName,
    String? branchName,
    String? agentCode,
    String? receiverName,
    String? receiverPhone,
    String? receiverCountry,
    String? receiverCity,
    String? streetName,
    String? apartmentNumber,
    String? zipCode,
    String? postalCity,
    String? postalCountry,
    double? doorToDoorPrice,
    double? pricePerKg,
    double? minimumPrice,
    double? insurancePercent,
    double? goodsValue,
    double? agentCommission,
    double? insuranceAmount,
    double? customsCost,
    double? exportDocCost,
    double? boxPackingCost,
    double? doorToDoorCost,
    double? postSubCost,
    double? discountAmount,
    double? totalPostCost,
    double? totalPostCostPaid,
    double? unpaidAmount,
    double? totalCostEuroCurrency,
    double? unpaidAmountEuro,
  }) {
    return SendRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      truckNumber: truckNumber ?? this.truckNumber,
      codeNumber: codeNumber ?? this.codeNumber,
      senderName: senderName ?? this.senderName,
      senderPhone: senderPhone ?? this.senderPhone,
      senderIdNumber: senderIdNumber ?? this.senderIdNumber,
      goodsDescription: goodsDescription ?? this.goodsDescription,
      notes: notes ?? this.notes,
      boxNumber: boxNumber ?? this.boxNumber,
      palletNumber: palletNumber ?? this.palletNumber,
      realWeightKg: realWeightKg ?? this.realWeightKg,
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
      isDimensionCalculated:
          isDimensionCalculated ?? this.isDimensionCalculated,
      additionalKg: additionalKg ?? this.additionalKg,
      totalWeightKg: totalWeightKg ?? this.totalWeightKg,
      agentName: agentName ?? this.agentName,
      branchName: branchName ?? this.branchName,
      // agentCode: agentCode ?? this.agentCode,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      receiverCountry: receiverCountry ?? this.receiverCountry,
      receiverCity: receiverCity ?? this.receiverCity,
      streetName: streetName ?? this.streetName,

      zipCode: zipCode ?? this.zipCode,
      // postalCity: postalCity ?? this.postalCity,
      // postalCountry: postalCountry ?? this.postalCountry,
      doorToDoorPrice: doorToDoorPrice ?? this.doorToDoorPrice,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      minimumPrice: minimumPrice ?? this.minimumPrice,
      insurancePercent: insurancePercent ?? this.insurancePercent,
      goodsValue: goodsValue ?? this.goodsValue,
      // agentCommission: agentCommission ?? this.agentCommission,
      insuranceAmount: insuranceAmount ?? this.insuranceAmount,
      customsCost: customsCost ?? this.customsCost,
  
      boxPackingCost: boxPackingCost ?? this.boxPackingCost,
      doorToDoorCost: doorToDoorCost ?? this.doorToDoorCost,
      postSubCost: postSubCost ?? this.postSubCost,
      discountAmount: discountAmount ?? this.discountAmount,
      totalPostCost: totalPostCost ?? this.totalPostCost,
      totalPostCostPaid: totalPostCostPaid ?? this.totalPostCostPaid,
      unpaidAmount: unpaidAmount ?? this.unpaidAmount,
      totalCostEuroCurrency:
          totalCostEuroCurrency ?? this.totalCostEuroCurrency,
      unpaidAmountEuro: unpaidAmountEuro ?? this.unpaidAmountEuro,
    );
  }
  @override
  String toString() {
    return '''
SendRecord {
  id: $id,
  date: $date,
  idType: $idType,
  truckNumber: $truckNumber,
  codeNumber: $codeNumber,
  senderName: $senderName,
  senderPhone: $senderPhone,
  senderIdNumber: $senderIdNumber,
  goodsDescription: $goodsDescription,
  notes: $notes,
  boxNumber: $boxNumber,
  palletNumber: $palletNumber,
  realWeightKg: $realWeightKg,
  length: $length,
  width: $width,
  height: $height,
  isDimensionCalculated: $isDimensionCalculated,
  additionalKg: $additionalKg,
  totalWeightKg: $totalWeightKg,
  agentName: $agentName,
  branchName: $branchName,
  receiverName: $receiverName,
  receiverPhone: $receiverPhone,
  receiverCountry: $receiverCountry,
  receiverCity: $receiverCity,
  streetName: $streetName,
  zipCode: $zipCode,
  doorToDoorPrice: $doorToDoorPrice,
  pricePerKg: $pricePerKg,
  minimumPrice: $minimumPrice,
  insurancePercent: $insurancePercent,
  goodsValue: $goodsValue,
  insuranceAmount: $insuranceAmount,
  customsCost: $customsCost,
  boxPackingCost: $boxPackingCost,
  doorToDoorCost: $doorToDoorCost,
  postSubCost: $postSubCost,
  discountAmount: $discountAmount,
  totalPostCost: $totalPostCost,
  totalPostCostPaid: $totalPostCostPaid,
  unpaidAmount: $unpaidAmount,
  totalCostEuroCurrency: $totalCostEuroCurrency,
  unpaidAmountEuro: $unpaidAmountEuro
}
''';
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SendRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date;

  @override
  int get hashCode => id.hashCode ^ date.hashCode;
}
