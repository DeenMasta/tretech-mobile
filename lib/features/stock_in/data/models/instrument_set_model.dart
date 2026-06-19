class InstrumentSetComponentModel {
  const InstrumentSetComponentModel({
    required this.id,
    required this.name,
    this.code,
    required this.quantity,
    required this.type,
  });

  factory InstrumentSetComponentModel.fromJson(Map<String, dynamic> json) {
    return InstrumentSetComponentModel(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      code: json['code'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      type: (json['type'] ?? 'product').toString(),
    );
  }

  final int id;
  final String name;
  final String? code;
  final int quantity;
  final String type;
}

class InstrumentSetModel {
  const InstrumentSetModel({
    required this.id,
    this.setCode,
    required this.setName,
    this.description,
    this.isActive = true,
    this.items = const [],
  });

  factory InstrumentSetModel.fromJson(Map<String, dynamic> json) {
    return InstrumentSetModel(
      id: (json['id'] as num).toInt(),
      setCode: json['set_code'] as String?,
      setName: (json['set_name'] ?? '').toString(),
      description: json['description'] as String?,
      isActive: (json['is_active'] as bool?) ?? true,
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(InstrumentSetComponentModel.fromJson)
          .toList(),
    );
  }

  final int id;
  final String? setCode;
  final String setName;
  final String? description;
  final bool isActive;
  final List<InstrumentSetComponentModel> items;

  String get displayLabel {
    final code = setCode?.trim();
    if (code == null || code.isEmpty) {
      return setName;
    }
    return '$code - $setName';
  }
}
