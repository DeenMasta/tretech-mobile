import 'package:flutter_test/flutter_test.dart';
import 'package:tretech_mobile/features/returns/data/models/return_session_model.dart';

void main() {
  test('parses component lot numbers from reconciliation results', () {
    final item = ReconciliationItem.fromJson({
      'id': 9,
      'instrument_results': [
        {
          'id': 21,
          'product_id': 5,
          'lot_numbers': ['COMP-LOT-001'],
          'expected_quantity': 2,
          'returned_quantity': 1,
          'used_quantity': 1,
          'remarks': 'Damaged packaging',
          'product': {'product_name': 'Femoral component', 'ref_num': 'FC-1'},
        },
      ],
    });

    expect(item.instrumentResults, hasLength(1));
    expect(item.instrumentResults.single.productName, 'Femoral component');
    expect(item.instrumentResults.single.lotNumbers, ['COMP-LOT-001']);
    expect(item.instrumentResults.single.expectedQuantity, 2);
    expect(item.instrumentResults.single.remarks, 'Damaged packaging');
  });
}
