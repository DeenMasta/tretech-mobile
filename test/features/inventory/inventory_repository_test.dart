import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tretech_mobile/features/inventory/data/repositories/inventory_repository.dart';

void main() {
  group('InventoryRepository', () {
    late Dio dio;
    late InventoryRepository repository;
    late RequestOptions? request;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            request = options;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                data: const <String, dynamic>{'data': <dynamic>[]},
              ),
            );
          },
        ),
      );
      repository = InventoryRepository(dio);
    });

    test(
      'maps inventory unit pagination and filters to query parameters',
      () async {
        await repository.listInventoryUnits(
          search: '  suture  ',
          status: 'available',
          supplierId: 4,
          productId: 8,
          instrumentSetId: 12,
          expiryFrom: '2026-01-01',
          expiryTo: '2026-12-31',
          page: 3,
          perPage: 50,
        );

        expect(request!.path, '/api/v1/inventory-units');
        expect(request!.queryParameters, {
          'page': 3,
          'per_page': 50,
          'search': '  suture  ',
          'status': 'available',
          'supplier_id': 4,
          'product_id': 8,
          'instrument_set_id': 12,
          'expiry_from': '2026-01-01',
          'expiry_to': '2026-12-31',
        });
      },
    );

    test('omits blank optional filters from ledger queries', () async {
      await repository.listLedger(
        lotNumber: '  ',
        movementType: '',
        page: 2,
        perPage: 100,
      );

      expect(request!.path, '/api/v1/inventory-ledger');
      expect(request!.queryParameters, {
        'page': 2,
        'per_page': 100,
        'lot_id': null,
        'lot_number': null,
        'movement_type': null,
        'from_date': null,
        'to_date': null,
      });
    });

    test('uses encoded lot and reference values in lookup paths', () async {
      await repository.lookupByLot('LOT / 42');
      expect(
        request!.path,
        '/api/v1/inventory-units/lookup/by-lot/LOT%20%2F%2042',
      );

      await repository.lookupByRef('REF / 9');
      expect(
        request!.path,
        '/api/v1/inventory-units/lookup/by-ref/REF%20%2F%209',
      );
    });
  });
}
