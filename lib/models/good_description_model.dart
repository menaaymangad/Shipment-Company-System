import 'dart:convert';

class GoodsDescription {
  int? id;
  String descriptionEn;
  String descriptionAr;
  double weight; // Add this
  int quantity; // Add this

  GoodsDescription({
    this.id,
    required this.descriptionEn,
    required this.descriptionAr,
    this.weight = 0.0, // Default value
    this.quantity = 1, // Default value
  });
  String get formattedDescription {
    return '$descriptionAr * $quantity (${weight}kg)';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description_en': descriptionEn,
      'description_ar': descriptionAr,
      'weight': weight, // Add this
      'quantity': quantity, // Add this
    };
  }

  factory GoodsDescription.fromMap(Map<String, dynamic> map) {
    return GoodsDescription(
      id: map['id'],
      descriptionEn: map['description_en'],
      descriptionAr: map['description_ar'],
      weight: map['weight'] ?? 0.0, // Add this
      quantity: map['quantity'] ?? 1, // Add this
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'descriptionEn': descriptionEn,
        'descriptionAr': descriptionAr,
        'weight': weight,
        'quantity': quantity,
      };
  // Add this to your GoodsDescription class
  static List<GoodsDescription> parseGoodsList(String jsonString) {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => GoodsDescription.fromMap(json)).toList();
    } catch (e) {
      print('Error parsing goods descriptions: $e');
      return [];
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoodsDescription &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
