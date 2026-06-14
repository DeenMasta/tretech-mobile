class DashboardTrendPoint {
  const DashboardTrendPoint({
    required this.date,
    required this.transactionCount,
    required this.totalQty,
  });

  factory DashboardTrendPoint.fromJson(Map<String, dynamic> json) =>
      DashboardTrendPoint(
        date: json['date'] as String,
        transactionCount: (json['transaction_count'] as num).toInt(),
        totalQty: (json['total_qty'] as num).toInt(),
      );

  final String date;
  final int transactionCount;
  final int totalQty;
}

// ── Top moved product ────────────────────────────────────────────────────────

class DashboardTopProduct {
  const DashboardTopProduct({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.movedQty,
  });

  factory DashboardTopProduct.fromJson(Map<String, dynamic> json) =>
      DashboardTopProduct(
        productId: (json['product_id'] as num).toInt(),
        productName: json['product_name'] as String,
        productCode: (json['product_code'] as String?) ?? '',
        movedQty: (json['moved_qty'] as num).toInt(),
      );

  final int productId;
  final String productName;
  final String productCode;
  final int movedQty;
}

// ── Lot counts ───────────────────────────────────────────────────────────────

class DashboardLotCounts {
  const DashboardLotCounts({
    required this.available,
    required this.holding,
    required this.supplied,
    required this.used,
    required this.disposed,
    required this.returnedToSupplier,
    required this.total,
  });

  factory DashboardLotCounts.fromJson(Map<String, dynamic> json) =>
      DashboardLotCounts(
        available: (json['available'] as num).toInt(),
        holding: (json['holding'] as num).toInt(),
        supplied: (json['supplied'] as num).toInt(),
        used: (json['used'] as num).toInt(),
        disposed: (json['disposed'] as num).toInt(),
        returnedToSupplier: (json['returned_to_supplier'] as num).toInt(),
        total: (json['total'] as num).toInt(),
      );

  final int available;
  final int holding;
  final int supplied;
  final int used;
  final int disposed;
  final int returnedToSupplier;
  final int total;
}

// ── Operations pipeline ──────────────────────────────────────────────────────

class DashboardOperationsPipeline {
  const DashboardOperationsPipeline({
    required this.stockInDraft,
    required this.stockInFinalizedToday,
    required this.consignmentDraft,
    required this.consignmentConfirmedToday,
    required this.returnSessionsInProgress,
    required this.reconciliationPending,
    required this.disposalDraft,
    required this.supplierReturnDraft,
  });

  factory DashboardOperationsPipeline.fromJson(Map<String, dynamic> json) =>
      DashboardOperationsPipeline(
        stockInDraft: (json['stock_in_draft'] as num).toInt(),
        stockInFinalizedToday:
            (json['stock_in_finalized_today'] as num).toInt(),
        consignmentDraft: (json['consignment_draft'] as num).toInt(),
        consignmentConfirmedToday:
            (json['consignment_confirmed_today'] as num).toInt(),
        returnSessionsInProgress:
            (json['return_sessions_in_progress'] as num).toInt(),
        reconciliationPending:
            (json['reconciliation_pending'] as num).toInt(),
        disposalDraft: (json['disposal_draft'] as num).toInt(),
        supplierReturnDraft: (json['supplier_return_draft'] as num).toInt(),
      );

  final int stockInDraft;
  final int stockInFinalizedToday;
  final int consignmentDraft;
  final int consignmentConfirmedToday;
  final int returnSessionsInProgress;
  final int reconciliationPending;
  final int disposalDraft;
  final int supplierReturnDraft;
}

// ── Today's activity ─────────────────────────────────────────────────────────

class DashboardTodayActivity {
  const DashboardTodayActivity({
    required this.stockInCount,
    required this.consignedCount,
    required this.returnedCount,
    required this.usedCount,
    required this.disposedCount,
    required this.returnedToSupplierCount,
    required this.holdingReleasedCount,
    required this.movementsTotal,
  });

  factory DashboardTodayActivity.fromJson(Map<String, dynamic> json) =>
      DashboardTodayActivity(
        stockInCount: (json['stock_in_count'] as num).toInt(),
        consignedCount: (json['consigned_count'] as num).toInt(),
        returnedCount: (json['returned_count'] as num).toInt(),
        usedCount: (json['used_count'] as num).toInt(),
        disposedCount: (json['disposed_count'] as num).toInt(),
        returnedToSupplierCount:
            (json['returned_to_supplier_count'] as num).toInt(),
        holdingReleasedCount:
            (json['holding_released_count'] as num).toInt(),
        movementsTotal: (json['movements_total'] as num).toInt(),
      );

  final int stockInCount;
  final int consignedCount;
  final int returnedCount;
  final int usedCount;
  final int disposedCount;
  final int returnedToSupplierCount;
  final int holdingReleasedCount;
  final int movementsTotal;
}

// ── Alerts ───────────────────────────────────────────────────────────────────

class DashboardAlerts {
  const DashboardAlerts({
    required this.holdingLotsPending,
    required this.expiringSoon30Days,
    required this.overdueStockInDrafts,
    required this.reconciliationPending,
  });

  factory DashboardAlerts.fromJson(Map<String, dynamic> json) =>
      DashboardAlerts(
        holdingLotsPending: (json['holding_lots_pending'] as num).toInt(),
        expiringSoon30Days: (json['expiring_soon_30_days'] as num).toInt(),
        overdueStockInDrafts:
            (json['overdue_stock_in_drafts'] as num).toInt(),
        reconciliationPending:
            (json['reconciliation_pending'] as num).toInt(),
      );

  final int holdingLotsPending;
  final int expiringSoon30Days;
  final int overdueStockInDrafts;
  final int reconciliationPending;
}

// ── Root ─────────────────────────────────────────────────────────────────────

class DashboardSummary {
  const DashboardSummary({
    required this.lotCounts,
    required this.operationsPipeline,
    required this.todayActivity,
    required this.alerts,
    required this.lowStockRiskCount,
    required this.stockInTrend,
    required this.consignmentTrend,
    required this.topMovedProducts,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      lotCounts: DashboardLotCounts.fromJson(
        json['lot_counts'] as Map<String, dynamic>,
      ),
      operationsPipeline: DashboardOperationsPipeline.fromJson(
        json['operations_pipeline'] as Map<String, dynamic>,
      ),
      todayActivity: DashboardTodayActivity.fromJson(
        json['today_activity'] as Map<String, dynamic>,
      ),
      alerts: DashboardAlerts.fromJson(
        json['alerts'] as Map<String, dynamic>,
      ),
      lowStockRiskCount: (json['low_stock_risk_count'] as num).toInt(),
      stockInTrend: (json['stock_in_trend'] as List<dynamic>)
          .map((e) =>
              DashboardTrendPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      consignmentTrend: (json['consignment_trend'] as List<dynamic>)
          .map((e) =>
              DashboardTrendPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      topMovedProducts: (json['top_moved_products'] as List<dynamic>)
          .map((e) =>
              DashboardTopProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final DashboardLotCounts lotCounts;
  final DashboardOperationsPipeline operationsPipeline;
  final DashboardTodayActivity todayActivity;
  final DashboardAlerts alerts;
  final int lowStockRiskCount;
  final List<DashboardTrendPoint> stockInTrend;
  final List<DashboardTrendPoint> consignmentTrend;
  final List<DashboardTopProduct> topMovedProducts;
}
