class InventoryMovementUser {
  const InventoryMovementUser({
    required this.id,
    required this.fullName,
    this.email,
  });

  factory InventoryMovementUser.fromJson(Map<String, dynamic> json) {
    return InventoryMovementUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: (json['full_name'] ?? '').toString(),
      email: json['email'] as String?,
    );
  }

  final int id;
  final String fullName;
  final String? email;
}

class InventoryMovementLotProduct {
  const InventoryMovementLotProduct({
    required this.id,
    required this.refNum,
    required this.productName,
  });

  factory InventoryMovementLotProduct.fromJson(Map<String, dynamic> json) {
    return InventoryMovementLotProduct(
      id: (json['id'] as num?)?.toInt() ?? 0,
      refNum: (json['ref_num'] ?? '').toString(),
      productName: (json['product_name'] ?? '').toString(),
    );
  }

  final int id;
  final String refNum;
  final String productName;
}

class InventoryMovementLotBrief {
  const InventoryMovementLotBrief({
    required this.id,
    required this.lotNumber,
    required this.status,
    this.product,
  });

  factory InventoryMovementLotBrief.fromJson(Map<String, dynamic> json) {
    return InventoryMovementLotBrief(
      id: (json['id'] as num?)?.toInt() ?? 0,
      lotNumber: (json['lot_number'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      product: json['product'] is Map<String, dynamic>
          ? InventoryMovementLotProduct.fromJson(
              json['product'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final int id;
  final String lotNumber;
  final String status;
  final InventoryMovementLotProduct? product;
}

class InventoryMovementModel {
  const InventoryMovementModel({
    required this.id,
    required this.lotId,
    required this.movementType,
    this.referenceType,
    this.referenceId,
    this.fromStatus,
    this.toStatus,
    this.fromLocationType,
    this.fromLocationId,
    this.toLocationType,
    this.toLocationId,
    this.performedAt,
    this.performedByUser,
    this.lot,
    this.remarks,
    this.createdAt,
  });

  factory InventoryMovementModel.fromJson(Map<String, dynamic> json) {
    return InventoryMovementModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      lotId: (json['lot_id'] as num?)?.toInt() ?? 0,
      movementType: (json['movement_type'] ?? '').toString(),
      referenceType: json['reference_type'] as String?,
      referenceId: (json['reference_id'] as num?)?.toInt(),
      fromStatus: json['from_status'] as String?,
      toStatus: json['to_status'] as String?,
      fromLocationType: json['from_location_type'] as String?,
      fromLocationId: (json['from_location_id'] as num?)?.toInt(),
      toLocationType: json['to_location_type'] as String?,
      toLocationId: (json['to_location_id'] as num?)?.toInt(),
      performedAt: DateTime.tryParse((json['performed_at'] ?? '').toString()),
      performedByUser: json['performed_by_user'] is Map<String, dynamic>
          ? InventoryMovementUser.fromJson(
              json['performed_by_user'] as Map<String, dynamic>,
            )
          : null,
      lot: json['lot'] is Map<String, dynamic>
          ? InventoryMovementLotBrief.fromJson(
              json['lot'] as Map<String, dynamic>,
            )
          : null,
      remarks: json['remarks'] as String?,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }

  final int id;
  final int lotId;
  final String movementType;
  final String? referenceType;
  final int? referenceId;
  final String? fromStatus;
  final String? toStatus;
  final String? fromLocationType;
  final int? fromLocationId;
  final String? toLocationType;
  final int? toLocationId;
  final DateTime? performedAt;
  final InventoryMovementUser? performedByUser;
  final InventoryMovementLotBrief? lot;
  final String? remarks;
  final DateTime? createdAt;
}
