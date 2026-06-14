class StockInItemProductBrief {
  const StockInItemProductBrief({
    required this.id,
    required this.refNum,
    required this.productName,
  });

  factory StockInItemProductBrief.fromJson(Map<String, dynamic> json) {
    return StockInItemProductBrief(
      id: (json['id'] as num).toInt(),
      refNum: (json['ref_num'] ?? '').toString(),
      productName: (json['product_name'] ?? '').toString(),
    );
  }

  final int id;
  final String refNum;
  final String productName;
}

class StockInItemLotBrief {
  const StockInItemLotBrief({
    required this.id,
    required this.lotNumber,
    this.status,
  });

  factory StockInItemLotBrief.fromJson(Map<String, dynamic> json) {
    return StockInItemLotBrief(
      id: (json['id'] as num).toInt(),
      lotNumber: (json['lot_number'] ?? '').toString(),
      status: json['status'] as String?,
    );
  }

  final int id;
  final String lotNumber;
  final String? status;
}

enum LotEntryMode { scan, manual }

extension LotEntryModeX on LotEntryMode {
  String get apiValue => name;
  static LotEntryMode parse(String? raw) {
    switch (raw) {
      case 'manual':
        return LotEntryMode.manual;
      case 'scan':
      default:
        return LotEntryMode.scan;
    }
  }
}

/// Mirrors the Laravel StockInItemResource payload.
class StockInItemModel {
  const StockInItemModel({
    required this.id,
    required this.stockInId,
    required this.productId,
    required this.supplierBatchCode,
    this.product,
    this.lotId,
    this.lot,
    this.scannedLotNumber,
    this.expiryDate,
    this.lotEntryMode = LotEntryMode.scan,
    this.expiryEntryMode = LotEntryMode.scan,
    this.missingLotFlag = false,
    this.sourceBarcode,
    this.entryOverrideReason,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  factory StockInItemModel.fromJson(Map<String, dynamic> json) {
    return StockInItemModel(
      id: (json['id'] as num).toInt(),
      stockInId: (json['stock_in_id'] as num).toInt(),
      productId: (json['product_id'] as num).toInt(),
      supplierBatchCode: (json['supplier_batch_code'] ?? '').toString(),
      product: json['product'] is Map<String, dynamic>
          ? StockInItemProductBrief.fromJson(
              json['product'] as Map<String, dynamic>,
            )
          : null,
      lotId: (json['lot_id'] as num?)?.toInt(),
      lot: json['lot'] is Map<String, dynamic>
          ? StockInItemLotBrief.fromJson(
              json['lot'] as Map<String, dynamic>,
            )
          : null,
      scannedLotNumber: json['scanned_lot_number'] as String?,
      expiryDate: DateTime.tryParse((json['expiry_date'] ?? '').toString()),
      lotEntryMode:
          LotEntryModeX.parse(json['lot_entry_mode'] as String?),
      expiryEntryMode:
          LotEntryModeX.parse(json['expiry_entry_mode'] as String?),
      missingLotFlag: (json['missing_lot_flag'] as bool?) ?? false,
      sourceBarcode: json['source_barcode'] as String?,
      entryOverrideReason: json['entry_override_reason'] as String?,
      remarks: json['remarks'] as String?,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()),
    );
  }

  final int id;
  final int stockInId;
  final int productId;
  final String supplierBatchCode;
  final StockInItemProductBrief? product;
  final int? lotId;
  final StockInItemLotBrief? lot;
  final String? scannedLotNumber;
  final DateTime? expiryDate;
  final LotEntryMode lotEntryMode;
  final LotEntryMode expiryEntryMode;
  final bool missingLotFlag;
  final String? sourceBarcode;
  final String? entryOverrideReason;
  final String? remarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get productLabel =>
      product != null ? '${product!.refNum} • ${product!.productName}' : '—';
  String get lotLabel =>
      scannedLotNumber ?? lot?.lotNumber ?? (missingLotFlag ? 'Missing lot' : '—');
}
