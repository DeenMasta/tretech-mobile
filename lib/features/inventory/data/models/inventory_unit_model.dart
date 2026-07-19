class InventoryProductBrief {
  const InventoryProductBrief({
    required this.id,
    required this.refNum,
    required this.productName,
    this.productType,
    this.category,
    this.uom,
  });

  factory InventoryProductBrief.fromJson(Map<String, dynamic> json) {
    return InventoryProductBrief(
      id: (json['id'] as num?)?.toInt() ?? 0,
      refNum: (json['ref_num'] ?? '').toString(),
      productName: (json['product_name'] ?? '').toString(),
      productType: json['product_type'] as String?,
      category: json['category'] as String?,
      uom: json['uom'] as String?,
    );
  }

  final int id;
  final String refNum;
  final String productName;
  final String? productType;
  final String? category;
  final String? uom;
}

class InventorySupplierBrief {
  const InventorySupplierBrief({required this.id, required this.supplierName});

  factory InventorySupplierBrief.fromJson(Map<String, dynamic> json) {
    return InventorySupplierBrief(
      id: (json['id'] as num?)?.toInt() ?? 0,
      supplierName: (json['supplier_name'] ?? '').toString(),
    );
  }

  final int id;
  final String supplierName;
}

class InventoryInstrumentSetBrief {
  const InventoryInstrumentSetBrief({required this.id, this.setName});

  factory InventoryInstrumentSetBrief.fromJson(Map<String, dynamic> json) {
    return InventoryInstrumentSetBrief(
      id: (json['id'] as num?)?.toInt() ?? 0,
      setName: json['set_name'] as String?,
    );
  }

  final int id;
  final String? setName;
}

class InventoryQrLabelBrief {
  const InventoryQrLabelBrief({
    required this.id,
    this.qrPayload,
    this.generatedAt,
  });

  factory InventoryQrLabelBrief.fromJson(Map<String, dynamic> json) {
    return InventoryQrLabelBrief(
      id: (json['id'] as num?)?.toInt() ?? 0,
      qrPayload: json['qr_payload'] as String?,
      generatedAt: DateTime.tryParse((json['generated_at'] ?? '').toString()),
    );
  }

  final int id;
  final String? qrPayload;
  final DateTime? generatedAt;
}

class InventoryLotHoldingBrief {
  const InventoryLotHoldingBrief({
    this.holdingReason,
    this.assignedAt,
    this.resolvedAt,
  });

  factory InventoryLotHoldingBrief.fromJson(Map<String, dynamic> json) {
    return InventoryLotHoldingBrief(
      holdingReason: json['holding_reason'] as String?,
      assignedAt: DateTime.tryParse((json['assigned_at'] ?? '').toString()),
      resolvedAt: DateTime.tryParse((json['resolved_at'] ?? '').toString()),
    );
  }

  final String? holdingReason;
  final DateTime? assignedAt;
  final DateTime? resolvedAt;
}

class InventoryUnitModel {
  const InventoryUnitModel({
    required this.id,
    required this.lotNumber,
    required this.status,
    this.manufacturingDate,
    this.expiryDate,
    this.quantity,
    this.quantityAvailable,
    this.quantityConsigned,
    this.productQtyInSet,
    this.currentLocationType,
    this.currentLocationId,
    this.remarks,
    this.receivedAt,
    this.createdAt,
    this.updatedAt,
    this.isSystemGeneratedLot = false,
    this.lotMovementsCount,
    this.product,
    this.supplier,
    this.instrumentSet,
    this.qrLabel,
    this.lotHolding,
  });

  factory InventoryUnitModel.fromJson(Map<String, dynamic> json) {
    return InventoryUnitModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      lotNumber: (json['lot_number'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      manufacturingDate: DateTime.tryParse(
        (json['manufacturing_date'] ?? '').toString(),
      ),
      expiryDate: DateTime.tryParse((json['expiry_date'] ?? '').toString()),
      quantity: (json['quantity'] as num?)?.toInt(),
      quantityAvailable: (json['quantity_available'] as num?)?.toInt(),
      quantityConsigned: (json['quantity_consigned'] as num?)?.toInt(),
      productQtyInSet: (json['product_qty_in_set'] as num?)?.toInt(),
      currentLocationType: json['current_location_type'] as String?,
      currentLocationId: (json['current_location_id'] as num?)?.toInt(),
      remarks: json['remarks'] as String?,
      receivedAt: DateTime.tryParse((json['received_at'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()),
      isSystemGeneratedLot: (json['is_system_generated_lot'] as bool?) ?? false,
      lotMovementsCount: (json['lot_movements_count'] as num?)?.toInt(),
      product: json['product'] is Map<String, dynamic>
          ? InventoryProductBrief.fromJson(
              json['product'] as Map<String, dynamic>,
            )
          : null,
      supplier: json['supplier'] is Map<String, dynamic>
          ? InventorySupplierBrief.fromJson(
              json['supplier'] as Map<String, dynamic>,
            )
          : null,
      instrumentSet: json['instrument_set'] is Map<String, dynamic>
          ? InventoryInstrumentSetBrief.fromJson(
              json['instrument_set'] as Map<String, dynamic>,
            )
          : null,
      qrLabel: json['qr_label'] is Map<String, dynamic>
          ? InventoryQrLabelBrief.fromJson(
              json['qr_label'] as Map<String, dynamic>,
            )
          : null,
      lotHolding: json['lot_holding'] is Map<String, dynamic>
          ? InventoryLotHoldingBrief.fromJson(
              json['lot_holding'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final int id;
  final String lotNumber;
  final String status;
  final DateTime? manufacturingDate;
  final DateTime? expiryDate;
  final int? quantity;
  final int? quantityAvailable;
  final int? quantityConsigned;
  final int? productQtyInSet;
  final String? currentLocationType;
  final int? currentLocationId;
  final String? remarks;
  final DateTime? receivedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isSystemGeneratedLot;
  final int? lotMovementsCount;
  final InventoryProductBrief? product;
  final InventorySupplierBrief? supplier;
  final InventoryInstrumentSetBrief? instrumentSet;
  final InventoryQrLabelBrief? qrLabel;
  final InventoryLotHoldingBrief? lotHolding;
}
