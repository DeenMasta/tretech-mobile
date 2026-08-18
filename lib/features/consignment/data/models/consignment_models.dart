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

class ConsignmentInstrumentSetComponent {
  const ConsignmentInstrumentSetComponent({
    required this.id,
    required this.productId,
    required this.productName,
    this.refNum,
    required this.quantity,
    this.lotNumbers = const [],
  });

  factory ConsignmentInstrumentSetComponent.fromJson(
    Map<String, dynamic> json,
  ) => ConsignmentInstrumentSetComponent(
    id: (json['id'] as num?)?.toInt() ?? 0,
    productId: (json['product_id'] as num?)?.toInt() ?? 0,
    productName: (json['product_name'] ?? json['name'] ?? '-').toString(),
    refNum: (json['ref_num'] ?? json['code'])?.toString(),
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    lotNumbers: (json['lot_numbers'] as List<dynamic>? ?? const [])
        .map((lotNumber) => lotNumber.toString())
        .where((lotNumber) => lotNumber.isNotEmpty)
        .toList(),
  );

  final int id;
  final int productId;
  final String productName;
  final String? refNum;
  final int quantity;
  final List<String> lotNumbers;

  String get label =>
      '$productName x $quantity${refNum?.isNotEmpty == true ? ' ($refNum)' : ''}';
}

class ConsignmentItem {
  const ConsignmentItem({
    required this.id,
    required this.entryKind,
    this.lot,
    this.instrumentSetId,
    this.instrumentSetName,
    this.instrumentSetCode,
    this.instrumentSetComponents = const [],
    required this.proposedQuantity,
    required this.quantity,
    this.remarks,
  });
  factory ConsignmentItem.fromJson(Map<String, dynamic> json) {
    final set = json['instrument_set'] as Map<String, dynamic>?;
    final components =
        (set?['components'] as List<dynamic>? ??
                set?['items'] as List<dynamic>? ??
                const [])
            .whereType<Map<String, dynamic>>()
            .map(ConsignmentInstrumentSetComponent.fromJson)
            .toList();
    return ConsignmentItem(
      id: (json['id'] as num).toInt(),
      entryKind: (json['entry_kind'] ?? 'lot').toString(),
      lot: json['lot'] is Map<String, dynamic>
          ? ConsignmentLot.fromJson(json['lot'] as Map<String, dynamic>)
          : null,
      instrumentSetId: (json['instrument_set_id'] as num?)?.toInt(),
      instrumentSetName: set?['set_name']?.toString(),
      instrumentSetCode: set?['set_code']?.toString(),
      instrumentSetComponents: components,
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
  final List<ConsignmentInstrumentSetComponent> instrumentSetComponents;
  final int proposedQuantity;
  final int quantity;
  final String? remarks;

  List<String> get componentSummaries => instrumentSetComponents.map((
    component,
  ) {
    final reference = component.refNum?.trim();
    final lots = component.lotNumbers;
    final label =
        '${component.productName}${reference?.isNotEmpty == true ? ' ($reference)' : ''} x ${component.quantity * quantity}';

    return lots.isEmpty ? label : '$label — Lots: ${lots.join(', ')}';
  }).toList();

  List<String> get instrumentSetItems => instrumentSetComponents
      .map(
        (component) =>
            '${component.label}${component.lotNumbers.isEmpty ? '' : ' — Lots: ${component.lotNumbers.join(', ')}'}',
      )
      .toList();

  bool get isSet => entryKind == 'set';
}

class ConsignmentModel {
  const ConsignmentModel({
    required this.id,
    required this.number,
    required this.status,
    this.client,
    required this.consignmentAt,
    this.picUserId,
    this.picName,
    this.surgeonName,
    this.caseDate,
    this.caseName,
    this.remarks,
    this.itemsCount,
    this.confirmedAt,
    this.confirmedBy,
  });
  factory ConsignmentModel.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;
    final pic = json['pic_user'] as Map<String, dynamic>?;
    final confirmed = json['confirmed_by_user'] as Map<String, dynamic>?;
    return ConsignmentModel(
      id: (json['id'] as num).toInt(),
      number: (json['consignment_no'] ?? '').toString(),
      status: (json['status'] ?? 'draft').toString(),
      client: client == null ? null : ClientBrief.fromJson(client),
      consignmentAt:
          DateTime.tryParse((json['consignment_at'] ?? '').toString()) ??
          DateTime.now(),
      picUserId:
          (json['pic_user_id'] as num?)?.toInt() ??
          (pic?['id'] as num?)?.toInt(),
      picName: pic?['full_name']?.toString(),
      surgeonName: json['surgeon_name']?.toString(),
      caseDate: DateTime.tryParse((json['case_date'] ?? '').toString()),
      caseName: json['case_name']?.toString(),
      remarks: json['remarks']?.toString(),
      itemsCount: (json['items_count'] as num?)?.toInt(),
      confirmedAt: DateTime.tryParse((json['confirmed_at'] ?? '').toString()),
      confirmedBy: confirmed?['full_name']?.toString(),
    );
  }
  final int id;
  final String number;
  final String status;
  final ClientBrief? client;
  final DateTime consignmentAt;
  final int? picUserId;
  final String? picName;
  final String? surgeonName;
  final DateTime? caseDate;
  final String? caseName;
  final String? remarks;
  final int? itemsCount;
  final DateTime? confirmedAt;
  final String? confirmedBy;
  bool get isDraft => status == 'draft';
  bool get isConfirmed => status == 'confirmed';
}

class ConsignmentPage {
  const ConsignmentPage({
    required this.items,
    required this.total,
    required this.lastPage,
    required this.currentPage,
  });
  final List<ConsignmentModel> items;
  final int total;
  final int lastPage;
  final int currentPage;
}
