String? _asString(Object? v) => v?.toString();

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return int.tryParse(s) ?? double.tryParse(s)?.toInt();
}

double? _asDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return double.tryParse(s);
}

bool? _asBool(Object? v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().trim().toLowerCase();
  if (s == 'true' || s == '1') return true;
  if (s == 'false' || s == '0') return false;
  return null;
}

List<String> _asStringList(Object? v) {
  if (v is List) {
    return v.where((e) => e != null).map((e) => e.toString()).toList();
  }
  if (v is String && v.isNotEmpty) return [v];
  return const [];
}

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
      orderToken: _asString(map['orderToken']),
      branchId: _asInt(map['branchId']),
      orderDate: _asString(map['orderDate']),
      status: _asString(map['status']),
      paymentPlanId: _asString(map['paymentPlanId']),
      redirectUrl: _asString(map['redirectUrl']),
      paymentPlanName: _asString(map['paymentPlanName']),
      branchType: _asString(map['branchType']),
      branchName: _asString(map['branchName']),
      settlementType: _asString(map['settlementType']),
      totalReturnAmount: _asDouble(map['totalReturnAmount']),
      totalRefundAmount: _asDouble(map['totalRefundAmount']),
      merchantId: _asInt(map['merchantId']),
      merchantName: _asString(map['merchantName']),
      currency: _asString(map['currency']),
      talyOrderId: _asInt(map['talyOrderId']),
      merchantOrderId: _asString(map['merchantOrderId']),
      totalAmount: _asDouble(map['totalAmount']),
      settlementStatus: _asString(map['settlementStatus']),
      postBackUrl: _asString(map['postBackUrl']),
      merchantLogo: _asString(map['merchantLogo']),
      psp: pspMap is Map
          ? PaymentSuccessPsp.fromMap(Map<Object?, Object?>.from(pspMap))
          : null,
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

  @override
  String toString() => 'PaymentSuccess(${toJson()})';
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
        isPspOrder: _asBool(map['isPspOrder']),
        pspProvider: _asString(map['pspProvider']),
        subMerchantName: _asString(map['subMerchantName']),
        subMerchantId: _asInt(map['subMerchantId']),
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
    status: _asString(map['status']),
    message: _asString(map['message']),
    errors: _asStringList(map['errors']),
    errorCode: _asString(map['errorCode']),
    merchantOrderId: _asString(map['merchantOrderId']),
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