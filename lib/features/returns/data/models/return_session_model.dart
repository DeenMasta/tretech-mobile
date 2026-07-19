/// Data models for the Returns workflow, mirroring the backend
/// ReturnSessionResource / ReturnSessionItemResource payloads.
library;

// ── User / Consignment brief ──────────────────────────────────────────────

class ReturnUserBrief {
  const ReturnUserBrief({required this.id, required this.fullName});

  factory ReturnUserBrief.fromJson(Map<String, dynamic> json) =>
      ReturnUserBrief(
        id: (json['id'] as num).toInt(),
        fullName: (json['full_name'] ?? json['name'] ?? '').toString(),
      );

  final int id;
  final String fullName;
}

class ReturnConsignmentBrief {
  const ReturnConsignmentBrief({required this.id, required this.consignmentNo, this.clientName});

  factory ReturnConsignmentBrief.fromJson(Map<String, dynamic> json) =>
      ReturnConsignmentBrief(
        id: (json['id'] as num).toInt(),
        consignmentNo: (json['consignment_no'] ?? '').toString(),
        clientName: (json['client'] as Map<String, dynamic>?)?['client_name']?.toString(),
      );

  final int id;
  final String consignmentNo;
  final String? clientName;

  String get label =>
      clientName != null ? '$consignmentNo – $clientName' : consignmentNo;
}

// ── Lot brief attached to a returned item ────────────────────────────────

class ReturnLotBrief {
  const ReturnLotBrief({required this.id, required this.lotNumber, this.productName, this.refNum});

  factory ReturnLotBrief.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return ReturnLotBrief(
      id: (json['id'] as num).toInt(),
      lotNumber: (json['lot_number'] ?? '').toString(),
      productName: product?['product_name']?.toString(),
      refNum: product?['ref_num']?.toString(),
    );
  }

  final int id;
  final String lotNumber;
  final String? productName;
  final String? refNum;
}

// ── Return Session Item ───────────────────────────────────────────────────

class ReturnSessionItem {
  const ReturnSessionItem({
    required this.id,
    required this.returnSessionId,
    this.lotId,
    this.lot,
    this.productName,
    this.instrumentSetName,
    this.quantity,
    this.usedQuantity,
    this.damagedQuantity,
    this.missingQuantity,
    this.returnedAt,
    this.remarks,
  });

  factory ReturnSessionItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final instrumentSet = json['instrument_set'] as Map<String, dynamic>?;
    return ReturnSessionItem(
      id: (json['id'] as num).toInt(),
      returnSessionId: (json['return_session_id'] as num).toInt(),
      lotId: (json['lot_id'] as num?)?.toInt(),
      lot: json['lot'] is Map<String, dynamic>
          ? ReturnLotBrief.fromJson(json['lot'] as Map<String, dynamic>)
          : null,
      productName: product?['product_name']?.toString(),
      instrumentSetName: instrumentSet?['set_name']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt(),
      usedQuantity: (json['used_quantity'] as num?)?.toInt(),
      damagedQuantity: (json['damaged_quantity'] as num?)?.toInt(),
      missingQuantity: (json['missing_quantity'] as num?)?.toInt(),
      returnedAt: DateTime.tryParse((json['returned_at'] ?? '').toString()),
      remarks: json['remarks'] as String?,
    );
  }

  final int id;
  final int returnSessionId;
  final int? lotId;
  final ReturnLotBrief? lot;
  final String? productName;
  final String? instrumentSetName;
  final int? quantity;
  final int? usedQuantity;
  final int? damagedQuantity;
  final int? missingQuantity;
  final DateTime? returnedAt;
  final String? remarks;

  /// Display label for the item — lot number then product fallback.
  String get displayLabel {
    if (lot != null) return lot!.lotNumber;
    if (productName != null) return productName!;
    if (instrumentSetName != null) return instrumentSetName!;
    return '#$id';
  }

  String get productLabel {
    if (lot?.productName != null) return lot!.productName!;
    if (productName != null) return productName!;
    if (instrumentSetName != null) return instrumentSetName!;
    return '—';
  }

  int get totalScanned =>
      (quantity ?? 0) + (usedQuantity ?? 0) + (damagedQuantity ?? 0) + (missingQuantity ?? 0);
}

// ── Reconciliation items (usage / invoice report) ────────────────────────

class ReconciliationItem {
  const ReconciliationItem({
    required this.id,
    this.lotNumber,
    this.productName,
    this.refNum,
    this.totalConsigned,
    this.totalReturned,
    this.totalUsed,
    this.totalDamaged,
    this.totalMissing,
    this.invoiceQuantity,
  });

  factory ReconciliationItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final lot = json['lot'] as Map<String, dynamic>?;
    return ReconciliationItem(
      id: (json['id'] as num).toInt(),
      lotNumber: (lot?['lot_number'] ?? json['lot_number'])?.toString(),
      productName: product?['product_name']?.toString(),
      refNum: product?['ref_num']?.toString(),
      totalConsigned: (json['total_consigned'] as num?)?.toInt(),
      totalReturned: (json['total_returned'] as num?)?.toInt(),
      totalUsed: (json['total_used'] as num?)?.toInt(),
      totalDamaged: (json['total_damaged'] as num?)?.toInt(),
      totalMissing: (json['total_missing'] as num?)?.toInt(),
      invoiceQuantity: (json['invoice_quantity'] as num?)?.toInt(),
    );
  }

  final int id;
  final String? lotNumber;
  final String? productName;
  final String? refNum;
  final int? totalConsigned;
  final int? totalReturned;
  final int? totalUsed;
  final int? totalDamaged;
  final int? totalMissing;
  final int? invoiceQuantity;
}

class ReconciliationBrief {
  const ReconciliationBrief({required this.id, this.items = const []});

  factory ReconciliationBrief.fromJson(Map<String, dynamic> json) =>
      ReconciliationBrief(
        id: (json['id'] as num).toInt(),
        items: (json['items'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ReconciliationItem.fromJson)
            .toList(),
      );

  final int id;
  final List<ReconciliationItem> items;
}

// ── Return Session ────────────────────────────────────────────────────────

class ReturnSessionModel {
  const ReturnSessionModel({
    required this.id,
    required this.returnSessionNo,
    required this.status,
    required this.consignmentId,
    this.consignment,
    this.picUserId,
    this.picUser,
    this.completedByUser,
    this.remarks,
    this.startedAt,
    this.completedAt,
    this.itemsCount,
    this.items,
    this.reconciliation,
    this.createdAt,
    this.updatedAt,
  });

  factory ReturnSessionModel.fromJson(Map<String, dynamic> json) =>
      ReturnSessionModel(
        id: (json['id'] as num).toInt(),
        returnSessionNo: (json['return_session_no'] ?? '').toString(),
        status: (json['status'] ?? 'in_progress').toString(),
        consignmentId: (json['consignment_id'] as num).toInt(),
        consignment: json['consignment'] is Map<String, dynamic>
            ? ReturnConsignmentBrief.fromJson(
                json['consignment'] as Map<String, dynamic>,
              )
            : null,
        picUserId: (json['pic_user_id'] as num?)?.toInt(),
        picUser: json['pic_user'] is Map<String, dynamic>
            ? ReturnUserBrief.fromJson(json['pic_user'] as Map<String, dynamic>)
            : null,
        completedByUser: json['completed_by_user'] is Map<String, dynamic>
            ? ReturnUserBrief.fromJson(
                json['completed_by_user'] as Map<String, dynamic>,
              )
            : null,
        remarks: json['remarks'] as String?,
        startedAt: DateTime.tryParse((json['started_at'] ?? '').toString()),
        completedAt: DateTime.tryParse((json['completed_at'] ?? '').toString()),
        itemsCount: (json['items_count'] as num?)?.toInt(),
        items: json['items'] is List
            ? (json['items'] as List<dynamic>)
                  .whereType<Map<String, dynamic>>()
                  .map(ReturnSessionItem.fromJson)
                  .toList()
            : null,
        reconciliation: json['reconciliation'] is Map<String, dynamic>
            ? ReconciliationBrief.fromJson(
                json['reconciliation'] as Map<String, dynamic>,
              )
            : null,
        createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
        updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()),
      );

  final int id;
  final String returnSessionNo;
  final String status;
  final int consignmentId;
  final ReturnConsignmentBrief? consignment;
  final int? picUserId;
  final ReturnUserBrief? picUser;
  final ReturnUserBrief? completedByUser;
  final String? remarks;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? itemsCount;
  final List<ReturnSessionItem>? items;
  final ReconciliationBrief? reconciliation;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isReadOnly => status == 'completed' || status == 'reconciled';
  bool get isCompleted => status == 'completed' || status == 'reconciled';
  bool get isInProgress => status == 'in_progress';

  String get picUserName => picUser?.fullName ?? '—';
  String get consignmentLabel => consignment?.label ?? '—';
}

// ── Pagination wrapper ────────────────────────────────────────────────────

class ReturnSessionPage {
  const ReturnSessionPage({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
  });

  final List<ReturnSessionModel> items;
  final int total;
  final int currentPage;
  final int lastPage;
  final int perPage;
}
