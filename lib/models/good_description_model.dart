class GoodsDescription {
  final int? id;
  final String descriptionEn;
  final String descriptionAr;
  bool isSelected;
  int quantity;
  double weight; // Add this field

  GoodsDescription({
    this.id,
    required this.descriptionEn,
    required this.descriptionAr,
    this.isSelected = false,
    this.quantity = 1,
    this.weight = 0.0, // Default weight
  });

  factory GoodsDescription.fromMap(Map<String, dynamic> map) {
    return GoodsDescription(
      id: map['id'],
      descriptionEn: map['descriptionEn'] ?? '',
      descriptionAr: map['descriptionAr'] ?? '',
      weight: map['weight'] ?? 0.0, // Add this line
    );
  }

  // Add this method to convert the object to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descriptionEn': descriptionEn,
      'descriptionAr': descriptionAr,
      'weight': weight, // Add this line
    };
  }
}
