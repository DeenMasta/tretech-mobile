/// Mirrors the Laravel PrintJobResource payload.
class PrintJobLotBrief {
  const PrintJobLotBrief({
    required this.id,
    required this.lotNumber,
    this.productRefNum,
    this.productName,
  });

  factory PrintJobLotBrief.fromJson(Map<String, dynamic> json) {
    final product = json['product'] is Map<String, dynamic>
        ? json['product'] as Map<String, dynamic>
        : null;
    return PrintJobLotBrief(
      id: (json['id'] as num).toInt(),
      lotNumber: (json['lot_number'] ?? '').toString(),
      productRefNum: product?['ref_num'] as String?,
      productName: product?['product_name'] as String?,
    );
  }

  final int id;
  final String lotNumber;
  final String? productRefNum;
  final String? productName;
}

enum PrintJobStatus { pending, printed, failed }

extension PrintJobStatusX on PrintJobStatus {
  String get label {
    switch (this) {
      case PrintJobStatus.pending:
        return 'Pending';
      case PrintJobStatus.printed:
        return 'Printed';
      case PrintJobStatus.failed:
        return 'Failed';
    }
  }

  static PrintJobStatus parse(String? raw) {
    switch (raw) {
      case 'printed':
        return PrintJobStatus.printed;
      case 'failed':
        return PrintJobStatus.failed;
      case 'pending':
      default:
        return PrintJobStatus.pending;
    }
  }
}

class PrintJobModel {
  const PrintJobModel({
    required this.id,
    required this.lotId,
    required this.actionType,
    required this.status,
    this.qrLabelId,
    this.reprintReason,
    this.printerName,
    this.deviceId,
    this.tsplPayload,
    this.errorMessage,
    this.requestedByUserId,
    this.requestedAt,
    this.printedAt,
    this.failedAt,
    this.lot,
  });

  factory PrintJobModel.fromJson(Map<String, dynamic> json) {
    return PrintJobModel(
      id: (json['id'] as num).toInt(),
      lotId: (json['lot_id'] as num).toInt(),
      actionType: (json['action_type'] ?? 'print').toString(),
      status: PrintJobStatusX.parse(json['status'] as String?),
      qrLabelId: (json['qr_label_id'] as num?)?.toInt(),
      reprintReason: json['reprint_reason'] as String?,
      printerName: json['printer_name'] as String?,
      deviceId: json['device_id'] as String?,
      tsplPayload: json['tspl_payload'] as String?,
      errorMessage: json['error_message'] as String?,
      requestedByUserId: (json['requested_by_user_id'] as num?)?.toInt(),
      requestedAt: DateTime.tryParse((json['requested_at'] ?? '').toString()),
      printedAt: DateTime.tryParse((json['printed_at'] ?? '').toString()),
      failedAt: DateTime.tryParse((json['failed_at'] ?? '').toString()),
      lot: json['lot'] is Map<String, dynamic>
          ? PrintJobLotBrief.fromJson(json['lot'] as Map<String, dynamic>)
          : null,
    );
  }

  final int id;
  final int lotId;
  final String actionType;
  final PrintJobStatus status;
  final int? qrLabelId;
  final String? reprintReason;
  final String? printerName;
  final String? deviceId;
  final String? tsplPayload;
  final String? errorMessage;
  final int? requestedByUserId;
  final DateTime? requestedAt;
  final DateTime? printedAt;
  final DateTime? failedAt;
  final PrintJobLotBrief? lot;
}
