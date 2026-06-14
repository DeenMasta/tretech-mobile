/// Mirrors the Laravel QrLabelResource payload.
class QrLabelLotBrief {
  const QrLabelLotBrief({
    required this.id,
    required this.lotNumber,
    this.supplierBatchCode,
    this.expiryDate,
    this.status,
  });

  factory QrLabelLotBrief.fromJson(Map<String, dynamic> json) {
    return QrLabelLotBrief(
      id: (json['id'] as num).toInt(),
      lotNumber: (json['lot_number'] ?? '').toString(),
      supplierBatchCode: json['supplier_batch_code'] as String?,
      expiryDate: DateTime.tryParse((json['expiry_date'] ?? '').toString()),
      status: json['status'] as String?,
    );
  }

  final int id;
  final String lotNumber;
  final String? supplierBatchCode;
  final DateTime? expiryDate;
  final String? status;
}

class QrLabelModel {
  const QrLabelModel({
    required this.id,
    required this.lotId,
    required this.qrPayload,
    this.generatedAt,
    this.generatedByUserId,
    this.lot,
    this.createdAt,
  });

  factory QrLabelModel.fromJson(Map<String, dynamic> json) {
    return QrLabelModel(
      id: (json['id'] as num).toInt(),
      lotId: (json['lot_id'] as num).toInt(),
      qrPayload: (json['qr_payload'] ?? '').toString(),
      generatedAt: DateTime.tryParse((json['generated_at'] ?? '').toString()),
      generatedByUserId: (json['generated_by_user_id'] as num?)?.toInt(),
      lot: json['lot'] is Map<String, dynamic>
          ? QrLabelLotBrief.fromJson(json['lot'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }

  final int id;
  final int lotId;
  final String qrPayload;
  final DateTime? generatedAt;
  final int? generatedByUserId;
  final QrLabelLotBrief? lot;
  final DateTime? createdAt;
}
