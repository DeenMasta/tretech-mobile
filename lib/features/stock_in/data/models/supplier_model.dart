/// Lightweight supplier model used by the stock-in flow.
class SupplierModel {
  const SupplierModel({
    required this.id,
    required this.supplierName,
    this.phone,
    this.email,
    this.address,
    this.isActive = true,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: (json['id'] as num).toInt(),
      supplierName: (json['supplier_name'] ?? json['name'] ?? '').toString(),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }

  final int id;
  final String supplierName;
  final String? phone;
  final String? email;
  final String? address;
  final bool isActive;
}
