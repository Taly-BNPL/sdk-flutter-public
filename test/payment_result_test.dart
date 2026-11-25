import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sdk_flutter/sdk_flutter.dart';

/// `toJson` must always produce valid JSON that cannot be changed by the values it carries.
void main() {
  group('PaymentSuccess.toJson', () {
    test('a quote in a value cannot add or override a key', () {
      const injected = 'x","status":"CONFIRMED';
      const result = PaymentSuccess(
        merchantOrderId: injected,
        status: 'REJECTED',
      );

      final decoded = jsonDecode(result.toJson()) as Map<String, dynamic>;

      expect(decoded['status'], 'REJECTED');
      expect(decoded['merchantOrderId'], injected);
    });

    test('quotes, backslashes, newlines and Arabic text round-trip unchanged', () {
      const name = 'Al "Main" \\ branch\nفرع';
      const result = PaymentSuccess(
        branchName: name,
        merchantName: name,
        psp: PaymentSuccessPsp(subMerchantName: name, pspProvider: 'p"q'),
      );

      final decoded = jsonDecode(result.toJson()) as Map<String, dynamic>;

      expect(decoded['branchName'], name);
      expect(decoded['merchantName'], name);
      expect((decoded['PSP'] as Map)['subMerchantName'], name);
      expect((decoded['PSP'] as Map)['pspProvider'], 'p"q');
    });

    test('missing values are JSON null, not the text "null"', () {
      final decoded = jsonDecode(const PaymentSuccess().toJson()) as Map<String, dynamic>;

      expect(decoded['orderToken'], isNull);
      expect(decoded['status'], isNull);
      expect(decoded['totalAmount'], isNull);
      expect(decoded['PSP'], isNull);
    });

    test('keeps the existing keys, including PSP', () {
      final decoded = jsonDecode(const PaymentSuccess().toJson()) as Map<String, dynamic>;

      expect(decoded.keys.toSet(), {
        'orderToken', 'branchId', 'orderDate', 'status', 'paymentPlanId',
        'redirectUrl', 'paymentPlanName', 'branchType', 'branchName',
        'settlementType', 'totalReturnAmount', 'totalRefundAmount',
        'merchantId', 'merchantName', 'currency', 'talyOrderId',
        'merchantOrderId', 'totalAmount', 'settlementStatus', 'postBackUrl',
        'merchantLogo', 'PSP',
      });
    });

    test('numbers and booleans keep their types; values from the channel map are kept', () {
      final result = PaymentSuccess.fromMap({
        'talyOrderId': 42,
        'branchId': '7',
        'totalAmount': 12.5,
        'status': 'CONFIRMED',
        'psp': {'isPspOrder': true, 'subMerchantId': 3},
      });

      final decoded = jsonDecode(result.toJson()) as Map<String, dynamic>;

      expect(decoded['talyOrderId'], 42);
      expect(decoded['branchId'], 7);
      expect(decoded['totalAmount'], 12.5);
      expect(decoded['status'], 'CONFIRMED');
      expect((decoded['PSP'] as Map)['isPspOrder'], true);
      expect((decoded['PSP'] as Map)['subMerchantId'], 3);
    });

    test('a NaN amount does not make toJson throw', () {
      final result = PaymentSuccess.fromMap({'totalAmount': 'NaN', 'totalRefundAmount': 'Infinity'});

      final decoded = jsonDecode(result.toJson()) as Map<String, dynamic>;

      expect(decoded['totalAmount'], isNull);
      expect(decoded['totalRefundAmount'], isNull);
    });

    test('toString wraps the same valid JSON', () {
      const result = PaymentSuccess(status: 'a"b');
      final s = result.toString();

      expect(s.startsWith('PaymentSuccess('), isTrue);
      final json = s.substring('PaymentSuccess('.length, s.length - 1);
      expect((jsonDecode(json) as Map)['status'], 'a"b');
    });
  });

  group('PaymentError.toJson', () {
    test('a quote in a value cannot add or override a key', () {
      const error = PaymentError(
        status: 'FAILED',
        message: 'bad","status":"OK',
        errors: ['first "one"', 'second\\two'],
        errorCode: 'E1',
      );

      final decoded = jsonDecode(error.toJson()) as Map<String, dynamic>;

      expect(decoded['status'], 'FAILED');
      expect(decoded['message'], 'bad","status":"OK');
      expect(decoded['errors'], ['first "one"', 'second\\two']);
      expect(decoded['errorCode'], 'E1');
      expect(decoded['merchantOrderId'], isNull);
    });

    test('keeps the existing keys', () {
      final decoded = jsonDecode(const PaymentError().toJson()) as Map<String, dynamic>;

      expect(decoded.keys.toSet(),
          {'status', 'message', 'errors', 'errorCode', 'merchantOrderId'});
      expect(decoded['errors'], isEmpty);
    });
  });
}
