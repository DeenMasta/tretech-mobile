import 'package:flutter_test/flutter_test.dart';
import 'package:tretech_mobile/features/consignment/data/models/consignment_models.dart';

void main() {
  group('ConsignmentItem', () {
    test('parses tracked lot numbers for instrument set components', () {
      final item = ConsignmentItem.fromJson({
        'id': 12,
        'entry_kind': 'set',
        'proposed_quantity': 1,
        'quantity': 1,
        'instrument_set': {
          'id': 3,
          'set_code': 'SET-001',
          'set_name': 'Knee set',
          'components': [
            {
              'id': 7,
              'product_id': 22,
              'product_name': 'Tibial tray',
              'ref_num': 'TT-01',
              'quantity': 1,
              'lot_numbers': ['COMP-LOT-001', 'COMP-LOT-002'],
            },
          ],
        },
      });

      expect(item.isSet, isTrue);
      expect(item.instrumentSetComponents, hasLength(1));
      expect(item.instrumentSetComponents.single.productName, 'Tibial tray');
      expect(item.instrumentSetComponents.single.lotNumbers, [
        'COMP-LOT-001',
        'COMP-LOT-002',
      ]);
      expect(
        item.instrumentSetItems.single,
        'Tibial tray x 1 (TT-01) — Lots: COMP-LOT-001, COMP-LOT-002',
      );
    });
  });
}
