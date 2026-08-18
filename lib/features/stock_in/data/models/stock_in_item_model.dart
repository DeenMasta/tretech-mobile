import 'instrument_set_model.dart';

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

class StockInComponentLotDecision {
  const StockInComponentLotDecision({
    required this.instrumentSetItemId,
    this.lotNumber,
    required this.generateLotNumber,
  });

  factory StockInComponentLotDecision.fromJson(Map<String, dynamic> json) =>
      StockInComponentLotDecision(
        instrumentSetItemId: (json['instrument_set_item_id'] as num).toInt(),
        lotNumber: json['lot_number']?.toString(),
        generateLotNumber: (json['generate_lot_number'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
    'instrument_set_item_id': instrumentSetItemId,
    'lot_number': lotNumber,
    'generate_lot_number': generateLotNumber,
  };

  final int instrumentSetItemId;
  final String? lotNumber;
  final bool generateLotNumber;
}

enum StockInEntryKind { product, set }

extension StockInEntryKindX on StockInEntryKind {
  String get apiValue => name;

  static StockInEntryKind parse(String? raw) {
    switch (raw) {
      case 'set':
        return StockInEntryKind.set;
      case 'product':
      default:
        return StockInEntryKind.product;
    }
  }
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

class StockInItemModel {
  const StockInItemModel({
    required this.id,
    required this.stockInId,
    required this.entryKind,
    this.supplierBatchCode = '',
    this.productId,
    this.instrumentSetId,
    this.product,
    this.instrumentSet,
    this.lotId,
    this.lot,
    this.quantity,
    this.manufacturingDate,
    this.manufacturingDateRaw,
    this.scannedLotNumber,
    this.expiryDate,
    this.lotEntryMode = LotEntryMode.scan,
    this.expiryEntryMode = LotEntryMode.scan,
    this.missingLotFlag = false,
    this.generateLotNumber = false,
    this.componentLots = const [],
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
      entryKind: StockInEntryKindX.parse(json['entry_kind'] as String?),
      productId: (json['product_id'] as num?)?.toInt(),
      instrumentSetId: (json['instrument_set_id'] as num?)?.toInt(),
      supplierBatchCode: (json['supplier_batch_code'] ?? '').toString(),
      product: json['product'] is Map<String, dynamic>
          ? StockInItemProductBrief.fromJson(
              json['product'] as Map<String, dynamic>,
            )
          : null,
      instrumentSet: json['instrument_set'] is Map<String, dynamic>
          ? InstrumentSetModel.fromJson(
              json['instrument_set'] as Map<String, dynamic>,
            )
          : null,
      lotId: (json['lot_id'] as num?)?.toInt(),
      lot: json['lot'] is Map<String, dynamic>
          ? StockInItemLotBrief.fromJson(json['lot'] as Map<String, dynamic>)
          : null,
      quantity: (json['quantity'] as num?)?.toInt(),
      manufacturingDate: DateTime.tryParse(
        (json['manufacturing_date'] ?? '').toString(),
      ),
      manufacturingDateRaw: json['manufacturing_date']?.toString(),
      scannedLotNumber: json['scanned_lot_number'] as String?,
      expiryDate: DateTime.tryParse((json['expiry_date'] ?? '').toString()),
      lotEntryMode: LotEntryModeX.parse(json['lot_entry_mode'] as String?),
      expiryEntryMode: LotEntryModeX.parse(
        json['expiry_entry_mode'] as String?,
      ),
      missingLotFlag: (json['missing_lot_flag'] as bool?) ?? false,
      generateLotNumber: (json['generate_lot_number'] as bool?) ?? false,
      componentLots: (json['component_lots'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(StockInComponentLotDecision.fromJson)
          .toList(),
      sourceBarcode: json['source_barcode'] as String?,
      entryOverrideReason: json['entry_override_reason'] as String?,
      remarks: json['remarks'] as String?,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()),
    );
  }

  final int id;
  final int stockInId;
  final StockInEntryKind entryKind;
  final int? productId;
  final int? instrumentSetId;
  final String supplierBatchCode;
  final StockInItemProductBrief? product;
  final InstrumentSetModel? instrumentSet;
  final int? lotId;
  final StockInItemLotBrief? lot;
  final int? quantity;
  final DateTime? manufacturingDate;
  final String? manufacturingDateRaw;
  final String? scannedLotNumber;
  final DateTime? expiryDate;
  final LotEntryMode lotEntryMode;
  final LotEntryMode expiryEntryMode;
  final bool missingLotFlag;
  final bool generateLotNumber;
  final List<StockInComponentLotDecision> componentLots;
  final String? sourceBarcode;
  final String? entryOverrideReason;
  final String? remarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Number of identical QR stickers required for this stock-in entry.
  /// A legacy or incomplete response without a positive quantity still prints
  /// one label so the lot remains printable.
  int get labelPrintQuantity =>
      quantity != null && quantity! > 0 ? quantity! : 1;

  bool get isSetEntry => entryKind == StockInEntryKind.set;

  bool get isProductEntry => entryKind == StockInEntryKind.product;

  String get productLabel {
    if (isSetEntry) {
      return instrumentSet?.displayLabel ?? 'Instrument set';
    }
    if (product != null) {
      return '${product!.refNum} - ${product!.productName}';
    }
    return '-';
  }

  String get entryKindLabel => isSetEntry ? 'Set entry' : 'Product entry';

  bool get willAutoGenerateLot =>
      isProductEntry &&
      !missingLotFlag &&
      (scannedLotNumber == null || scannedLotNumber!.trim().isEmpty) &&
      lot == null;

  String get lotLabel {
    if (scannedLotNumber != null && scannedLotNumber!.trim().isNotEmpty) {
      return scannedLotNumber!;
    }
    if (lot?.lotNumber != null && lot!.lotNumber.isNotEmpty) {
      return lot!.lotNumber;
    }
    if (missingLotFlag) {
      return 'Missing lot';
    }
    if (isSetEntry) {
      return 'Minted on finalize';
    }
    if (willAutoGenerateLot) {
      return 'Auto-generate on finalize';
    }
    return '-';
  }

  String get manufacturingDateLabel {
    if (manufacturingDate != null) {
      final year = manufacturingDate!.year.toString().padLeft(4, '0');
      final month = manufacturingDate!.month.toString().padLeft(2, '0');
      final day = manufacturingDate!.day.toString().padLeft(2, '0');
      return '$year-$month-$day';
    }

    final raw = manufacturingDateRaw?.trim() ?? '';
    return raw.isEmpty ? '-' : raw;
  }
}
