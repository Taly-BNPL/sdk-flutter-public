import 'package:flutter/services.dart';
import 'enums/environment.dart';
import 'enums/log_level.dart';
import 'models/initiate_payment_model.dart';
import 'models/installment_model.dart';
import 'models/payment_result.dart';

class TalyFlutterSdk {
  TalyFlutterSdk._();

  static const _channel = MethodChannel('io.taly.sdk/taly');
  static bool _listenerAttached = false;

  static Environment _environment = Environment.production;

  static Environment get environment => _environment;

  static String _languageCode = 'en';

  static String get languageCode => _languageCode;

  static void Function(PaymentSuccess)? onPaymentSuccess;

  static void Function(PaymentFailure)? onPaymentFailure;

  static void Function(PaymentError)? onPaymentError;

  static void _attachListener() {
    if (_listenerAttached) return;
    _listenerAttached = true;

    _channel.setMethodCallHandler((call) async {
      final args = (call.arguments as Map<Object?, Object?>?) ?? {};
      switch (call.method) {
        case 'onPaymentSuccess':
          onPaymentSuccess?.call(PaymentSuccess.fromMap(args));
          break;
        case 'onPaymentFailure':
          onPaymentFailure?.call(PaymentFailure.fromMap(args));
          break;
        case 'onPaymentError':
          onPaymentError?.call(PaymentError.fromMap(args));
          break;
      }
    });
  }

  /// [oauthScope] / [oauthGrantType] are used on **iOS** for [TokenRequest] (Taly docs: `scope: "api"`).
  /// Android ignores them; the native Android SDK sets OAuth internally.
  static Future<void> initialize({
    required String userName,
    required String password,
    Environment environment = Environment.production,
    String oauthGrantType = 'password',
    String oauthScope = 'api',
  }) async {
    _environment = environment;

    await _channel.invokeMethod<void>('initialize', {
      'userName': userName,
      'password': password,
      'environment': environment.value,
      'oauthGrantType': oauthGrantType,
      'oauthScope': oauthScope,
    });

    await setLogLevel(LogLevel.verbose);

    _attachListener();
  }

  static Future<void> initiatePayment(InitiatePaymentModel model) async {
    await _channel.invokeMethod<void>('initiatePayment', model.toMap());
  }

  static Future<List<InstallmentModel>> fetchInstallments({
    required String name,
    required int quantity,
    required String amount,
    required String currency,
  }) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'fetchInstallments',
      {
        'name': name,
        'quantity': quantity,
        'amount': amount,
        'currency': currency,
      },
    );
    return (result ?? [])
        .cast<Map<Object?, Object?>>()
        .map(InstallmentModel.fromMap)
        .toList();
  }

  static Future<void> setPrimaryColor(int colorInt) async {
    await _channel.invokeMethod<void>('setPrimaryColor', {'color': colorInt});
  }

  static Future<void> setLanguageCode(String code) async {
    _languageCode = code;
    await _channel.invokeMethod<void>('setLanguageCode', {'code': code});
  }

  static Future<void> setLogLevel(LogLevel level) async {
    await _channel.invokeMethod<void>('setLogLevel', {'level': level.name});
  }
}
