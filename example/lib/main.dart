// =============================================================================
// Taly Flutter SDK — worked integration example
// =============================================================================
//
// Every Taly touchpoint below is marked with an `SDK STEP n` banner (or an
// `SDK ·` note); everything else is ordinary Flutter UI / validation you can
// replace with your own. Two payment flows are shown: a FULL order that fills
// in every optional field, and a REQUIRED-ONLY order with the bare minimum.
//
// The integration is 4 SDK steps:
//   STEP 1  initialize()        authenticate once at startup
//   STEP 2  configure (opt.)    log level / language
//   STEP 3  register callbacks  success / failure / error (static, set once)
//   STEP 4  initiatePayment()   build an order, open native checkout
// ...plus the optional TalyBannerView widget that previews the installment plan.
//
// Prerequisites (outside this file):
//   * pubspec.yaml: depend on the package (the key must be `sdk_flutter`), e.g.
//         sdk_flutter:
//           git: { url: https://github.com/Taly-BNPL/Flutter-SDK.git }
//   * iOS:     ios/Podfile -> platform :ios, '13.0'   then `pod install`
//   * Android: app build.gradle -> minSdk 21+   (INTERNET permission + payment
//              activities are merged in from the plugin's own manifest)
//   * Native binaries must ship in the plugin: taly-sdk-release.aar + TalySdk.xcframework
// =============================================================================

import 'dart:developer';
import 'package:flutter/material.dart';

// Single barrel import: exposes TalyFlutterSdk, TalyBannerView, and every model
// (InitiatePaymentModel, OrderItem, PSP, CustomerDetails, DeliveryAddress) and
// enum (Environment, LogLevel). You never import the individual SDK files.
import 'package:sdk_flutter/sdk_flutter.dart';

void main() async {
  // Needed because we await async SDK calls before runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // == SDK STEP 1 · Initialize ================================================
  // Call once, before runApp(), and await it. It authenticates your merchant
  // credentials with Taly, turns on logging, and opens the native -> Dart
  // channel that later delivers payment results to the STEP 3 callbacks.
  await TalyFlutterSdk.initialize(
    userName:    'YOUR_USER_NAME',      // your merchant username
    password:    'YOUR_PASSWORD',      // your merchant PASSWORD
    environment: Environment.development, // sandbox; use Environment.production when live
  );

  // == SDK STEP 2 · Optional configuration ====================================
  await TalyFlutterSdk.setLogLevel(LogLevel.verbose); // SDK log verbosity
  await TalyFlutterSdk.setLanguageCode('en');         // 'en' or 'ar'

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taly SDK Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  final _amountController  = TextEditingController();
  final _orderIdController = TextEditingController();

  String  _amount       = '';
  final String  _orderId      = '';
  bool    _radioChecked = false;
  bool    _bannerVisible = false;
  String _bannerAmount  = '';

  String? _amountError;

  @override
  void initState() {
    super.initState();

    _amountController.addListener(() {
      if (_amountController.text != _amount) {
        _clearAll();
      }
    });

    // == SDK STEP 3 · Result callbacks ========================================
    // These are STATIC on TalyFlutterSdk (global), so set them ONCE. After the
    // native checkout closes, the SDK fires EXACTLY ONE of them:
    //   onPaymentSuccess -> PaymentSuccess (approved) · fields incl. talyOrderId,
    //                       status, totalAmount; .toJson() for the full payload
    //   onPaymentFailure -> PaymentSuccess (declined / cancelled; same shape —
    //                       PaymentFailure is just a typedef of PaymentSuccess)
    //   onPaymentError   -> PaymentError (network / auth / bad request) ·
    //                       .message, .errorCode, .errors, .toJson()
    // This is where a real app updates its order state / shows a receipt.
    TalyFlutterSdk.onPaymentSuccess = (result) {
      log('onPaymentSuccess: $result', name: 'talySDK');
      _clearAll();
      _showPopup('Success', result.toJson());
    };

    TalyFlutterSdk.onPaymentFailure = (failure) {
      log('onPaymentFailure: $failure', name: 'talySDK');
      _clearAll();
      _showPopup('Failure', failure.toJson());
    };

    TalyFlutterSdk.onPaymentError = (error) {
      log('onPaymentError: $error', name: 'talySDK');
      _clearAll();
      _showPopup('Error', error.toJson());
    };
  }

  @override
  void dispose() {
    _amountController.dispose();
    _orderIdController.dispose();
    super.dispose();
  }

  void _validate() {
    final raw = _amountController.text.trim();
    FocusScope.of(context).unfocus();

    if (raw.isEmpty) {
      setState(() => _amountError = 'Amount is Empty');
      return;
    }
    if (raw == '.') {
      setState(() => _amountError = 'Enter valid amount');
      return;
    }
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      setState(() => _amountError = 'Amount cannot be less than 1');
      return;
    }

    setState(() {
      _amountError  = null;
      _amount       = raw;
      _radioChecked = true;
    });

    _setupSDK(_amount);
  }

  // Reveals the TalyBannerView (see build()). The banner itself calls Taly to
  // fetch the installment plan for this amount — no extra wiring needed.
  void _setupSDK(String amount) {
    setState(() {
      _bannerAmount  = amount;
      _bannerVisible = true;
    });
  }

  // == SDK STEP 4a · Start a payment (FULL payload) ===========================
  // Every optional field is filled in here. Only 7 are actually REQUIRED (see
  // the tags): merchantOrderId, subTotal, totalAmount, currency, deliveryMethod,
  // merchantRedirectUrl, orderItems. The result arrives via the STEP 3
  // callbacks — initiatePayment() itself returns nothing.
  Future<void> _initiatePaymentFull() async {
    if (_amount.isEmpty || !_radioChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the payment option..')),
      );
      return;
    }

    // Your own order id (used for reconciliation); fall back to a timestamp.
    final merchantOrderId = _orderIdController.text.trim().isNotEmpty
        ? _orderIdController.text.trim()
        : DateTime.now().millisecondsSinceEpoch.toString();

    await TalyFlutterSdk.initiatePayment(
      InitiatePaymentModel(
        merchantOrderId:     merchantOrderId,          // REQUIRED · your unique order id
        language:            'en',                     // optional · per-order language override
        merchantBranch:      'salmiya',                // optional · originating store/branch
        subTotal:             double.parse(_amount),   // REQUIRED · items total before fees
        totalAmount:          double.parse(_amount),   // REQUIRED · final amount charged
        currency:             'KWD',                   // REQUIRED · ISO currency code
        discountAmount:       0.0,                     // optional · defaults to 0
        taxAmount:            0.0,                      // optional · defaults to 0
        deliveryAmount:       0.0,                      // optional · defaults to 0
        deliveryMethod:       'home delivery',          // REQUIRED
        otherFees:            0.0,                       // optional · defaults to 0
        // REQUIRED · URL the checkout returns to when finished:
        merchantRedirectUrl:  'https://yourmerchant.com/checkout/',
        // optional · server-to-server webhook Taly calls to confirm the order:
        postBackUrl:          'https://yourmerchant.com/yourWebhookEndpoint/',
        // optional · logo shown on the checkout screen:
        merchantLogo:         'https://www.yourmerchant.com/media/merchantLogo.png',
        // optional block · include ONLY if you route through a payment service
        // provider; omit the whole `psp:` argument otherwise:
        psp: const PSP(
          isPspOrder:      true,
          pspProvider:     'Tap',
          subMerchantId:   1234,
          subMerchantName: 'Test',
        ),
        orderItems: [                                  // REQUIRED · at least one item
          OrderItem(
            sku:                   '23433312436',      // REQUIRED · product SKU
            type:                  'physical',         // optional · e.g. physical / digital
            name:                  'blue shirt 998',   // REQUIRED · English name
            nameArabic:            'القميص الأزرق 998', // REQUIRED · Arabic name
            currency:              'KWD',              // REQUIRED
            itemDescription:       't-shirt made of cotton',        // optional
            itemDescriptionArabic: 'تي شيرت مصنوع من القطن',        // optional
            quantity:               1,                 // REQUIRED
            itemPrice:              double.parse(_amount), // REQUIRED · price per unit
            imageUrl:              'https://www.merchantwebsite.com/item1image.jpg', // optional
            itemUrl:               'https://www.merchantwebsite.com/item1.html',     // optional
            itemUnit:              'gm',               // optional
            itemSize:              '32',               // optional
            itemColor:             'blue',             // optional
            itemGender:            'men',              // optional
            itemBrand:             'Adidas',           // optional
            itemCategory:          'Men>Men\'s Wear>Running', // optional
          ),
        ],
        // optional block · buyer info; improves approval + prefills checkout:
        customerDetails: const CustomerDetails(
          firstName:       'Ahmad',
          lastName:        'Ali',
          gender:          'Male',
          countryCode:     '+965',
          phoneNumber:     '55555333',
          customerEmail:   'user@example.com',
          registeredSince: '2022-10-26',
          loyaltyMember:   true,
          loyaltyLevel:    'VIP',
        ),
        // optional block · where the order ships:
        deliveryAddress: const DeliveryAddress(
          city:          'Hawalli',
          area:          'Salmiya',
          fullAddress:   'Hawalli, Salmiya, block 5, building 5, floor 2, flat 6',
          phoneNumber:   '502223333',
          customerEmail: 'user@example.com',
        ),
      ),
    );
  }

  // == SDK STEP 4b · Start a payment (REQUIRED-ONLY payload) ===================
  // The smallest valid order — just the 7 required fields. (The three amount
  // fields below are optional and only kept here for clarity.)
  Future<void> _initiatePaymentRequiredOnly() async {
    if (_amount.isEmpty || !_radioChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the payment option..')),
      );
      return;
    }

    final merchantOrderId = _orderIdController.text.trim().isNotEmpty
        ? _orderIdController.text.trim()
        : DateTime.now().millisecondsSinceEpoch.toString();

    await TalyFlutterSdk.initiatePayment(
      InitiatePaymentModel(
        merchantOrderId:    merchantOrderId,           // REQUIRED
        subTotal:            double.parse(_amount),     // REQUIRED
        totalAmount:         double.parse(_amount),     // REQUIRED
        currency:            'KWD',                     // REQUIRED
        discountAmount:      0.0,                        // optional
        taxAmount:           0.0,                        // optional
        deliveryAmount:      0.0,                        // optional
        deliveryMethod:      'home delivery',            // REQUIRED
        merchantRedirectUrl: 'https://yourmerchant.com/checkout/', // REQUIRED
        orderItems: [                                   // REQUIRED
          OrderItem(
            sku:        '23433312436',                 // REQUIRED
            name:       'blue shirt 998',              // REQUIRED
            nameArabic: 'القميص الأزرق 998',           // REQUIRED
            currency:   'KWD',                         // REQUIRED
            quantity:    1,                            // REQUIRED
            itemPrice:   double.parse(_amount),        // REQUIRED · price per unit
          ),
        ],
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _radioChecked  = false;
      _amount        = '';
      _bannerVisible = false;
      _bannerAmount  = '';
    });
  }

  String _formatString(String text) {
    final json        = StringBuffer();
    String indent     = '';

    for (final ch in text.characters) {
      switch (ch) {
        case '{':
        case '[':
          json.write('\n$indent$ch\n');
          indent += '\t';
          json.write(indent);
        case '}':
        case ']':
          indent = indent.replaceFirst('\t', '');
          json.write('\n$indent$ch');
        case ',':
          json.write(',\n$indent');
        default:
          json.write(ch);
      }
    }

    return json.toString();
  }

  void _showPopup(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            _formatString(message),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize:   13,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ordinary Flutter layout. The only SDK widget here is TalyBannerView
    // (flagged inline); the two buttons call the two STEP 4 flows above.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taly SDK Example'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              TextField(
                controller:  _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText:   'Amount',
                  hintText:    'Enter amount',
                  errorText:   _amountError,
                  prefixText:  'KWD ',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller:  _orderIdController,
                decoration: const InputDecoration(
                  labelText: 'Order ID (optional)',
                  hintText:  'Leave empty to auto-generate',
                  border:    OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _validate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _radioChecked
                          ? const Color(0xFF1565C0)
                          : Colors.grey.shade300,
                      width: _radioChecked ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: _radioChecked
                        ? const Color(0xFFE3F2FD)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Radio<bool>(
                        value:         true,
                        groupValue:    _radioChecked,
                        onChanged:     (_) => _validate(),
                        activeColor:   const Color(0xFF1565C0),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'taly Pay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Image.network(
                        'https://taly.io/favicon.ico',
                        width:  32,
                        height: 32,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.account_balance_wallet,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // == SDK · Promotional banner (optional) ========================
              // Give it amount + currency and it calls Taly to fetch the plan,
              // then renders "Split into N payments of ...". It manages its own
              // loading + error states. onInfoClicked hands you a URL for a
              // "how it works" sheet when the info icon is tapped.
              if (_bannerVisible && _bannerAmount.isNotEmpty)
                TalyBannerView(
                  amount:   _bannerAmount,
                  currency: 'KWD',
                  onInfoClicked: (url) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title:   const Text('How it works'),
                        content: Text(url),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 30),
              // Triggers the FULL-payload payment (STEP 4a).
              ElevatedButton(
                onPressed: _initiatePaymentFull,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding:         const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Pay Now (Full)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),

              // Triggers the REQUIRED-ONLY payment (STEP 4b).
              OutlinedButton(
                onPressed: _initiatePaymentRequiredOnly,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1565C0),
                  side:            const BorderSide(color: Color(0xFF1565C0)),
                  padding:         const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Pay Now (Required Only)',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}