import 'instrument_set_item_model.dart';

class InventorySetAvailabilityModel {
  const InventorySetAvailabilityModel({
    required this.id,
    required this.setName,
    this.setCode,
    this.description,
    this.itemsCount,
    this.availableSetsCount,
    this.items,
  });

  factory InventorySetAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return InventorySetAvailabilityModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      setName: (json['set_name'] ?? '').toString(),
      setCode: json['set_code'] as String?,
      description: json['description'] as String?,
      itemsCount: (json['items_count'] as num?)?.toInt(),
      availableSetsCount: (json['available_sets_count'] as num?)?.toInt(),
      items: json['items'] == null
          ? null
          : (json['items'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map(InstrumentSetItemModel.fromJson)
              .toList(),
    );
  }

  final int id;
  final String setName;
  final String? setCode;
  final String? description;
  final int? itemsCount;
  final int? availableSetsCount;
  final List<InstrumentSetItemModel>? items;
}
