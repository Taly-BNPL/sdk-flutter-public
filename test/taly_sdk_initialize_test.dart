import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdk_flutter/sdk_flutter.dart';

/// Verifies what `TalyFlutterSdk.initialize` sends to the native side (Android and iOS share it).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('io.taly.sdk/taly');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Map<Object?, Object?> initializeArgs() =>
      calls.firstWhere((c) => c.method == 'initialize').arguments as Map<Object?, Object?>;

  test('sends client credentials when provided', () async {
    await TalyFlutterSdk.initialize(
      userName: 'user',
      password: 'pass',
      environment: Environment.development,
      clientId: 'mapi_abc',
      clientSecret: 'secret',
    );

    final args = initializeArgs();
    expect(args['clientId'], 'mapi_abc');
    expect(args['clientSecret'], 'secret');
    expect(args['userName'], 'user');
    expect(args['password'], 'pass');
    expect(args['environment'], Environment.development.value);
  });

  test('does not change the log level (the integrator decides)', () async {
    await TalyFlutterSdk.initialize(userName: 'user', password: 'pass');

    expect(calls.where((c) => c.method == 'setLogLevel'), isEmpty);
  });

  test('setLogLevel still sends the chosen level', () async {
    await TalyFlutterSdk.setLogLevel(LogLevel.none);

    expect(calls.single.method, 'setLogLevel');
    expect(calls.single.arguments, {'level': 'none'});
  });

  test('existing calls without client credentials are unchanged (backward compatible)', () async {
    await TalyFlutterSdk.initialize(userName: 'user', password: 'pass');

    final args = initializeArgs();
    expect(args.containsKey('clientId'), isFalse);
    expect(args.containsKey('clientSecret'), isFalse);
    expect(
      args.keys.toSet(),
      {'userName', 'password', 'environment', 'oauthGrantType', 'oauthScope'},
    );
  });
}
