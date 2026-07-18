class ClientBrief {
  const ClientBrief({required this.id, required this.name});
  factory ClientBrief.fromJson(Map<String, dynamic> json) => ClientBrief(
    id: (json['id'] as num).toInt(),
    name: (json['client_name'] ?? '').toString(),
  );
  final int id;
  final String name;
}

class ConsignmentLot {
  const ConsignmentLot({
    required this.id,
    required this.lotNumber,
    required this.status,
    this.productName,
    this.productType,
    this.refNum,
    this.expiryDate,
    this.quantityAvailable,
  });
  factory ConsignmentLot.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return ConsignmentLot(
      id: (json['id'] as num).toInt(),
      lotNumber: (json['lot_number'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      productName: product?['product_name']?.toString(),
      productType: product?['product_type']?.toString(),
      refNum: product?['ref_num']?.toString(),
      expiryDate: DateTime.tryParse((json['expiry_date'] ?? '').toString()),
      quantityAvailable: (json['quantity_available'] as num?)?.toInt(),
    );
  }
  final int id;
  final String lotNumber;
  final String status;
  final String? productName;
  final String? productType;
  final String? refNum;
  final DateTime? expiryDate;
  final int? quantityAvailable;
  String get label =>
      '$lotNumber - ${productName ?? '-'}${refNum?.isNotEmpty == true ? ' ($refNum)' : ''}${quantityAvailable == null ? '' : ' [Qty: $quantityAvailable]'}';
}

class ConsignmentItem {
  const ConsignmentItem({
    required this.id,
    required this.entryKind,
    this.lot,
    this.instrumentSetId,
    this.instrumentSetName,
    this.instrumentSetCode,
    this.instrumentSetItems = const [],
    required this.proposedQuantity,
    required this.quantity,
    this.remarks,
  });
  factory ConsignmentItem.fromJson(Map<String, dynamic> json) {
    final set = json['instrument_set'] as Map<String, dynamic>?;
    return ConsignmentItem(
      id: (json['id'] as num).toInt(),
      entryKind: (json['entry_kind'] ?? 'lot').toString(),
      lot: json['lot'] is Map<String, dynamic>
          ? ConsignmentLot.fromJson(json['lot'] as Map<String, dynamic>)
          : null,
      instrumentSetId: (json['instrument_set_id'] as num?)?.toInt(),
      instrumentSetName: set?['set_name']?.toString(),
      instrumentSetCode: set?['set_code']?.toString(),
      instrumentSetItems:
          (set?['items'] as List<dynamic>? ??
                  set?['components'] as List<dynamic>? ??
                  const [])
              .whereType<Map<String, dynamic>>()
              .map(
                (e) =>
                    '${e['name'] ?? e['product_name'] ?? '-'} x ${e['quantity'] ?? 0}',
              )
              .toList(),
      proposedQuantity: (json['proposed_quantity'] as num?)?.toInt() ?? 1,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      remarks: json['remarks']?.toString(),
    );
  }
  final int id;
  final String entryKind;
  final ConsignmentLot? lot;
  final int? instrumentSetId;
  final String? instrumentSetName;
  final String? instrumentSetCode;
  final List<String> instrumentSetItems;
  final int proposedQuantity;
  final int quantity;
  final String? remarks;
  bool get isSet => entryKind == 'set';
}

class ConsignmentModel {
  const ConsignmentModel({
    required this.id,
    required this.number,
    required this.status,
    this.client,
    required this.consignmentAt,
    this.picName,
    this.remarks,
    this.itemsCount,
    this.confirmedAt,
    this.confirmedBy,
    this.editedAfterConfirmation = false,
    this.lastEditAt,
    this.lastEditedBy,
    this.lastEditReason,
  });
  factory ConsignmentModel.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;
    final pic = json['pic_user'] as Map<String, dynamic>?;
    final confirmed = json['confirmed_by_user'] as Map<String, dynamic>?;
    final lastEditor =
        json['last_post_confirm_edit_by_user'] as Map<String, dynamic>?;
    return ConsignmentModel(
      id: (json['id'] as num).toInt(),
      number: (json['consignment_no'] ?? '').toString(),
      status: (json['status'] ?? 'draft').toString(),
      client: client == null ? null : ClientBrief.fromJson(client),
      consignmentAt:
          DateTime.tryParse((json['consignment_at'] ?? '').toString()) ??
          DateTime.now(),
      picName: pic?['full_name']?.toString(),
      remarks: json['remarks']?.toString(),
      itemsCount: (json['items_count'] as num?)?.toInt(),
      confirmedAt: DateTime.tryParse((json['confirmed_at'] ?? '').toString()),
      confirmedBy: confirmed?['full_name']?.toString(),
      editedAfterConfirmation: json['edited_after_confirmation'] == true,
      lastEditAt: DateTime.tryParse(
        (json['last_post_confirm_edit_at'] ?? '').toString(),
      ),
      lastEditedBy: lastEditor?['full_name']?.toString(),
      lastEditReason: json['last_post_confirm_edit_reason']?.toString(),
    );
  }
  final int id;
  final String number;
  final String status;
  final ClientBrief? client;
  final DateTime consignmentAt;
  final String? picName;
  final String? remarks;
  final int? itemsCount;
  final DateTime? confirmedAt;
  final String? confirmedBy;
  final bool editedAfterConfirmation;
  final DateTime? lastEditAt;
  final String? lastEditedBy;
  final String? lastEditReason;
  bool get isDraft => status == 'draft';
  bool get isConfirmed => status == 'confirmed';
}

class ConsignmentPage {
  const ConsignmentPage({
    required this.items,
    required this.total,
    required this.lastPage,
  });
  final List<ConsignmentModel> items;
  final int total;
  final int lastPage;
}
