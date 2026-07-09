# Flutter SDKs

You can easily integrate your Apps with our Flutter SDKs

## Introduction

The **Taly Flutter SDK** enables you to integrate the Taly Payment Gateway into your Flutter application for both Android and iOS platforms. It exposes a clean Dart API backed by native platform channels, so your Flutter code remains fully cross-platform while Taly's native iOS and Android SDKs handle all payment logic under the hood.

The typical integration workflow is:

1. **Initialize** — Authenticate with your merchant credentials before your app renders any UI.
2. **Initiate Payment** — Build an order model and hand it off to the SDK to launch the native payment screen.
3. **Handle Results** — Listen to `onPaymentSuccess`, `onPaymentFailure`, and `onPaymentError` callbacks.
4. **Banner** *(optional)* — Drop `TalyBannerView` onto any product screen to show "split into 4 payments" messaging automatically.

***

## Requirements

| Requirement           | Minimum Version  |
| --------------------- | ---------------- |
| Flutter               | `>=3.10.0`       |
| Dart SDK              | `>=3.0.0 <4.0.0` |
| iOS deployment target | 13.0+            |
| Android minSdkVersion | 21+              |

***

## Installation

Add `sdk_flutter` to your project's `pubspec.yaml`:

```yaml
dependencies:
  sdk_flutter:
    git:
      url: https://github.com/Taly-BNPL/sdk-flutter-public.git
```

Then fetch the package:

```bash
flutter pub get
```

### iOS — Additional Setup

The Taly Flutter SDK wraps the native Taly iOS SDK (`.xcframework`). After running `flutter pub get`, navigate to the `ios` directory and install the CocoaPods dependencies:

```bash
cd ios && pod install
```

If the native framework requires manual embedding, open `ios/Runner.xcworkspace` in Xcode:

1. Drag & drop `TalySdk.xcframework` into your project's target.
2. Set the embedding to **Embed & Sign** in the target's *Frameworks, Libraries, and Embedded Content* section.

### Android — Additional Setup

The Taly Android SDK requires `minSdkVersion` 26. In `android/app/build.gradle.kts`, set:

```kotlin
android {
    defaultConfig {
        minSdk = 26
    }
}
```

## Setup SDK

### Import the Package

In every Dart file where you use the SDK, add the import:

```dart
import 'package:sdk_flutter/sdk_flutter.dart';
```

***

## Usage

The example app bundled with the SDK (`example/lib/main.dart`) is a simple online shopping demo that highlights end-to-end integration. The steps below mirror that workflow.

### 1. Initialize TalyFlutterSdk

Call `TalyFlutterSdk.initialize()` **once**, as early as possible — ideally before `runApp()` in `main()`. You need:

* **userName** — Your merchant username for authentication.
* **password** — Your merchant password for authentication.
* **environment** — `Environment.development` for testing, `Environment.production` for live.

```dart
import 'package:flutter/material.dart';
import 'package:sdk_flutter/sdk_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TalyFlutterSdk.initialize(
    userName:    'YOUR_USER_NAME',
    password:    'YOUR_PASSWORD',
    environment: Environment.development, // or Environment.production
  );

  runApp(const MyApp());
}
```

> **Note for iOS only:** The `oauthGrantType` and `oauthScope` parameters correspond to the iOS native `TokenRequest` (`grantType: "password"`, `scope: "api"`). Android sets OAuth internally and ignores these values. The defaults (`'password'` and `'api'`) match the Taly iOS SDK requirements and do not need to be changed under normal circumstances.

***

### 2. Register Payment Callbacks

After initialization, assign the static callback handlers so your app receives payment outcomes. These can be set anywhere — `initState()` of your checkout screen is a common place:

```dart
@override
void initState() {
  super.initState();

  TalyFlutterSdk.onPaymentSuccess = (PaymentSuccess result) {
    // Handle successful payment
    print('Payment succeeded: ${result.talyOrderId}');
  };

  TalyFlutterSdk.onPaymentFailure = (PaymentFailure failure) {
    // Handle a failed payment (e.g. user cancelled, card declined)
    print('Payment failed: ${failure.status}');
  };

  TalyFlutterSdk.onPaymentError = (PaymentError error) {
    // Handle SDK/network errors
    print('Payment error: ${error.message}');
  };
}
```

***

### 3. Initiate Payment

Build an `InitiatePaymentModel` and call `TalyFlutterSdk.initiatePayment()`. The SDK will launch the native Taly payment screen on top of your Flutter app.

#### Full Example (all fields)

```dart
await TalyFlutterSdk.initiatePayment(
  InitiatePaymentModel(
    merchantOrderId:    DateTime.now().millisecondsSinceEpoch.toString(),
    language:           'en',
    merchantBranch:     'main',
    subTotal:            15.000,
    totalAmount:         15.000,
    currency:            'KWD',
    discountAmount:      0.0,
    taxAmount:           0.0,
    deliveryAmount:      0.0,
    deliveryMethod:      'home delivery',
    otherFees:           0.0,
    isDigitalOrder:      false,
    merchantRedirectUrl: 'https://yourmerchant.com/checkout/',
    postBackUrl:         'https://yourmerchant.com/yourWebhookEndpoint/',
    merchantLogo:        'https://www.yourmerchant.com/media/merchantLogo.png',
    psp: const PSP(
      isPspOrder:      true,
      pspProvider:     'Tap',
      subMerchantId:   1234,
      subMerchantName: 'My Store',
    ),
    orderItems: [
      OrderItem(
        sku:                   '23433312436',
        type:                  'physical',
        name:                  'Blue Shirt',
        nameArabic:            'القميص الأزرق',
        currency:              'KWD',
        itemDescription:       'T-shirt made of cotton',
        itemDescriptionArabic: 'تي شيرت مصنوع من القطن',
        quantity:               1,
        itemPrice:              15.000,
        imageUrl:              'https://www.merchantwebsite.com/item1image.jpg',
        itemUrl:               'https://www.merchantwebsite.com/item1.html',
        itemUnit:              'gm',
        itemSize:              '32',
        itemColor:             'blue',
        itemGender:            'men',
        itemBrand:             'Adidas',
        itemCategory:          'Men>Men\'s Wear>Running',
      ),
    ],
    customerDetails: const CustomerDetails(
      firstName:       'Ahmad',
      lastName:        'Ali',
      gender:          'Male',
      countryCode:     '+965',
      phoneNumber:     '55555333',
      customerEmail:   'ahmad@example.com',
      registeredSince: '2022-10-26',
      loyaltyMember:   true,
      loyaltyLevel:    'VIP',
    ),
    deliveryAddress: const DeliveryAddress(
      city:          'Hawalli',
      area:          'Salmiya',
      fullAddress:   'Hawalli, Salmiya, block 5, building 5, floor 2, flat 6',
      phoneNumber:   '502223333',
      customerEmail: 'ahmad@example.com',
    ),
  ),
);
```

#### Minimal Example (required fields only)

```dart
await TalyFlutterSdk.initiatePayment(
  InitiatePaymentModel(
    merchantOrderId:    DateTime.now().millisecondsSinceEpoch.toString(),
    subTotal:            15.000,
    totalAmount:         15.000,
    currency:            'KWD',
    deliveryMethod:      'home delivery',
    merchantRedirectUrl: 'https://yourmerchant.com/checkout/',
    orderItems: [
      OrderItem(
        sku:        '23433312436',
        name:       'Blue Shirt',
        nameArabic: 'القميص الأزرق',
        currency:   'KWD',
        quantity:    1,
        itemPrice:   15.000,
      ),
    ],
  ),
);
```

***

### 4. Product Banner View

`TalyBannerView` is a Flutter widget you can embed in any product detail screen. It automatically fetches installment data from the Taly API and displays a "Split into 4 payments of KWD X.XXX" message, reinforcing Taly as a payment option at the point of consideration.

```dart
TalyBannerView(
  amount:   '15.000',   // Product price as a string
  currency: 'KWD',
  name:     'Blue Shirt',  // optional product name
  quantity: 1,             // optional quantity
  onInfoClicked: (String url) {
    // Called when the user taps the ⓘ info button
    // url is always 'https://Taly.io/how-it-works'
    // Open a WebView, launch a URL, or show a dialog
    launchUrl(Uri.parse(url));
  },
)
```

The widget manages its own state and automatically re-fetches when `amount`, `currency`, or `quantity` props change. It renders one of three states:

| State       | Description                                         |
| ----------- | --------------------------------------------------- |
| **Loading** | A circular progress indicator while fetching        |
| **Banner**  | Installment messaging with the Taly logo            |
| **Error**   | An error icon with a "Something went wrong" message |

> **Prerequisite:** `TalyFlutterSdk.initialize()` must be called before rendering `TalyBannerView`.

***

### 5. Fetch Installments (Manual)

If you need raw installment data to build your own custom banner UI, call `fetchInstallments()` directly:

```dart
final List<InstallmentModel> installments = await TalyFlutterSdk.fetchInstallments(
  name:     'Blue Shirt',
  quantity: 1,
  amount:   '15.000',
  currency: 'KWD',
);

for (final inst in installments) {
  print('Installment ${inst.nbOfInstallment}: ${inst.currency} ${inst.amount} on ${inst.dueDate}');
}
```

***

## API Reference

### TalyFlutterSdk

The main entry point of the SDK. All members are **static** — do not instantiate this class.

```dart
class TalyFlutterSdk { ... }
```

#### Static Callbacks

| Property           | Type                             | Description                                                             |
| ------------------ | -------------------------------- | ----------------------------------------------------------------------- |
| `onPaymentSuccess` | `void Function(PaymentSuccess)?` | Invoked when a payment completes successfully.                          |
| `onPaymentFailure` | `void Function(PaymentFailure)?` | Invoked when a payment fails (e.g. card declined, user cancelled).      |
| `onPaymentError`   | `void Function(PaymentError)?`   | Invoked when an SDK or network error occurs during the payment process. |

#### Static Methods

##### `initialize()`

Authenticates with the Taly platform and sets up the native SDK on both iOS and Android. Must be awaited before calling any other SDK method.

```dart
static Future<void> initialize({
  required String userName,
  required String password,
  Environment environment = Environment.production,
  String oauthGrantType = 'password',
  String oauthScope = 'api',
})
```

| Parameter        | Type          | Required | Default                  | Description                                     |
| ---------------- | ------------- | -------- | ------------------------ | ----------------------------------------------- |
| `userName`       | `String`      | ✅        | —                        | Your merchant username.                         |
| `password`       | `String`      | ✅        | —                        | Your merchant password.                         |
| `environment`    | `Environment` | ❌        | `Environment.production` | Target environment.                             |
| `oauthGrantType` | `String`      | ❌        | `'password'`             | iOS only — OAuth grant type for `TokenRequest`. |
| `oauthScope`     | `String`      | ❌        | `'api'`                  | iOS only — OAuth scope for `TokenRequest`.      |

***

##### `initiatePayment()`

Launches the native Taly payment screen. Results are delivered via the `onPaymentSuccess`, `onPaymentFailure`, and `onPaymentError` callbacks.

```dart
static Future<void> initiatePayment(InitiatePaymentModel model)
```

| Parameter | Type                   | Required | Description                                                                |
| --------- | ---------------------- | -------- | -------------------------------------------------------------------------- |
| `model`   | `InitiatePaymentModel` | ✅        | The full order details. See [InitiatePaymentModel](#initiatepaymentmodel). |

***

##### `fetchInstallments()`

Retrieves the installment schedule for a given product and amount. Used internally by `TalyBannerView` and available for building custom banner UI.

```dart
static Future<List<InstallmentModel>> fetchInstallments({
  required String name,
  required int    quantity,
  required String amount,
  required String currency,
})
```

| Parameter  | Type     | Required | Description                                  |
| ---------- | -------- | -------- | -------------------------------------------- |
| `name`     | `String` | ✅        | Product name.                                |
| `quantity` | `int`    | ✅        | Product quantity. Must be > 0.               |
| `amount`   | `String` | ✅        | Product price as a string (e.g. `'15.000'`). |
| `currency` | `String` | ✅        | Currency code (e.g. `'KWD'`).                |

**Returns:** `Future<List<InstallmentModel>>` — An ordered list of installment details.

***

##### `setPrimaryColor()`

Overrides the primary accent color used in the Taly native payment screen.

```dart
static Future<void> setPrimaryColor(int colorInt)
```

| Parameter  | Type  | Description                                                               |
| ---------- | ----- | ------------------------------------------------------------------------- |
| `colorInt` | `int` | ARGB integer color value. Use `Color.value` from Flutter's `Color` class. |

**Example:**

```dart
await TalyFlutterSdk.setPrimaryColor(const Color(0xFF1565C0).value);
```

***

##### `setLanguageCode()`

Sets the display language for the native Taly payment screen.

```dart
static Future<void> setLanguageCode(String code)
```

| Parameter | Type     | Description                                                                |
| --------- | -------- | -------------------------------------------------------------------------- |
| `code`    | `String` | BCP 47 language code. Supported values: `'en'` (English), `'ar'` (Arabic). |

**Example:**

```dart
await TalyFlutterSdk.setLanguageCode('ar');
```

***

##### `setLogLevel()`

Controls the verbosity of SDK log output. Called automatically with `LogLevel.verbose` after `initialize()`.

```dart
static Future<void> setLogLevel(LogLevel level)
```

| Parameter | Type       | Description                                       |
| --------- | ---------- | ------------------------------------------------- |
| `level`   | `LogLevel` | Desired log verbosity. See [LogLevel](#loglevel). |

**Example:**

```dart
await TalyFlutterSdk.setLogLevel(LogLevel.error); // production builds
```

***

### TalyBannerView (Widget)

A Flutter `StatefulWidget` that displays a Taly installment banner on product screens. Internally calls `TalyFlutterSdk.fetchInstallments()` and re-fetches whenever its props change.

```dart
class TalyBannerView extends StatefulWidget {
  const TalyBannerView({
    super.key,
    this.name = '',
    this.quantity = 1,
    required this.amount,
    required this.currency,
    this.onInfoClicked,
  });
}
```

#### Properties

| Property        | Type                         | Required | Default | Description                                                                                           |
| --------------- | ---------------------------- | -------- | ------- | ----------------------------------------------------------------------------------------------------- |
| `amount`        | `String`                     | ✅        | —       | Product price as a string (e.g. `'15.000'`).                                                          |
| `currency`      | `String`                     | ✅        | —       | Currency code (e.g. `'KWD'`).                                                                         |
| `name`          | `String`                     | ❌        | `''`    | Product name, passed to the installments API.                                                         |
| `quantity`      | `int`                        | ❌        | `1`     | Product quantity, passed to the installments API.                                                     |
| `onInfoClicked` | `void Function(String url)?` | ❌        | `null`  | Called when the user taps the ⓘ icon. The `url` parameter is always `'https://Taly.io/how-it-works'`. |

***

### Models

#### InitiatePaymentModel

Represents a complete order passed to `TalyFlutterSdk.initiatePayment()`.

```dart
const InitiatePaymentModel({
  required String merchantOrderId,
  required double subTotal,
  required double totalAmount,
  required String currency,
  required String deliveryMethod,
  required List<OrderItem> orderItems,
  required String merchantRedirectUrl,
  String?  language,            // default: 'en'
  String?  merchantBranch,      // default: 'main'
  double   discountAmount,      // default: 0.0
  double   taxAmount,           // default: 0.0
  double   deliveryAmount,      // default: 0.0
  double?  otherFees,
  bool?    isDigitalOrder,      // default: false
  String?  postBackUrl,
  String?  merchantLogo,
  PSP      psp,                 // default: PSP()
  CustomerDetails customerDetails, // default: CustomerDetails()
  DeliveryAddress deliveryAddress, // default: DeliveryAddress()
})
```

| Field                 | Type              | Required | Default             | Description                                                                            |
| --------------------- | ----------------- | -------- | ------------------- | -------------------------------------------------------------------------------------- |
| `merchantOrderId`     | `String`          | ✅        | —                   | Your unique order ID. Recommended: `DateTime.now().millisecondsSinceEpoch.toString()`. |
| `subTotal`            | `double`          | ✅        | —                   | Order subtotal before discounts/fees.                                                  |
| `totalAmount`         | `double`          | ✅        | —                   | Final order total charged to the customer.                                             |
| `currency`            | `String`          | ✅        | —                   | ISO 4217 currency code (e.g. `'KWD'`).                                                 |
| `deliveryMethod`      | `String`          | ✅        | —                   | Delivery method description (e.g. `'home delivery'`).                                  |
| `orderItems`          | `List<OrderItem>` | ✅        | —                   | One or more items in the order.                                                        |
| `merchantRedirectUrl` | `String`          | ✅        | —                   | URL the SDK redirects to after payment completion.                                     |
| `language`            | `String?`         | ❌        | `'en'`              | Language code for the payment screen (`'en'` or `'ar'`).                               |
| `merchantBranch`      | `String?`         | ❌        | `'main'`            | Merchant branch identifier.                                                            |
| `discountAmount`      | `double`          | ❌        | `0.0`               | Total discount applied to the order.                                                   |
| `taxAmount`           | `double`          | ❌        | `0.0`               | Tax amount.                                                                            |
| `deliveryAmount`      | `double`          | ❌        | `0.0`               | Shipping / delivery fee.                                                               |
| `otherFees`           | `double?`         | ❌        | `null`              | Any additional fees.                                                                   |
| `isDigitalOrder`      | `bool?`           | ❌        | `false`             | Set to `true` for digital goods orders.                                                |
| `postBackUrl`         | `String?`         | ❌        | `null`              | Webhook endpoint for server-to-server order status notifications.                      |
| `merchantLogo`        | `String?`         | ❌        | `null`              | Publicly accessible URL of your merchant logo shown on the payment screen.             |
| `psp`                 | `PSP`             | ❌        | `PSP()`             | Payment Service Provider details.                                                      |
| `customerDetails`     | `CustomerDetails` | ❌        | `CustomerDetails()` | Customer demographic information.                                                      |
| `deliveryAddress`     | `DeliveryAddress` | ❌        | `DeliveryAddress()` | Customer delivery address.                                                             |

***

#### OrderItem

Represents a single product in an order.

| Field                   | Type      | Required | Default      | Description                                        |
| ----------------------- | --------- | -------- | ------------ | -------------------------------------------------- |
| `sku`                   | `String`  | ✅        | —            | Stock Keeping Unit — unique product identifier.    |
| `name`                  | `String`  | ✅        | —            | Product name in English.                           |
| `nameArabic`            | `String`  | ✅        | —            | Product name in Arabic.                            |
| `currency`              | `String`  | ✅        | —            | Currency code for this item (e.g. `'KWD'`).        |
| `quantity`              | `int`     | ✅        | —            | Number of units.                                   |
| `itemPrice`             | `double`  | ✅        | —            | Unit price.                                        |
| `type`                  | `String?` | ❌        | `'physical'` | Item type: `'physical'` or `'Digital'`.            |
| `itemDescription`       | `String?` | ❌        | `null`       | Product description in English.                    |
| `itemDescriptionArabic` | `String?` | ❌        | `null`       | Product description in Arabic.                     |
| `imageUrl`              | `String?` | ❌        | `null`       | Publicly accessible product image URL.             |
| `itemUrl`               | `String?` | ❌        | `null`       | Product page URL on your website.                  |
| `itemUnit`              | `String?` | ❌        | `null`       | Unit of measure (e.g. `'gm'`, `'kg'`).             |
| `itemSize`              | `String?` | ❌        | `null`       | Product size.                                      |
| `itemColor`             | `String?` | ❌        | `null`       | Product color.                                     |
| `itemGender`            | `String?` | ❌        | `null`       | Target gender (e.g. `'men'`, `'women'`, `'kids'`). |
| `itemBrand`             | `String?` | ❌        | `null`       | Brand name (e.g. `'Adidas'`).                      |
| `itemCategory`          | `String?` | ❌        | `null`       | Category path (e.g. `'Men>Men\'s Wear>Running'`).  |

***

#### CustomerDetails

Optional customer information sent with an order for fraud detection and analytics.

| Field             | Type      | Required | Description                                                          |
| ----------------- | --------- | -------- | -------------------------------------------------------------------- |
| `firstName`       | `String?` | ❌        | Customer's first name.                                               |
| `lastName`        | `String?` | ❌        | Customer's last name.                                                |
| `gender`          | `String?` | ❌        | Customer's gender (e.g. `'Male'`, `'Female'`).                       |
| `countryCode`     | `String?` | ❌        | Phone country code (e.g. `'+965'`).                                  |
| `phoneNumber`     | `String?` | ❌        | Customer's phone number (without country code).                      |
| `customerEmail`   | `String?` | ❌        | Customer's email address.                                            |
| `registeredSince` | `String?` | ❌        | Date the customer registered, ISO 8601 format (e.g. `'2022-10-26'`). |
| `loyaltyMember`   | `bool?`   | ❌        | Whether the customer is in a loyalty programme.                      |
| `loyaltyLevel`    | `String?` | ❌        | Loyalty tier name (e.g. `'VIP'`, `'Gold'`).                          |

***

#### DeliveryAddress

Optional delivery address sent with an order.

| Field           | Type      | Required | Description                                  |
| --------------- | --------- | -------- | -------------------------------------------- |
| `city`          | `String?` | ❌        | Delivery city (e.g. `'Hawalli'`).            |
| `area`          | `String?` | ❌        | Delivery area / district (e.g. `'Salmiya'`). |
| `fullAddress`   | `String?` | ❌        | Full street address.                         |
| `phoneNumber`   | `String?` | ❌        | Contact phone number for delivery.           |
| `customerEmail` | `String?` | ❌        | Contact email for delivery.                  |

***

#### PSP

Payment Service Provider information for PSP-routed orders.

| Field             | Type      | Required | Default | Description                                          |
| ----------------- | --------- | -------- | ------- | ---------------------------------------------------- |
| `isPspOrder`      | `bool?`   | ❌        | `false` | Set to `true` if this order is routed through a PSP. |
| `pspProvider`     | `String?` | ❌        | `null`  | PSP provider name (e.g. `'Tap'`).                    |
| `subMerchantId`   | `int?`    | ❌        | `null`  | Sub-merchant ID assigned by the PSP.                 |
| `subMerchantName` | `String?` | ❌        | `null`  | Sub-merchant name.                                   |

***

#### PaymentSuccess

Returned via `onPaymentSuccess` when a payment completes successfully.

| Field               | Type                 | Description                                           |
| ------------------- | -------------------- | ----------------------------------------------------- |
| `orderToken`        | `String?`            | Taly order token.                                     |
| `talyOrderId`       | `int?`               | Taly's internal order ID.                             |
| `merchantOrderId`   | `String?`            | Your original merchant order ID.                      |
| `status`            | `String?`            | Order status string (e.g. `'approved'`).              |
| `totalAmount`       | `double?`            | Total amount charged.                                 |
| `currency`          | `String?`            | Currency code.                                        |
| `paymentPlanId`     | `String?`            | ID of the selected Taly payment plan.                 |
| `paymentPlanName`   | `String?`            | Name of the selected Taly payment plan.               |
| `orderDate`         | `String?`            | ISO 8601 order creation timestamp.                    |
| `merchantId`        | `int?`               | Your merchant ID on the Taly platform.                |
| `merchantName`      | `String?`            | Your merchant name on the Taly platform.              |
| `branchId`          | `int?`               | Branch ID associated with the order.                  |
| `branchName`        | `String?`            | Branch name.                                          |
| `branchType`        | `String?`            | Branch type.                                          |
| `settlementType`    | `String?`            | Settlement method.                                    |
| `settlementStatus`  | `String?`            | Settlement status.                                    |
| `totalReturnAmount` | `double?`            | Total amount returned (refunds).                      |
| `totalRefundAmount` | `double?`            | Total amount refunded.                                |
| `redirectUrl`       | `String?`            | The merchant redirect URL the order was completed on. |
| `postBackUrl`       | `String?`            | Webhook URL used for this order.                      |
| `merchantLogo`      | `String?`            | Merchant logo URL used during checkout.               |
| `psp`               | `PaymentSuccessPsp?` | PSP details echoed back from the order.               |

##### `toJson()` → `String`

Serializes the result to a JSON string for logging or server forwarding.

***

#### PaymentFailure

A type alias for `PaymentSuccess`:

```dart
typedef PaymentFailure = PaymentSuccess;
```

The same fields are available. Inspect `status` to determine the reason for failure.

***

#### PaymentError

Returned via `onPaymentError` when an SDK or network error prevents the payment from being processed.

| Field             | Type           | Description                                                    |
| ----------------- | -------------- | -------------------------------------------------------------- |
| `status`          | `String?`      | HTTP status or error category.                                 |
| `message`         | `String?`      | Human-readable error message.                                  |
| `errors`          | `List<String>` | List of detailed error strings (may be empty).                 |
| `errorCode`       | `String?`      | Machine-readable error code.                                   |
| `merchantOrderId` | `String?`      | The merchant order ID that triggered the error (if available). |

##### `toJson()` → `String`

Serializes the error to a JSON string.

***

#### InstallmentModel

Represents a single installment in the payment schedule returned by `fetchInstallments()`.

| Field                 | Type     | Description                                                 |
| --------------------- | -------- | ----------------------------------------------------------- |
| `amount`              | `double` | Amount due for this installment.                            |
| `currency`            | `String` | Currency code.                                              |
| `dueDate`             | `String` | ISO 8601 due date for this installment.                     |
| `dueDateDesc`         | `String` | Human-readable due date description.                        |
| `nbOfInstallment`     | `int`    | Installment number (1-based, e.g. `1` = first installment). |
| `noOfInstallmentDesc` | `String` | Description of installment position (e.g. `'1st'`).         |
| `status`              | `String` | Installment status.                                         |
| `finalAmount`         | `double` | Final total after all installments are paid.                |

***

### Enums

#### Environment

Controls which Taly backend the SDK communicates with.

| Value                     | Description                                                  |
| ------------------------- | ------------------------------------------------------------ |
| `Environment.development` | Development / sandbox environment — use for testing.         |
| `Environment.production`  | Production environment — use for live merchant transactions. |

```dart
await TalyFlutterSdk.initialize(
  userName:    'YOUR_USER_NAME',
  password:    'YOUR_PASSWORD',
  environment: Environment.production,
);
```

***

#### LogLevel

Controls the verbosity of SDK log output.

| Value              | Description                                                                   |
| ------------------ | ----------------------------------------------------------------------------- |
| `LogLevel.verbose` | All messages, including detailed trace output. (Default after `initialize()`) |
| `LogLevel.debug`   | Debug messages and above.                                                     |
| `LogLevel.info`    | Informational messages and above.                                             |
| `LogLevel.warning` | Warnings and above.                                                           |
| `LogLevel.error`   | Errors only. Recommended for production builds.                               |
| `LogLevel.none`    | No log output.                                                                |

```dart
// Development
await TalyFlutterSdk.setLogLevel(LogLevel.verbose);

// Production
await TalyFlutterSdk.setLogLevel(LogLevel.error);
```

***

## Customization

### Primary Color

Override the SDK's primary accent color to match your brand:

```dart
// Use Flutter's Color.value (ARGB integer)
await TalyFlutterSdk.setPrimaryColor(const Color(0xFF1565C0).value);
```

### Language

Switch the payment screen language. Must match a locale supported by your app:

```dart
await TalyFlutterSdk.setLanguageCode('ar'); // Arabic
await TalyFlutterSdk.setLanguageCode('en'); // English (default)
```

For Arabic, ensure your Flutter app declares `ar` as a supported locale:

```dart
MaterialApp(
  supportedLocales: const [
    Locale('en'),
    Locale('ar'),
  ],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  ...
)
```

***

## Error Handling

The SDK surfaces errors through three mechanisms:

### 1. Payment Callbacks

Register `onPaymentError` to catch SDK-level errors (authentication failures, network timeouts, invalid order data):

```dart
TalyFlutterSdk.onPaymentError = (PaymentError error) {
  // Log for diagnostics
  debugPrint('Taly error [${error.errorCode}]: ${error.message}');
  // Show user-friendly message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Payment could not be completed. Please try again.')),
  );
};
```

### 2. try / catch on `fetchInstallments()`

`fetchInstallments()` and other SDK methods are `async` and may throw. Wrap them in `try/catch`:

```dart
try {
  final installments = await TalyFlutterSdk.fetchInstallments(
    name:     'Blue Shirt',
    quantity: 1,
    amount:   '15.000',
    currency: 'KWD',
  );
  // use installments
} catch (e) {
  debugPrint('Failed to fetch installments: $e');
  // Gracefully degrade — hide the banner, show a fallback, etc.
}
```

### 3. TalyBannerView Error State

`TalyBannerView` handles its own errors internally and renders an error icon if `fetchInstallments()` fails. No additional error handling is required in the host widget.

### Common Error Scenarios

| Scenario                  | Callback / Exception                          | Recommended Action                                        |
| ------------------------- | --------------------------------------------- | --------------------------------------------------------- |
| Wrong credentials         | `onPaymentError` — `errorCode: 'auth_failed'` | Verify `userName` / `password`.                           |
| `initialize()` not called | Exception thrown from `initiatePayment()`     | Always call `initialize()` before any other SDK method.   |
| Network unavailable       | `onPaymentError`                              | Show a connectivity error message and retry.              |
| Invalid order data        | `onPaymentError`                              | Validate all required fields in `InitiatePaymentModel`.   |
| Quantity ≤ 0 in banner    | Banner renders error state                    | Ensure `quantity > 0` before displaying `TalyBannerView`. |
| Empty amount in banner    | Banner renders error state                    | Ensure `amount` is a non-empty, positive numeric string.  |

***

## Best Practices

1. **Initialize once, early.** Call `TalyFlutterSdk.initialize()` in `main()` before `runApp()`. Avoid calling it multiple times.

2. **Use `Environment.development` during development.** Switch to `Environment.production` only in release builds. Consider using Dart's compilation flags or a flavors setup to select the environment automatically.

3. **Generate unique `merchantOrderId` values.** Using `DateTime.now().millisecondsSinceEpoch.toString()` is a reliable approach. Duplicate order IDs may cause unexpected behavior.

4. **Set `LogLevel.error` in production.** `LogLevel.verbose` is useful during development but generates significant output in production.

   ```dart
   await TalyFlutterSdk.setLogLevel(
     kReleaseMode ? LogLevel.error : LogLevel.verbose,
   );
   ```

5. **Assign callbacks before navigating to checkout.** Set `onPaymentSuccess`, `onPaymentFailure`, and `onPaymentError` before calling `initiatePayment()` to guarantee you never miss a result.

6. **Dispose controllers alongside callbacks.** Callback references are static. If your widget is disposed, avoid using `context` inside the callback without checking `mounted`:

   ```dart
   TalyFlutterSdk.onPaymentSuccess = (result) {
     if (!mounted) return;
     // safe to use context here
   };
   ```

7. **Show `TalyBannerView` only when a valid amount is available.** Conditionally render the banner widget to avoid unnecessary API calls:

   ```dart
   if (amount.isNotEmpty)
     TalyBannerView(amount: amount, currency: 'KWD')
   ```

8. **Provide `postBackUrl` for server-side verification.** Always verify payment status server-to-server via the webhook before fulfilling an order — do not rely solely on the client-side callback.

9. **Supply `customerDetails` and `deliveryAddress` when possible.** These fields improve Taly's risk scoring and increase approval rates for your customers.

10. **Handle both `onPaymentFailure` and `onPaymentError`.** Failure indicates a completed transaction that was declined; error indicates the transaction could not be submitted. Both require different UX responses.