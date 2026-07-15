import Flutter
import UIKit
import TalySdk

/// Bridges Flutter `MethodChannel('io.taly.sdk/taly')` to the native **TalySdk** iOS framework.
/// Mirrors `SdkFlutterPlugin.kt`: same channel name, method names, argument keys, error codes, and callback maps.
public class SdkFlutterPlugin: NSObject, FlutterPlugin {

    // MARK: - Channel (must match Android & Dart `TalyFlutterSdk._channel`)
    private var channel: FlutterMethodChannel?

    /// Credentials and environment from `initialize`; iOS payment UI (`PlaceOrderView`) needs these at presentation time.
    private var storedUserName: String?
    private var storedPassword: String?
    private var storedEnvironment: URLHost = .production

    /// OAuth for `TokenRequest` (from Dart `initialize`; defaults match https://docs.taly.io/docs/ios).
    private var storedOauthGrantType: String = "password"
    private var storedOauthScope: String = "api"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "io.taly.sdk/taly",
            binaryMessenger: registrar.messenger()
        )
        let instance = SdkFlutterPlugin()
        instance.channel = channel
        channel.setMethodCallHandler(instance.handle)
    }

    // MARK: - Method dispatch (same `call.method` strings as Kotlin `when`)

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            handleInitialize(call, result: result)
        case "initiatePayment":
            handleInitiatePayment(call, result: result)
        case "fetchInstallments":
            handleFetchInstallments(call, result: result)
        case "setLogLevel":
            handleSetLogLevel(call, result: result)
        case "setPrimaryColor":
            handleSetPrimaryColor(call, result: result)
        case "setLanguageCode":
            handleSetLanguageCode(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - initialize

    /// Args: `userName`, `password`, `environment` (`"development"` | default production).
    /// Android: `TalySdk.initialize(context, …)` — iOS stores credentials and updates `Utils` (no single global init API).
    private func handleInitialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "MISSING_PARAM", message: "Invalid arguments", details: nil))
            return
        }
        guard let userName = args["userName"] as? String else {
            result(FlutterError(code: "MISSING_PARAM", message: "userName is required", details: nil))
            return
        }
        guard let password = args["password"] as? String else {
            result(FlutterError(code: "MISSING_PARAM", message: "password is required", details: nil))
            return
        }
        let envStr = args["environment"] as? String ?? "production"
        let env: URLHost = (envStr == "development") ? .dev : .production

        storedUserName = userName
        storedPassword = password
        storedEnvironment = env
        if let gt = args["oauthGrantType"] as? String, !gt.isEmpty {
            storedOauthGrantType = gt
        }
        if let sc = args["oauthScope"] as? String, !sc.isEmpty {
            storedOauthScope = sc
        }
        let envString = (env == .dev) ? "development" : "production"
        Utils.updateProperties(userName: userName, password: password, environment: envString)

        // Drop any cached session so a stale token (e.g. from an older plugin using `read` scope) is not reused.
        resetTalySdkSessionTokens()
        result(nil)
    }

    /// Clears tokens stored in `TalySdk.Utils` so the next auth uses a fresh `TokenRequest` (correct `api` scope).
    private func resetTalySdkSessionTokens() {
        Utils.token = ""
        Utils.expiresIn = 0
    }

    /// Uses `OrderResource.getToken` with [storedOauthScope] (default `api`) and writes `accessToken` / `expiresIn` into `Utils`.
    /// Several TalySdk code paths reuse `Utils.token` or request OAuth with a built-in `read` scope; priming an `api` token
    /// matches Taly docs and avoids `invalid_scope` on create-order.
    private func obtainMerchantAccessToken(username: String, password: String) async throws {
        await MainActor.run { resetTalySdkSessionTokens() }
        let tokenRequest = TokenRequest(
            username: username,
            password: password,
            grantType: storedOauthGrantType,
            scope: storedOauthScope
        )
        let outcome = try await OrderResource().getToken(tokenRequest: tokenRequest)
        switch outcome {
        case .value(let tr):
            await MainActor.run {
                Utils.updateProperties(token: tr.accessToken, expiresIn: tr.expiresIn)
            }
        case .error(let err, let code):
            let msg = [err.error, err.error_description].compactMap { $0 }.joined(separator: " ")
            throw NSError(
                domain: "TALY_TOKEN",
                code: code,
                userInfo: [NSLocalizedDescriptionKey: msg.isEmpty ? "Token request failed (code \(code))" : msg]
            )
        }
    }

    // MARK: - initiatePayment

    /// Presents `PlaceOrderView` modally. Payment outcomes are sent on the same channel as Android:
    /// `onPaymentSuccess`, `onPaymentFailure`, `onPaymentError`.
    private func handleInitiatePayment(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = (call.arguments as? [String: Any]) ?? [:]
        DispatchQueue.main.async { [self] in
            guard let userName = storedUserName, let password = storedPassword else {
                result(FlutterError(code: "INIT_ERROR", message: "SDK not initialized", details: nil))
                return
            }
            guard let root = topViewController() else {
                result(FlutterError(code: "NO_ACTIVITY", message: "No root view controller to present from", details: nil))
                return
            }

            let orderRequest = buildOrderRequest(from: args)
            let languageCode = (args["language"] as? String) ?? "en"
            let hostEnv = storedEnvironment
            let grant = storedOauthGrantType
            let scope = storedOauthScope
            let channelRef = channel

            Task {
                do {
                    try await obtainMerchantAccessToken(username: userName, password: password)
                    let tokenRequest = TokenRequest(
                        username: userName,
                        password: password,
                        grantType: grant,
                        scope: scope
                    )
                    await MainActor.run {
                        let paymentDelegate = PaymentFlowDelegate(channel: channelRef)
                        let placeOrderVC = TrackedPlaceOrderView(
                            orderRequest: orderRequest,
                            tokenRequest: tokenRequest,
                            environment: hostEnv,
                            languageCode: languageCode
                        )
                        placeOrderVC.activityIndicatorColor = UIColor(
                            red: 14.0 / 255.0,
                            green: 133.0 / 255.0,
                            blue: 255.0 / 255.0,
                            alpha: 1.0
                        )
                        placeOrderVC.onWebViewLoaded = { [weak channelRef] in
                            DispatchQueue.main.async {
                                channelRef?.invokeMethod("onPaymentWebViewLoaded", arguments: nil)
                            }
                        }
                        placeOrderVC.delegate = paymentDelegate
                        paymentDelegate.beginRetainingLifetime()
                        placeOrderVC.modalPresentationStyle = .fullScreen
                        root.present(placeOrderVC, animated: true) {
                            placeOrderVC.presentationController?.delegate = paymentDelegate
                            result(nil)
                        }
                    }
                } catch {
                    await MainActor.run {
                        result(FlutterError(
                            code: "TOKEN_ERROR",
                            message: error.localizedDescription,
                            details: nil
                        ))
                    }
                }
            }
        }
    }

    /// Maps Flutter `InitiatePaymentModel.toMap()` into `TalySdk.OrderRequest`.
    /// Differences vs Android: iOS public `OrderItem` init has no `nameArabic` / `itemDescriptionArabic` — merged into `itemDescription` when useful.
    private func buildOrderRequest(from args: [String: Any]) -> OrderRequest {
        let rawItems = args["orderItems"] as? [[String: Any]] ?? []
        let orderItems: [OrderItem] = rawItems.map { i in
            let nameEn = i["name"] as? String ?? ""
            let nameAr = i["nameArabic"] as? String
            let descEn = i["itemDescription"] as? String
            let descAr = i["itemDescriptionArabic"] as? String
            let mergedDescription: String? = {
                var parts: [String] = []
                if let d = descEn, !d.isEmpty { parts.append(d) }
                if let d = descAr, !d.isEmpty { parts.append(d) }
                if parts.isEmpty, let ar = nameAr, !ar.isEmpty { return ar }
                return parts.isEmpty ? nil : parts.joined(separator: " | ")
            }()

            return OrderItem(
                sku: i["sku"] as? String ?? "",
                type: i["type"] as? String ?? "physical",
                name: nameEn.isEmpty ? (nameAr ?? "") : nameEn,
                itemDescription: mergedDescription,
                quantity: intValue(i["quantity"]) ?? 0,
                itemPrice: doubleValue(i["itemPrice"]) ?? 0,
                imageUrl: i["imageUrl"] as? String,
                itemUrl: i["itemUrl"] as? String,
                itemUnit: i["itemUnit"] as? String,
                itemSize: i["itemSize"] as? String,
                itemColor: i["itemColor"] as? String,
                itemGender: i["itemGender"] as? String,
                itemBrand: i["itemBrand"] as? String,
                itemCategory: i["itemCategory"] as? String,
                currency: i["currency"] as? String
            )
        }

        let cd = args["customerDetails"] as? [String: Any] ?? [:]
        let customerDetails = CustomerDetails(
            firstName: cd["firstName"] as? String,
            lastName: cd["lastName"] as? String,
            gender: cd["gender"] as? String,
            countryCode: cd["countryCode"] as? String,
            phoneNumber: cd["phoneNumber"] as? String,
            customerEmail: cd["customerEmail"] as? String,
            registeredSince: cd["registeredSince"] as? String,
            loyaltyMember: cd["loyaltyMember"] as? Bool,
            loyaltyLevel: cd["loyaltyLevel"] as? String
        )

        let da = args["deliveryAddress"] as? [String: Any] ?? [:]
        let deliveryAddress = DeliveryAddress(
            city: da["city"] as? String,
            area: da["area"] as? String,
            fullAddress: da["fullAddress"] as? String,
            phoneNumber: da["phoneNumber"] as? String,
            customerEmail: da["customerEmail"] as? String
        )

        let pspMap = args["psp"] as? [String: Any] ?? [:]
        let psp = PSP(
            isPspOrder: pspMap["isPspOrder"] as? Bool ?? false,
            pspProvider: pspMap["pspProvider"] as? String,
            subMerchantId: intValue(pspMap["subMerchantId"]),
            subMerchantName: pspMap["subMerchantName"] as? String
        )

        var request = OrderRequest(
            merchantOrderId: args["merchantOrderId"] as? String ?? "",
            language: args["language"] as? String ?? "en",
            subtotal: doubleValue(args["subTotal"]) ?? 0,
            totalAmount: doubleValue(args["totalAmount"]) ?? 0,
            currency: args["currency"] as? String ?? "",
            discountAmount: doubleValue(args["discountAmount"]) ?? 0,
            taxAmount: doubleValue(args["taxAmount"]) ?? 0,
            deliveryAmount: doubleValue(args["deliveryAmount"]) ?? 0,
            deliveryMethod: args["deliveryMethod"] as? String ?? "",
            otherFees: doubleValue(args["otherFees"]),
            psp: psp,
            orderItems: orderItems,
            isDigitalOrder: args["isDigitalOrder"] as? Bool ?? false,
            customerDetails: customerDetails,
            deliveryAddress: deliveryAddress,
            merchantRedirectURL: args["merchantRedirectUrl"] as? String ?? "",
            postBackUrl: args["postBackUrl"] as? String,
            merchantLogo: args["merchantLogo"] as? String
        )
        request.platform = "Flutter"
        request.isMobile = true
        return request
    }

    // MARK: - fetchInstallments

    /// Android: `fetchBannerResponse` + `CustomSDKCallback`. iOS: async `BannerResource.getBannerData`.
    /// Response list shape matches Android maps (extra description fields empty — not in `BannerResponse`).
    private func handleFetchInstallments(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "FETCH_ERROR", message: "Invalid arguments", details: nil))
            return
        }
        let name = args["name"] as? String ?? ""
        let quantity = intValue(args["quantity"]) ?? 1
        let amountString = args["amount"] as? String ?? "0"
        let currency = args["currency"] as? String ?? ""
        let unitPrice = Double(amountString) ?? 0

        Task { [self] in
            do {
                guard let userName = storedUserName, let password = storedPassword else {
                    await MainActor.run {
                        result(FlutterError(code: "FETCH_ERROR", message: "SDK not initialized", details: nil))
                    }
                    return
                }
                try await obtainMerchantAccessToken(username: userName, password: password)
                let bannerRequest = BannerRequest(name: name, quantity: quantity, unitPrice: unitPrice, currency: currency)
                let response = try await BannerResource().getBannerData(data: bannerRequest)
                switch response {
                case .value(let rows):
                    let list: [[String: Any]] = rows.map { row in
                        [
                            "amount": row.amount,
                            "currency": row.currency,
                            "dueDate": row.dueDate,
                            "nbOfInstallment": row.nbOfInstallment,
                            "status": row.status,
                            "finalAmount": row.finalAmount,
                            "dueDateDesc": "",
                            "noOfInstallmentDesc": ""
                        ]
                    }
                    await MainActor.run { result(list) }
                case .error(let err, let code):
                    await MainActor.run {
                        let msg = [err.error, err.error_description].compactMap { $0 }.joined(separator: " ")
                        result(FlutterError(code: "FETCH_ERROR", message: "\(msg) code:\(code)", details: nil))
                    }
                }
            } catch {
                await MainActor.run {
                    result(FlutterError(code: "FETCH_ERROR", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    // MARK: - setLogLevel / setPrimaryColor / setLanguageCode

    /// Android maps string levels to `LogLevel`. The vendored iOS framework does not expose an equivalent API — kept for API parity.
    private func handleSetLogLevel(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        _ = (call.arguments as? [String: Any])?["level"] as? String
        result(nil)
    }

    /// Android: `TalySdk.setPrimaryColor(Int?)`. Not exposed on iOS public surface — no-op for parity.
    private func handleSetPrimaryColor(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        _ = (call.arguments as? [String: Any])?["color"] as? Int
        result(nil)
    }

    /// Android: `TalySdk.setLanguageCode`. iOS: `Utils.languageCode`.
    private func handleSetLanguageCode(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let code = (call.arguments as? [String: Any])?["code"] as? String
        Utils.languageCode = code
        result(nil)
    }

    // MARK: - Helpers

    private func doubleValue(_ any: Any?) -> Double? {
        if let n = any as? NSNumber { return n.doubleValue }
        if let d = any as? Double { return d }
        if let i = any as? Int { return Double(i) }
        return nil
    }

    private func intValue(_ any: Any?) -> Int? {
        if let n = any as? NSNumber { return n.intValue }
        if let i = any as? Int { return i }
        return nil
    }

    /// Walks `presentedViewController` chain to find a VC that can `present` the payment UI.
    private func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let base = base ?? {
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }) ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
                  let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first
            else { return nil }
            return window.rootViewController
        }()

        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}

// MARK: - Payment callbacks → Flutter (same method names & payload keys as Android)

/// Holds strong references while `PlaceOrderView` is on screen; released after dismissal.
private final class PaymentFlowDelegate: NSObject, PlaceOrderDelegate, UIAdaptivePresentationControllerDelegate {

    private weak var channel: FlutterMethodChannel?
    private var strongSelf: PaymentFlowDelegate?

    init(channel: FlutterMethodChannel?) {
        self.channel = channel
    }

    /// `PlaceOrderView` holds `delegate` weakly; retain until flow ends or the sheet is dismissed.
    func beginRetainingLifetime() {
        strongSelf = self
    }

    private func endRetainingLifetime() {
        strongSelf = nil
    }

    private func invokeOnMain(_ method: String, _ arguments: [String: Any?], completion: (() -> Void)? = nil) {
        let payload = arguments.compactMapValues { $0 }
        let run: () -> Void = { [self] in
            channel?.invokeMethod(method, arguments: payload)
            completion?()
        }
        if Thread.isMainThread {
            run()
        } else {
            DispatchQueue.main.async(execute: run)
        }
    }

    func didFinishPlaceOrderWithSuccess(successOrderDetails: OrderDetails) {
        invokeOnMain("onPaymentSuccess", mapOrderDetails(successOrderDetails)) { [weak self] in
            self?.endRetainingLifetime()
        }
    }

    func didFinishPlaceOrderWithFailure(failureOrderDetail: OrderDetails) {
        invokeOnMain("onPaymentFailure", mapOrderDetails(failureOrderDetail)) { [weak self] in
            self?.endRetainingLifetime()
        }
    }

    func didFinishPlaceOrderWithError(error: OtherErrorResponse) {
        invokeOnMain("onPaymentError", [
            "status": error.status,
            "message": error.message,
            "errors": error.errors,
            "errorCode": error.errorCode,
            "merchantOrderId": error.merchantOrderId
        ]) { [weak self] in
            self?.endRetainingLifetime()
        }
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        channel?.invokeMethod("onPaymentDismissed", arguments: nil)
        endRetainingLifetime()
    }

    /// Mirrors Android `SuccessCallBack` / `PaymentCallback` map (including nested `psp`).
    private func mapOrderDetails(_ s: OrderDetails) -> [String: Any?] {
        // `TalySdk.PSP` fields are not all accessible across module boundaries; encode via `Encodable` (public API).
        let pspNested: [String: Any]? = {
            guard let p = s.psp else { return nil }
            return Self.encodeToFlutterMap(p)
        }()
        return [
            "orderToken": s.orderToken,
            "branchId": s.branchId,
            "orderDate": s.orderDate,
            "status": s.status,
            "paymentPlanId": s.paymentPlanId,
            "redirectUrl": s.redirectUrl,
            "paymentPlanName": s.paymentPlanName,
            "branchType": s.branchType,
            "branchName": s.branchName,
            "totalReturnAmount": s.totalReturnAmount,
            "totalRefundAmount": s.totalRefundAmount,
            "merchantId": s.merchantId,
            "merchantName": s.merchantName,
            "currency": s.currency,
            "talyOrderId": s.talyOrderId,
            "merchantOrderId": s.merchantOrderId,
            "totalAmount": s.totalAmount,
            "finalAmount": s.finalAmount,
            "settlementStatus": s.settlementStatus,
            "platform": s.platform,
            "purchaseType": s.purchaseType,
            "cardType": s.cardType,
            "discountAmount": s.discountAmount,
            "postBackUrl": s.postBackUrl,
            "merchantLogo": s.merchantLogo,
            "psp": pspNested as Any?
        ]
    }

    /// Flattens a `Codable` value from TalySdk into a JSON-style dictionary for the Flutter method channel.
    private static func encodeToFlutterMap(_ value: some Encodable) -> [String: Any]? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(value),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let dict = obj as? [String: Any] else { return nil }
        return dict
    }
}
