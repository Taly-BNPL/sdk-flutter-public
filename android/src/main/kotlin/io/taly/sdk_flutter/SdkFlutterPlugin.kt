package io.taly.sdk_flutter

import android.app.Activity
import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import io.taly.sdk.TalySdk
import io.taly.sdk.callback.CustomSDKCallback
import io.taly.sdk.callback.PaymentCallback
import io.taly.sdk.model.ErrorCallBack
import io.taly.sdk.model.InitiatePaymentModel
import io.taly.sdk.model.InstallmentModel
import io.taly.sdk.model.SuccessCallBack
import io.taly.sdk.utils.Environment
import io.taly.sdk.utils.logs.LogLevel
import java.util.ArrayList
import java.util.Collections.emptyList
import java.util.Collections.emptyMap

class SdkFlutterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        channel = MethodChannel(binding.binaryMessenger, "io.taly.sdk/taly")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> handleInitialize(call, result)
            "initiatePayment" -> handleInitiatePayment(call, result)
            "fetchInstallments" -> handleFetchInstallments(call, result)
            "setLogLevel" -> handleSetLogLevel(call, result)
            "setPrimaryColor" -> handleSetPrimaryColor(call, result)
            "setLanguageCode" -> handleSetLanguageCode(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleInitialize(call: MethodCall, result: Result) {
        val userName = call.argument<String>("userName")
            ?: return result.error("MISSING_PARAM", "userName is required", null)
        val password = call.argument<String>("password")
            ?: return result.error("MISSING_PARAM", "password is required", null)
        val envStr = call.argument<String>("environment") ?: "production"
        val env = if (envStr == "development") Environment.Development else Environment.Production

        try {
            TalySdk.initialize(context, userName, password, env)
            result.success(null)
        } catch (e: Exception) {
            result.error("INIT_ERROR", e.message, null)
        }
    }

    private fun handleInitiatePayment(call: MethodCall, result: Result) {
        val ctx = activity
            ?: return result.error("NO_ACTIVITY", "Activity is not attached", null)

        @Suppress("UNCHECKED_CAST")
        val args = call.arguments as? Map<String, Any?> ?: emptyMap()

        @Suppress("UNCHECKED_CAST")
        val rawItems = args["orderItems"] as? List<Map<String, Any?>> ?: emptyList()
        val orderItems = ArrayList(rawItems.map { i ->
            InitiatePaymentModel.OrderItem(
                sku = i["sku"] as? String ?: "",
                type = i["type"] as? String ?: "physical",
                name = i["name"] as? String ?: "",
                nameArabic = i["nameArabic"] as? String ?: "",
                currency = i["currency"] as? String ?: "",
                itemDescription = i["itemDescription"] as? String,
                itemDescriptionArabic = i["itemDescriptionArabic"] as? String,
                quantity = (i["quantity"] as? Number)?.toInt() ?: 0,
                itemPrice = (i["itemPrice"] as? Number)?.toDouble() ?: 0.0,
                imageUrl = i["imageUrl"] as? String,
                itemUrl = i["itemUrl"] as? String,
                itemUnit = i["itemUnit"] as? String,
                itemSize = i["itemSize"] as? String,
                itemColor = i["itemColor"] as? String,
                itemGender = i["itemGender"] as? String,
                itemBrand = i["itemBrand"] as? String,
                itemCategory = i["itemCategory"] as? String,
            )
        })

        @Suppress("UNCHECKED_CAST")
        val cd = args["customerDetails"] as? Map<String, Any?> ?: emptyMap()
        val customerDetails = InitiatePaymentModel.CustomerDetails(
            firstName = cd["firstName"] as? String,
            lastName = cd["lastName"] as? String,
            gender = cd["gender"] as? String,
            countryCode = cd["countryCode"] as? String,
            phoneNumber = cd["phoneNumber"] as? String,
            customerEmail = cd["customerEmail"] as? String,
            registeredSince = cd["registeredSince"] as? String,
            loyaltyMember = cd["loyaltyMember"] as? Boolean,
            loyaltyLevel = cd["loyaltyLevel"] as? String,
        )

        @Suppress("UNCHECKED_CAST")
        val da = args["deliveryAddress"] as? Map<String, Any?> ?: emptyMap()
        val deliveryAddress = InitiatePaymentModel.DeliveryAddress(
            city = da["city"] as? String,
            area = da["area"] as? String,
            fullAddress = da["fullAddress"] as? String,
            phoneNumber = da["phoneNumber"] as? String,
            customerEmail = da["customerEmail"] as? String,
        )

        @Suppress("UNCHECKED_CAST")
        val pspMap = args["psp"] as? Map<String, Any?> ?: emptyMap()
        val psp = InitiatePaymentModel.PSP(
            isPspOrder = pspMap["isPspOrder"] as? Boolean ?: false,
            pspProvider = pspMap["pspProvider"] as? String,
            subMerchantName = pspMap["subMerchantName"] as? String,
            subMerchantId = (pspMap["subMerchantId"] as? Number)?.toInt(),
        )

        val model = InitiatePaymentModel(
            merchantOrderId = args["merchantOrderId"] as? String ?: "",
            language = args["language"] as? String ?: "en",
            merchantBranch = args["merchantBranch"] as? String ?: "main",
            subtotal = (args["subTotal"] as? Number)?.toDouble() ?: 0.0,
            totalAmount = (args["totalAmount"] as? Number)?.toDouble() ?: 0.0,
            currency = args["currency"] as? String ?: "",
            discountAmount = (args["discountAmount"] as? Number)?.toDouble() ?: 0.0,
            taxAmount = (args["taxAmount"] as? Number)?.toDouble() ?: 0.0,
            deliveryAmount = (args["deliveryAmount"] as? Number)?.toDouble() ?: 0.0,
            deliveryMethod = args["deliveryMethod"] as? String ?: "",
            otherFees = (args["otherFees"] as? Number)?.toDouble(),
            psp = psp,
            orderItems = orderItems,
            isDigitalOrder = args["isDigitalOrder"] as? Boolean ?: false,
            customerDetails = customerDetails,
            deliveryAddress = deliveryAddress,
            merchantRedirectUrl = args["merchantRedirectUrl"] as? String ?: "",
            platform = "Flutter",
            isMobile = true,
            postBackUrl = args["postBackUrl"] as? String,
            merchantLogo = args["merchantLogo"] as? String,
        )

        TalySdk.getControllerInstance().subscribeToListener(object : PaymentCallback {
            override fun onPaymentSuccess(s: SuccessCallBack) {
                val map = mapOf(
                    "orderToken" to s.orderToken,
                    "branchId" to s.branchId,
                    "orderDate" to s.orderDate,
                    "status" to s.status,
                    "paymentPlanId" to s.paymentPlanId,
                    "redirectUrl" to s.redirectUrl,
                    "paymentPlanName" to s.paymentPlanName,
                    "branchType" to s.branchType,
                    "branchName" to s.branchName,
                    "settlementType" to s.settlementType,
                    "totalReturnAmount" to s.totalReturnAmount,
                    "totalRefundAmount" to s.totalRefundAmount,
                    "merchantId" to s.merchantId,
                    "merchantName" to s.merchantName,
                    "currency" to s.currency,
                    "talyOrderId" to s.talyOrderId,
                    "merchantOrderId" to s.merchantOrderId,
                    "totalAmount" to s.totalAmount,
                    "settlementStatus" to s.settlementStatus,
                    "postBackUrl" to s.postBackUrl,
                    "merchantLogo" to s.merchantLogo,
                    "psp" to s.psp?.let { psp ->
                        mapOf(
                            "isPspOrder" to psp.isPspOrder,
                            "pspProvider" to psp.pspProvider,
                            "subMerchantName" to psp.subMerchantName,
                            "subMerchantId" to psp.subMerchantId,
                        )
                    },
                )
                ctx.runOnUiThread { channel.invokeMethod("onPaymentSuccess", map) }
            }

            override fun onPaymentFailure(f: SuccessCallBack) {
                val map = mapOf(
                    "orderToken" to f.orderToken,
                    "branchId" to f.branchId,
                    "orderDate" to f.orderDate,
                    "status" to f.status,
                    "paymentPlanId" to f.paymentPlanId,
                    "redirectUrl" to f.redirectUrl,
                    "paymentPlanName" to f.paymentPlanName,
                    "branchType" to f.branchType,
                    "branchName" to f.branchName,
                    "settlementType" to f.settlementType,
                    "totalReturnAmount" to f.totalReturnAmount,
                    "totalRefundAmount" to f.totalRefundAmount,
                    "merchantId" to f.merchantId,
                    "merchantName" to f.merchantName,
                    "currency" to f.currency,
                    "talyOrderId" to f.talyOrderId,
                    "merchantOrderId" to f.merchantOrderId,
                    "totalAmount" to f.totalAmount,
                    "settlementStatus" to f.settlementStatus,
                    "postBackUrl" to f.postBackUrl,
                    "merchantLogo" to f.merchantLogo,
                    "psp" to f.psp?.let { psp ->
                        mapOf(
                            "isPspOrder" to psp.isPspOrder,
                            "pspProvider" to psp.pspProvider,
                            "subMerchantName" to psp.subMerchantName,
                            "subMerchantId" to psp.subMerchantId,
                        )
                    },
                )
                ctx.runOnUiThread { channel.invokeMethod("onPaymentFailure", map) }
            }

            override fun onPaymentError(e: ErrorCallBack) {
                val map = mapOf(
                    "status" to e.status,
                    "message" to e.message,
                    "errors" to e.errors,
                    "errorCode" to e.errorCode,
                    "merchantOrderId" to e.merchantOrderId,
                )
                ctx.runOnUiThread { channel.invokeMethod("onPaymentError", map) }
            }
        })

        try {
            TalySdk.getControllerInstance().initiatePayment(ctx, model)
            result.success(null)
        } catch (e: Exception) {
            result.error("PAYMENT_ERROR", e.message, null)
        }
    }

    private fun handleFetchInstallments(call: MethodCall, result: Result) {
        val name = call.argument<String>("name") ?: ""
        val quantity = call.argument<Number>("quantity")?.toInt() ?: 1
        val amount = call.argument<String>("amount") ?: "0"
        val currency = call.argument<String>("currency") ?: ""

        try {
            TalySdk.getControllerInstance().fetchBannerResponse(
                name, quantity, amount, currency,
                object : CustomSDKCallback<InstallmentModel> {
                    override fun onSuccess(data: InstallmentModel) {
                        val list = data.installment.map { i ->
                            mapOf(
                                "amount" to i.amount,
                                "currency" to i.currency,
                                "dueDate" to i.dueDate,
                                "nbOfInstallment" to i.nbOfInstallment,
                                "status" to i.status,
                                "finalAmount" to i.finalAmount,
                                "dueDateDesc" to i.dueDateDesc,
                                "noOfInstallmentDesc" to i.noOfInstallmentDesc,
                            )
                        }
                        activity?.runOnUiThread { result.success(list) }
                    }

                    override fun onFailure(errorMessage: Any) {
                        activity?.runOnUiThread {
                            result.error("FETCH_ERROR", errorMessage.toString(), null)
                        }
                    }
                }
            )
        } catch (e: Exception) {
            result.error("FETCH_ERROR", e.message, null)
        }
    }

    private fun handleSetLogLevel(call: MethodCall, result: Result) {
        val level = when (call.argument<String>("level")) {
            "verbose" -> LogLevel.VERBOSE
            "debug" -> LogLevel.DEBUG
            "info" -> LogLevel.INFO
            "error" -> LogLevel.ERROR
            "warning" -> LogLevel.SUPRESS
            "none"    -> LogLevel.SUPRESS
            else -> LogLevel.DEBUG
        }
        TalySdk.setLogLevel(level)
        result.success(null)
    }

    private fun handleSetPrimaryColor(call: MethodCall, result: Result) {
        val color = call.argument<Number>("color")?.toInt()
            ?: return result.error("MISSING_PARAM", "color is required", null)
        TalySdk.setPrimaryColor(color)
        result.success(null)
    }

    private fun handleSetLanguageCode(call: MethodCall, result: Result) {
        TalySdk.setLanguageCode(call.argument<String>("code"))
        result.success(null)
    }
}
