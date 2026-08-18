/// Lightweight product model used by the stock-in flow.
class ProductModel {
  const ProductModel({
    required this.id,
    required this.refNum,
    required this.productName,
    this.productType,
    this.category,
    this.uom,
    this.requiresExpiry = true,
    this.requiresLot = true,
    this.isActive = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final productType = json['product_type'] as String?;
    return ProductModel(
      id: (json['id'] as num).toInt(),
      refNum: (json['ref_num'] ?? '').toString(),
      productName: (json['product_name'] ?? json['name'] ?? '').toString(),
      productType: productType,
      category: json['category'] as String?,
      uom: json['uom'] as String?,
      requiresExpiry: (json['requires_expiry'] as bool?) ?? true,
      requiresLot:
          isInstrumentProductType(productType) ||
          ((json['requires_lot'] as bool?) ?? true),
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }

  static bool isInstrumentProductType(String? productType) =>
      productType?.trim().toLowerCase() == 'instrument';

  final int id;
  final String refNum;
  final String productName;
  final String? productType;
  final String? category;
  final String? uom;
  final bool requiresExpiry;
  final bool requiresLot;
  final bool isActive;

  bool get isInstrumentProduct => isInstrumentProductType(productType);
}
