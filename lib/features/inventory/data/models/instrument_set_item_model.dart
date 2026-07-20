import 'inventory_product_availability_model.dart';

class InstrumentSetItemModel {
  const InstrumentSetItemModel({
    required this.id,
    required this.instrumentSetId,
    required this.productId,
    required this.quantity,
    required this.sortOrder,
    this.remarks,
    this.product,
  });

  factory InstrumentSetItemModel.fromJson(Map<String, dynamic> json) {
    return InstrumentSetItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      instrumentSetId: (json['instrument_set_id'] as num?)?.toInt() ?? 0,
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      remarks: json['remarks'] as String?,
      product: json['product'] == null
          ? null
          : InventoryProductAvailabilityModel.fromJson(
              json['product'] as Map<String, dynamic>,
            ),
    );
  }

  final int id;
  final int instrumentSetId;
  final int productId;
  final int quantity;
  final int sortOrder;
  final String? remarks;
  final InventoryProductAvailabilityModel? product;
}
