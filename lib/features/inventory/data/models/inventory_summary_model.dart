class InventorySummaryModel {
  const InventorySummaryModel({
    required this.total,
    required this.available,
    required this.holding,
    required this.supplied,
    required this.used,
    required this.disposed,
  });

  factory InventorySummaryModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) => (value as num?)?.toInt() ?? 0;

    return InventorySummaryModel(
      total: toInt(json['total']),
      available: toInt(json['available']),
      holding: toInt(json['holding']),
      supplied: toInt(json['supplied']),
      used: toInt(json['used']),
      disposed: toInt(json['disposed']),
    );
  }

  final int total;
  final int available;
  final int holding;
  final int supplied;
  final int used;
  final int disposed;
}
