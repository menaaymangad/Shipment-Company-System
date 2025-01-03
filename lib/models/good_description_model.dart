class GoodsDescription {
  final int? id;
  final String descriptionEn;
  final String descriptionAr;
  bool isSelected;
  int quantity;

  GoodsDescription({
    this.id,
    required this.descriptionEn,
    required this.descriptionAr,
    this.isSelected = false,
    this.quantity = 1,
  });

  factory GoodsDescription.fromMap(Map<String, dynamic> map) {
    return GoodsDescription(
      id: map['id'],
      descriptionEn: map['descriptionEn'] ?? '',
      descriptionAr: map['descriptionAr'] ?? '',
    );
  }
}
