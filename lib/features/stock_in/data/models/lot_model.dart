/// Mirrors the Laravel LotResource (created when finalizing a stock-in session).
class LotModel {
  const LotModel({
    required this.id,
    required this.productId,
    required this.supplierId,
    required this.lotNumber,
    required this.status,
    this.originalLotNumber,
    this.isSystemGeneratedLot = false,
    this.supplierBatchCode,
    this.expiryDate,
    this.currentLocationType,
    this.currentLocationId,
    this.receivedAt,
  });

  factory LotModel.fromJson(Map<String, dynamic> json) {
    return LotModel(
      id: (json['id'] as num).toInt(),
      productId: (json['product_id'] as num).toInt(),
      supplierId: (json['supplier_id'] as num).toInt(),
      lotNumber: (json['lot_number'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      originalLotNumber: json['original_lot_number'] as String?,
      isSystemGeneratedLot:
          (json['is_system_generated_lot'] as bool?) ?? false,
      supplierBatchCode: json['supplier_batch_code'] as String?,
      expiryDate: DateTime.tryParse((json['expiry_date'] ?? '').toString()),
      currentLocationType: json['current_location_type'] as String?,
      currentLocationId: (json['current_location_id'] as num?)?.toInt(),
      receivedAt: DateTime.tryParse((json['received_at'] ?? '').toString()),
    );
  }

  final int id;
  final int productId;
  final int supplierId;
  final String lotNumber;
  final String status;
  final String? originalLotNumber;
  final bool isSystemGeneratedLot;
  final String? supplierBatchCode;
  final DateTime? expiryDate;
  final String? currentLocationType;
  final int? currentLocationId;
  final DateTime? receivedAt;
}
