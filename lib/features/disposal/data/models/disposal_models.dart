class DisposalUserBrief {
  const DisposalUserBrief({
    required this.id,
    required this.fullName,
    this.email,
  });

  factory DisposalUserBrief.fromJson(Map<String, dynamic> json) =>
      DisposalUserBrief(
        id: (json['id'] as num?)?.toInt() ?? 0,
        fullName: (json['full_name'] ?? '').toString(),
        email: json['email'] as String?,
      );
  final int id;
  final String fullName;
  final String? email;
}

class DisposalLotBrief {
  const DisposalLotBrief({
    required this.id,
    required this.lotNumber,
    required this.status,
    this.expiryDate,
    this.quantityAvailable,
    this.productName,
    this.refNum,
    this.supplierName,
  });
  factory DisposalLotBrief.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final supplier = json['supplier'] as Map<String, dynamic>?;
    return DisposalLotBrief(
      id: (json['id'] as num?)?.toInt() ?? 0,
      lotNumber: (json['lot_number'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      expiryDate: DateTime.tryParse((json['expiry_date'] ?? '').toString()),
      quantityAvailable: (json['quantity_available'] as num?)?.toInt(),
      productName: product?['product_name']?.toString(),
      refNum: product?['ref_num']?.toString(),
      supplierName: supplier?['supplier_name']?.toString(),
    );
  }
  final int id;
  final String lotNumber;
  final String status;
  final DateTime? expiryDate;
  final int? quantityAvailable;
  final String? productName;
  final String? refNum;
  final String? supplierName;
}

class DisposalItemModel {
  const DisposalItemModel({
    required this.id,
    required this.disposalId,
    required this.lotId,
    required this.quantity,
    required this.disposalCategory,
    required this.reasonText,
    this.lot,
    this.remarks,
    this.createdAt,
  });
  factory DisposalItemModel.fromJson(Map<String, dynamic> json) =>
      DisposalItemModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        disposalId: (json['disposal_id'] as num?)?.toInt() ?? 0,
        lotId: (json['lot_id'] as num?)?.toInt() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        disposalCategory: (json['disposal_category'] ?? '').toString(),
        reasonText: (json['reason_text'] ?? '').toString(),
        lot: json['lot'] is Map<String, dynamic>
            ? DisposalLotBrief.fromJson(json['lot'] as Map<String, dynamic>)
            : null,
        remarks: json['remarks'] as String?,
        createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      );
  final int id;
  final int disposalId;
  final int lotId;
  final int quantity;
  final String disposalCategory;
  final String reasonText;
  final DisposalLotBrief? lot;
  final String? remarks;
  final DateTime? createdAt;
}

class DisposalModel {
  const DisposalModel({
    required this.id,
    required this.disposalNo,
    required this.status,
    required this.picUserId,
    this.disposedAt,
    this.remarks,
    this.picUser,
    this.completedAt,
    this.completedByUserId,
    this.completedByUser,
    this.itemsCount,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });
  factory DisposalModel.fromJson(Map<String, dynamic> json) => DisposalModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    disposalNo: (json['disposal_no'] ?? '').toString(),
    status: (json['status'] ?? '').toString(),
    picUserId: (json['pic_user_id'] as num?)?.toInt() ?? 0,
    disposedAt: DateTime.tryParse((json['disposed_at'] ?? '').toString()),
    remarks: json['remarks'] as String?,
    picUser: json['pic_user'] is Map<String, dynamic>
        ? DisposalUserBrief.fromJson(json['pic_user'] as Map<String, dynamic>)
        : null,
    completedAt: DateTime.tryParse((json['completed_at'] ?? '').toString()),
    completedByUserId: (json['completed_by_user_id'] as num?)?.toInt(),
    completedByUser: json['completed_by_user'] is Map<String, dynamic>
        ? DisposalUserBrief.fromJson(
            json['completed_by_user'] as Map<String, dynamic>,
          )
        : null,
    itemsCount: (json['disposal_items_count'] as num?)?.toInt(),
    items: (json['disposal_items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DisposalItemModel.fromJson)
        .toList(),
    createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()),
  );
  final int id;
  final String disposalNo;
  final String status;
  final int picUserId;
  final DateTime? disposedAt;
  final String? remarks;
  final DisposalUserBrief? picUser;
  final DateTime? completedAt;
  final int? completedByUserId;
  final DisposalUserBrief? completedByUser;
  final int? itemsCount;
  final List<DisposalItemModel> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  bool get isDraft => status == 'draft';
}

class DisposalPage {
  const DisposalPage({
    required this.items,
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });
  final List<DisposalModel> items;
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
}
