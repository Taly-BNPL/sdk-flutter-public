class PaymentSuccess {
  final String? orderToken;
  final int? branchId;
  final String? orderDate;
  final String? status;
  final String? paymentPlanId;
  final String? redirectUrl;
  final String? paymentPlanName;
  final String? branchType;
  final String? branchName;
  final String? settlementType;
  final double? totalReturnAmount;
  final double? totalRefundAmount;
  final int? merchantId;
  final String? merchantName;
  final String? currency;
  final int? talyOrderId;
  final String? merchantOrderId;
  final double? totalAmount;
  final String? settlementStatus;
  final String? postBackUrl;
  final String? merchantLogo;
  final PaymentSuccessPsp? psp;

  const PaymentSuccess({
    this.orderToken,
    this.branchId,
    this.orderDate,
    this.status,
    this.paymentPlanId,
    this.redirectUrl,
    this.paymentPlanName,
    this.branchType,
    this.branchName,
    this.settlementType,
    this.totalReturnAmount,
    this.totalRefundAmount,
    this.merchantId,
    this.merchantName,
    this.currency,
    this.talyOrderId,
    this.merchantOrderId,
    this.totalAmount,
    this.settlementStatus,
    this.postBackUrl,
    this.merchantLogo,
    this.psp,
  });

  factory PaymentSuccess.fromMap(Map<Object?, Object?> map) {
    final pspMap = map['psp'];
    return PaymentSuccess(
      orderToken: map['orderToken'] as String?,
      branchId: map['branchId'] as int?,
      orderDate: map['orderDate'] as String?,
      status: map['status'] as String?,
      paymentPlanId: map['paymentPlanId'] as String?,
      redirectUrl: map['redirectUrl'] as String?,
      paymentPlanName: map['paymentPlanName'] as String?,
      branchType: map['branchType'] as String?,
      branchName: map['branchName'] as String?,
      settlementType: map['settlementType'] as String?,
      totalReturnAmount: (map['totalReturnAmount'] as num?)?.toDouble(),
      totalRefundAmount: (map['totalRefundAmount'] as num?)?.toDouble(),
      merchantId: map['merchantId'] as int?,
      merchantName: map['merchantName'] as String?,
      currency: map['currency'] as String?,
      talyOrderId: map['talyOrderId'] as int?,
      merchantOrderId: map['merchantOrderId'] as String?,
      totalAmount: (map['totalAmount'] as num?)?.toDouble(),
      settlementStatus: map['settlementStatus'] as String?,
      postBackUrl: map['postBackUrl'] as String?,
      merchantLogo: map['merchantLogo'] as String?,
      psp: pspMap == null
          ? null
          : PaymentSuccessPsp.fromMap(
              Map<Object?, Object?>.from(pspMap as Map)),
    );
  }

  String toJson() => '{'
      '"orderToken":"$orderToken",'
      '"branchId":$branchId,'
      '"orderDate":"$orderDate",'
      '"status":"$status",'
      '"paymentPlanId":"$paymentPlanId",'
      '"redirectUrl":"$redirectUrl",'
      '"paymentPlanName":"$paymentPlanName",'
      '"branchType":"$branchType",'
      '"branchName":"$branchName",'
      '"settlementType":"$settlementType",'
      '"totalReturnAmount":$totalReturnAmount,'
      '"totalRefundAmount":$totalRefundAmount,'
      '"merchantId":$merchantId,'
      '"merchantName":"$merchantName",'
      '"currency":"$currency",'
      '"talyOrderId":$talyOrderId,'
      '"merchantOrderId":"$merchantOrderId",'
      '"totalAmount":$totalAmount,'
      '"settlementStatus":"$settlementStatus",'
      '"postBackUrl":"$postBackUrl",'
      '"merchantLogo":"$merchantLogo",'
      '"PSP":${psp?.toJson() ?? "null"}'
      '}';
}

class PaymentSuccessPsp {
  final bool? isPspOrder;
  final String? pspProvider;
  final String? subMerchantName;
  final int? subMerchantId;

  const PaymentSuccessPsp({
    this.isPspOrder,
    this.pspProvider,
    this.subMerchantName,
    this.subMerchantId,
  });

  factory PaymentSuccessPsp.fromMap(Map<Object?, Object?> map) =>
      PaymentSuccessPsp(
        isPspOrder: map['isPspOrder'] as bool?,
        pspProvider: map['pspProvider'] as String?,
        subMerchantName: map['subMerchantName'] as String?,
        subMerchantId: (map['subMerchantId'] as num?)?.toInt(),
      );

  String toJson() => '{'
      '"isPspOrder":$isPspOrder,'
      '"pspProvider":"$pspProvider",'
      '"subMerchantName":"$subMerchantName",'
      '"subMerchantId":$subMerchantId'
      '}';
}

class PaymentError {
  final String? status;
  final String? message;
  final List<String> errors;
  final String? errorCode;
  final String? merchantOrderId;

  const PaymentError({
    this.status,
    this.message,
    this.errors = const [],
    this.errorCode,
    this.merchantOrderId,
  });

  factory PaymentError.fromMap(Map<Object?, Object?> map) => PaymentError(
        status: map['status'] as String?,
        message: map['message'] as String?,
        errors:
            (map['errors'] as List?)?.map((e) => e.toString()).toList() ?? [],
        errorCode: map['errorCode'] as String?,
        merchantOrderId: map['merchantOrderId'] as String?,
      );

  String toJson() {
    final errList = errors.map((e) => '"$e"').join(',');
    return '{'
        '"status":"$status",'
        '"message":"$message",'
        '"errors":[$errList],'
        '"errorCode":"$errorCode",'
        '"merchantOrderId":"$merchantOrderId"'
        '}';
  }

  @override
  String toString() => 'PaymentError(${toJson()})';
}

typedef PaymentFailure = PaymentSuccess;
