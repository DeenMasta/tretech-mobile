/// Product information returned with a finalized stock-in lot.
class LotProductBrief {
  const LotProductBrief({
    required this.id,
    required this.refNum,
    required this.productName,
  });

  factory LotProductBrief.fromJson(Map<String, dynamic> json) =>
      LotProductBrief(
        id: (json['id'] as num).toInt(),
        refNum: (json['ref_num'] ?? '').toString(),
        productName: (json['product_name'] ?? '').toString(),
      );

  final int id;
  final String refNum;
  final String productName;

  String get displayLabel =>
      refNum.isEmpty ? productName : '$refNum - $productName';
}

/// Mirrors the Laravel LotResource (created when finalizing a stock-in session).
class LotModel {
  const LotModel({
    required this.id,
    required this.supplierId,
    required this.lotNumber,
    required this.status,
    this.productId,
    this.product,
    this.instrumentSetId,
    this.originalLotNumber,
    this.isSystemGeneratedLot = false,
    this.supplierBatchCode,
    this.manufacturingDate,
    this.quantity,
    this.quantityAvailable,
    this.expiryDate,
    this.currentLocationType,
    this.currentLocationId,
    this.receivedAt,
  });

  factory LotModel.fromJson(Map<String, dynamic> json) {
    return LotModel(
      id: (json['id'] as num).toInt(),
      supplierId: (json['supplier_id'] as num).toInt(),
      lotNumber: (json['lot_number'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      productId: (json['product_id'] as num?)?.toInt(),
      product: json['product'] is Map<String, dynamic>
          ? LotProductBrief.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      instrumentSetId: (json['instrument_set_id'] as num?)?.toInt(),
      originalLotNumber: json['original_lot_number'] as String?,
      isSystemGeneratedLot: (json['is_system_generated_lot'] as bool?) ?? false,
      supplierBatchCode: json['supplier_batch_code'] as String?,
      manufacturingDate: DateTime.tryParse(
        (json['manufacturing_date'] ?? '').toString(),
      ),
      quantity: (json['quantity'] as num?)?.toInt(),
      quantityAvailable: (json['quantity_available'] as num?)?.toInt(),
      expiryDate: DateTime.tryParse((json['expiry_date'] ?? '').toString()),
      currentLocationType: json['current_location_type'] as String?,
      currentLocationId: (json['current_location_id'] as num?)?.toInt(),
      receivedAt: DateTime.tryParse((json['received_at'] ?? '').toString()),
    );
  }

  final int id;
  final int supplierId;
  final String lotNumber;
  final String status;
  final int? productId;
  final LotProductBrief? product;
  final int? instrumentSetId;
  final String? originalLotNumber;
  final bool isSystemGeneratedLot;
  final String? supplierBatchCode;
  final DateTime? manufacturingDate;
  final int? quantity;
  final int? quantityAvailable;
  final DateTime? expiryDate;
  final String? currentLocationType;
  final int? currentLocationId;
  final DateTime? receivedAt;

  String get productLabel => product?.displayLabel ?? 'Instrument set lot';

  int get displayedQuantity => quantityAvailable ?? quantity ?? 1;
}
