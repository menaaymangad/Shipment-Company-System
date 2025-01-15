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
      descriptionEn: map['description_en'] ?? '',
      descriptionAr: map['description_ar'] ?? '',
    );
  }
  // Add this method to convert the object to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description_en': descriptionEn,
      'description_ar': descriptionAr,
    };
  }
}
