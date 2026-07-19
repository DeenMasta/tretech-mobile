import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tretech_mobile/features/disposal/data/repositories/disposal_repository.dart';

void main() {
  group('DisposalRepository', () {
    late DisposalRepository repository;
    late RequestOptions? request;

    setUp(() {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            request = options;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                data: const {
                  'data': <dynamic>[],
                  'pagination': <String, dynamic>{},
                },
              ),
            );
          },
        ),
      );
      repository = DisposalRepository(dio);
    });

    test('maps list filters and pagination', () async {
      await repository.list(
        search: 'TDS26',
        status: 'draft',
        fromDate: '2026-01-01',
        toDate: '2026-01-31',
        page: 2,
        perPage: 50,
      );
      expect(request!.path, '/api/v1/disposals');
      expect(request!.queryParameters, {
        'page': 2,
        'per_page': 50,
        'search': 'TDS26',
        'status': 'draft',
        'from_date': '2026-01-01',
        'to_date': '2026-01-31',
      });
    });

    test('posts the backend disposal item payload', () async {
      await repository.addItem(
        7,
        lotId: 9,
        quantity: 2,
        category: 'damaged',
        reasonText: 'Damaged pack',
        remarks: '  outer carton torn  ',
      );
      expect(request!.path, '/api/v1/disposals/7/items');
      expect(request!.method, 'POST');
      expect(request!.data, {
        'lot_id': 9,
        'quantity': 2,
        'disposal_category': 'damaged',
        'reason_text': 'Damaged pack',
        'remarks': 'outer carton torn',
      });
    });

    test('uses the complete endpoint', () async {
      await repository.complete(13);
      expect(request!.path, '/api/v1/disposals/13/complete');
      expect(request!.method, 'POST');
    });
  });
}
