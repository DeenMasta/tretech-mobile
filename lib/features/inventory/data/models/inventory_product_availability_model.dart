class InventoryProductAvailabilityModel {
  const InventoryProductAvailabilityModel({
    required this.id,
    required this.refNum,
    required this.productName,
    this.productType,
    this.category,
    this.uom,
    this.availableLotsCount,
    this.totalQuantityAvailable,
  });

  factory InventoryProductAvailabilityModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return InventoryProductAvailabilityModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      refNum: (json['ref_num'] ?? '').toString(),
      productName: (json['product_name'] ?? '').toString(),
      productType: json['product_type'] as String?,
      category: json['category'] as String?,
      uom: json['uom'] as String?,
      availableLotsCount: (json['available_lots_count'] as num?)?.toInt(),
      totalQuantityAvailable: (json['total_quantity_available'] as num?)?.toInt(),
    );
  }

  final int id;
  final String refNum;
  final String productName;
  final String? productType;
  final String? category;
  final String? uom;
  final int? availableLotsCount;
  final int? totalQuantityAvailable;
}
