import 'package:flutter_test/flutter_test.dart';
import 'package:tretech_mobile/core/utils/qr_payload_parser.dart';

void main() {
  group('QrPayloadParser.lotNumberOrRaw', () {
    test('extracts a lot number from the current compact QR payload', () {
      expect(
        QrPayloadParser.lotNumberOrRaw(
          'V=1;REF=IMP-003;LOT=LOT-123;MFG=2026-01-01;EXP=2031-01-01',
        ),
        'LOT-123',
      );
    });

    test('extracts a lot number from a legacy JSON payload', () {
      expect(
        QrPayloadParser.lotNumberOrRaw('{"lot_number":"LOT-456"}'),
        'LOT-456',
      );
    });

    test('preserves ordinary search text', () {
      expect(
        QrPayloadParser.lotNumberOrRaw('Surgical Needle'),
        'Surgical Needle',
      );
    });
  });
}
