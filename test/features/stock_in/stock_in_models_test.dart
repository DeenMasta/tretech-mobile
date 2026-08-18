import 'package:flutter_test/flutter_test.dart';
import 'package:tretech_mobile/features/stock_in/data/models/lot_model.dart';
import 'package:tretech_mobile/features/stock_in/data/models/instrument_set_model.dart';
import 'package:tretech_mobile/features/stock_in/data/models/product_model.dart';
import 'package:tretech_mobile/features/stock_in/data/models/stock_in_item_model.dart';

void main() {
  group('InstrumentSetModel', () {
    test('parses available set units', () {
      final set = InstrumentSetModel.fromJson({
        'id': 8,
        'set_code': 'SET-GEN-01',
        'set_name': 'General Surgery Starter Set',
        'available_sets_count': 4,
      });

      expect(set.availableSetsCount, 4);
    });
  });

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
      expect(item.instrumentSet?.items.single.instrumentSetItemId, 1);
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

    test('parses set component lot decisions', () {
      final item = StockInItemModel.fromJson({
        'id': 14,
        'stock_in_id': 4,
        'entry_kind': 'set',
        'instrument_set_id': 8,
        'quantity': 1,
        'component_lots': [
          {
            'instrument_set_item_id': 31,
            'lot_number': 'COMP-LOT-001',
            'generate_lot_number': false,
          },
          {
            'instrument_set_item_id': 32,
            'lot_number': null,
            'generate_lot_number': true,
          },
        ],
      });

      expect(item.componentLots, hasLength(2));
      expect(item.componentLots.first.instrumentSetItemId, 31);
      expect(item.componentLots.first.lotNumber, 'COMP-LOT-001');
      expect(item.componentLots.last.generateLotNumber, isTrue);
    });
  });

  group('LotModel', () {
    test('parses the full finalized-lot result for display', () {
      final lot = LotModel.fromJson({
        'id': 54,
        'supplier_id': 3,
        'product_id': 2,
        'product': {
          'id': 2,
          'ref_num': 'PRD-002',
          'product_name': 'Suture Pack',
        },
        'lot_number': 'LOT-2026-001',
        'manufacturing_date': '2026-01-01',
        'expiry_date': '2028-01-01',
        'quantity': 8,
        'quantity_available': 6,
        'is_system_generated_lot': true,
        'status': 'available',
      });

      expect(lot.productLabel, 'PRD-002 - Suture Pack');
      expect(lot.manufacturingDate, DateTime(2026, 1, 1));
      expect(lot.expiryDate, DateTime(2028, 1, 1));
      expect(lot.displayedQuantity, 6);
      expect(lot.isSystemGeneratedLot, isTrue);
    });

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

  group('ProductModel', () {
    test('always enables lot tracking for instrument products', () {
      final product = ProductModel.fromJson({
        'id': 8,
        'ref_num': 'INS-008',
        'product_name': 'Surgical Instrument',
        'product_type': ' Instrument ',
        'requires_lot': false,
      });

      expect(product.isInstrumentProduct, isTrue);
      expect(product.requiresLot, isTrue);
    });
  });
}
