class InitiatePaymentModel {
  final String merchantOrderId;
  final double subTotal;
  final double totalAmount;
  final String currency;
  final String deliveryMethod;
  final List<OrderItem> orderItems;
  final String merchantRedirectUrl;

  final String? language;
  final String? merchantBranch;
  final double discountAmount;
  final double taxAmount;
  final double deliveryAmount;
  final double? otherFees;
  final bool? isDigitalOrder;
  final String? postBackUrl;
  final String? merchantLogo;

  final PSP psp;
  final CustomerDetails customerDetails;
  final DeliveryAddress deliveryAddress;

  const InitiatePaymentModel({
    required this.merchantOrderId,
    required this.subTotal,
    required this.totalAmount,
    required this.currency,
    required this.deliveryMethod,
    required this.orderItems,
    required this.merchantRedirectUrl,
    this.language = 'en',
    this.merchantBranch = 'main',
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    this.deliveryAmount = 0.0,
    this.otherFees,
    this.isDigitalOrder = false,
    this.postBackUrl,
    this.merchantLogo,
    this.psp = const PSP(),
    this.customerDetails = const CustomerDetails(),
    this.deliveryAddress = const DeliveryAddress(),
  });

  Map<String, dynamic> toMap() => {
        'merchantOrderId': merchantOrderId,
        'subTotal': subTotal,
        'totalAmount': totalAmount,
        'currency': currency,
        'deliveryMethod': deliveryMethod,
        'merchantRedirectUrl': merchantRedirectUrl,
        'language': language,
        'merchantBranch': merchantBranch,
        'discountAmount': discountAmount,
        'taxAmount': taxAmount,
        'deliveryAmount': deliveryAmount,
        'otherFees': otherFees,
        'isDigitalOrder': isDigitalOrder,
        'postBackUrl': postBackUrl,
        'merchantLogo': merchantLogo,
        'psp': psp.toMap(),
        'customerDetails': customerDetails.toMap(),
        'deliveryAddress': deliveryAddress.toMap(),
        'orderItems': orderItems.map((e) => e.toMap()).toList(),
      };
}

class OrderItem {
  final String sku;
  final String name;
  final String nameArabic;
  final String currency;
  final int quantity;
  final double itemPrice;
  final String? type;
  final String? itemDescription;
  final String? itemDescriptionArabic;
  final String? imageUrl;
  final String? itemUrl;
  final String? itemUnit;
  final String? itemSize;
  final String? itemColor;
  final String? itemGender;
  final String? itemBrand;
  final String? itemCategory;

  const OrderItem({
    required this.sku,
    required this.name,
    required this.nameArabic,
    required this.currency,
    required this.quantity,
    required this.itemPrice,
    this.type = 'physical',
    this.itemDescription,
    this.itemDescriptionArabic,
    this.imageUrl,
    this.itemUrl,
    this.itemUnit,
    this.itemSize,
    this.itemColor,
    this.itemGender,
    this.itemBrand,
    this.itemCategory,
  });

  Map<String, dynamic> toMap() => {
        'sku': sku,
        'name': name,
        'nameArabic': nameArabic,
        'currency': currency,
        'quantity': quantity,
        'itemPrice': itemPrice,
        'type': type,
        'itemDescription': itemDescription,
        'itemDescriptionArabic': itemDescriptionArabic,
        'imageUrl': imageUrl,
        'itemUrl': itemUrl,
        'itemUnit': itemUnit,
        'itemSize': itemSize,
        'itemColor': itemColor,
        'itemGender': itemGender,
        'itemBrand': itemBrand,
        'itemCategory': itemCategory,
      };
}

class CustomerDetails {
  final String? firstName;
  final String? lastName;
  final String? gender;
  final String? countryCode;
  final String? phoneNumber;
  final String? customerEmail;
  final String? registeredSince;
  final bool? loyaltyMember;
  final String? loyaltyLevel;

  const CustomerDetails({
    this.firstName,
    this.lastName,
    this.gender,
    this.countryCode,
    this.phoneNumber,
    this.customerEmail,
    this.registeredSince,
    this.loyaltyMember,
    this.loyaltyLevel,
  });

  Map<String, dynamic> toMap() => {
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender,
        'countryCode': countryCode,
        'phoneNumber': phoneNumber,
        'customerEmail': customerEmail,
        'registeredSince': registeredSince,
        'loyaltyMember': loyaltyMember,
        'loyaltyLevel': loyaltyLevel,
      };
}

class DeliveryAddress {
  final String? city;
  final String? area;
  final String? fullAddress;
  final String? phoneNumber;
  final String? customerEmail;

  const DeliveryAddress({
    this.city,
    this.area,
    this.fullAddress,
    this.phoneNumber,
    this.customerEmail,
  });

  Map<String, dynamic> toMap() => {
        'city': city,
        'area': area,
        'fullAddress': fullAddress,
        'phoneNumber': phoneNumber,
        'customerEmail': customerEmail,
      };
}

// ── PSP ────────────────────────────────────────────────────────────────────

class PSP {
  final bool? isPspOrder;
  final String? pspProvider;
  final String? subMerchantName;
  final int? subMerchantId;

  const PSP({
    this.isPspOrder = false,
    this.pspProvider,
    this.subMerchantName,
    this.subMerchantId,
  });

  Map<String, dynamic> toMap() => {
        'isPspOrder': isPspOrder,
        'pspProvider': pspProvider,
        'subMerchantName': subMerchantName,
        'subMerchantId': subMerchantId,
      };
}
