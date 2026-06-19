import 'package:flutter_test/flutter_test.dart';
import 'package:tretech_mobile/features/stock_in/data/models/lot_model.dart';
import 'package:tretech_mobile/features/stock_in/data/models/stock_in_item_model.dart';

void main() {
  group('StockInItemModel', () {
    test('parses set entries with instrument set details', () {
      final item = StockInItemModel.fromJson({
        'id': 12,
        'stock_in_id': 4,
        'entry_kind': 'set',
        'product_id': null,
        'instrument_set_id': 8,
        'instrument_set': {
          'id': 8,
          'set_code': 'SET-GEN-01',
          'set_name': 'General Surgery Starter Set',
          'items': [
            {
              'id': 1,
              'name': 'Scalpel',
              'code': 'INS-01',
              'quantity': 2,
              'type': 'instrument',
            },
          ],
        },
        'supplier_batch_code': null,
        'lot': null,
      });

      expect(item.isSetEntry, isTrue);
      expect(item.productId, isNull);
      expect(item.instrumentSetId, 8);
      expect(item.productLabel, 'SET-GEN-01 - General Surgery Starter Set');
      expect(item.lotLabel, 'Minted on finalize');
      expect(item.instrumentSet?.items.length, 1);
    });

    test('flags product items without scanned lots for auto-generation', () {
      final item = StockInItemModel.fromJson({
        'id': 13,
        'stock_in_id': 4,
        'entry_kind': 'product',
        'product_id': 2,
        'product': {
          'id': 2,
          'ref_num': 'PRD-002',
          'product_name': 'Suture Pack',
        },
        'supplier_batch_code': 'BATCH-01',
        'missing_lot_flag': false,
        'scanned_lot_number': null,
        'lot': null,
      });

      expect(item.isProductEntry, isTrue);
      expect(item.willAutoGenerateLot, isTrue);
      expect(item.lotLabel, 'Auto-generate on finalize');
    });
  });

  group('LotModel', () {
    test('parses finalized set lots with nullable product ids', () {
      final lot = LotModel.fromJson({
        'id': 55,
        'product_id': null,
        'instrument_set_id': 8,
        'supplier_id': 3,
        'lot_number': 'SET-SET-GEN-01-20260619-0001',
        'status': 'available',
      });

      expect(lot.productId, isNull);
      expect(lot.instrumentSetId, 8);
      expect(lot.lotNumber, contains('SET-GEN-01'));
    });
  });
}
