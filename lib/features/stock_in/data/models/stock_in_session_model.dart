import 'stock_in_item_model.dart';

class StockInUserBrief {
  const StockInUserBrief({required this.id, required this.fullName});

  factory StockInUserBrief.fromJson(Map<String, dynamic> json) {
    return StockInUserBrief(
      id: (json['id'] as num).toInt(),
      fullName: (json['full_name'] ?? json['name'] ?? '').toString(),
    );
  }

  final int id;
  final String fullName;
}

class StockInSupplierBrief {
  const StockInSupplierBrief({required this.id, required this.supplierName});

  factory StockInSupplierBrief.fromJson(Map<String, dynamic> json) {
    return StockInSupplierBrief(
      id: (json['id'] as num).toInt(),
      supplierName:
          (json['supplier_name'] ?? json['name'] ?? '').toString(),
    );
  }

  final int id;
  final String supplierName;
}

/// Mirrors the Laravel StockInSessionResource payload.
class StockInSessionModel {
  const StockInSessionModel({
    required this.id,
    required this.supplierId,
    required this.sessionNo,
    required this.doNumber,
    required this.stockInAt,
    required this.picUserId,
    required this.status,
    this.supplier,
    this.picUser,
    this.confirmedByUser,
    this.remarks,
    this.confirmedAt,
    this.confirmedByUserId,
    this.itemsCount,
    this.items,
    this.createdAt,
    this.updatedAt,
  });

  factory StockInSessionModel.fromJson(Map<String, dynamic> json) {
    return StockInSessionModel(
      id: (json['id'] as num).toInt(),
      supplierId: (json['supplier_id'] as num).toInt(),
      sessionNo: (json['session_no'] ?? '').toString(),
      doNumber: (json['do_number'] ?? '').toString(),
      stockInAt:
          DateTime.tryParse((json['stock_in_at'] ?? '').toString()) ??
              DateTime.now(),
      picUserId: (json['pic_user_id'] as num).toInt(),
      status: (json['status'] ?? 'draft').toString(),
      supplier: json['supplier'] is Map<String, dynamic>
          ? StockInSupplierBrief.fromJson(
              json['supplier'] as Map<String, dynamic>,
            )
          : null,
      picUser: json['pic_user'] is Map<String, dynamic>
          ? StockInUserBrief.fromJson(
              json['pic_user'] as Map<String, dynamic>,
            )
          : null,
      confirmedByUser: json['confirmed_by_user'] is Map<String, dynamic>
          ? StockInUserBrief.fromJson(
              json['confirmed_by_user'] as Map<String, dynamic>,
            )
          : null,
      remarks: json['remarks'] as String?,
      confirmedAt: DateTime.tryParse((json['confirmed_at'] ?? '').toString()),
      confirmedByUserId: (json['confirmed_by_user_id'] as num?)?.toInt(),
      itemsCount: (json['items_count'] as num?)?.toInt(),
      items: json['items'] is List
          ? (json['items'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map(StockInItemModel.fromJson)
              .toList()
          : null,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()),
    );
  }

  final int id;
  final int supplierId;
  final String sessionNo;
  final String doNumber;
  final DateTime stockInAt;
  final int picUserId;
  final String status;
  final StockInSupplierBrief? supplier;
  final StockInUserBrief? picUser;
  final StockInUserBrief? confirmedByUser;
  final String? remarks;
  final DateTime? confirmedAt;
  final int? confirmedByUserId;
  final int? itemsCount;
  final List<StockInItemModel>? items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDraft => status == 'draft';
  bool get isConfirmed => status == 'confirmed' || status == 'finalized';

  String get supplierName => supplier?.supplierName ?? '—';
  String get picUserName => picUser?.fullName ?? '—';
}
