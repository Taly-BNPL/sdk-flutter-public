import UIKit
import WebKit
import TalySdk

/// Wraps [PlaceOrderView] with a loading overlay until the payment WebView finishes
/// its first load. Composition is used because `PlaceOrderView` is not `open`.
final class TrackedPlaceOrderView: UIViewController {

    let placeOrderView: PlaceOrderView

    var onWebViewLoaded: (() -> Void)?

    weak var delegate: PlaceOrderDelegate? {
        get { placeOrderView.delegate }
        set { placeOrderView.delegate = newValue }
    }

    var activityIndicatorColor: UIColor {
        get { placeOrderView.activityIndicatorColor }
        set { placeOrderView.activityIndicatorColor = newValue }
    }

    private var loadingOverlay: UIView?
    private var didReportLoad = false
    private var webViewObservation: NSKeyValueObservation?
    private var webViewSearchTimer: Timer?

    private static let indicatorColor = UIColor(
        red: 14.0 / 255.0,
        green: 133.0 / 255.0,
        blue: 255.0 / 255.0,
        alpha: 1.0
    )
    private static let webViewTopPadding: CGFloat = 20
    private static let webViewBottomPadding: CGFloat = 20
    private static let gray100 = UIColor(
        red: 243.0 / 255.0,
        green: 244.0 / 255.0,
        blue: 246.0 / 255.0,
        alpha: 1.0
    )

    init(
        orderRequest: OrderRequest,
        tokenRequest: TokenRequest,
        environment: URLHost,
        languageCode: String?
    ) {
        placeOrderView = PlaceOrderView(
            orderRequest: orderRequest,
            tokenRequest: tokenRequest,
            environment: environment,
            languageCode: languageCode
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        webViewSearchTimer?.invalidate()
        webViewObservation?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Self.gray100
        view.clipsToBounds = true
        embedPlaceOrderView()
        showLoadingOverlay()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        beginWebViewLoadTracking()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let webView = findWebView(in: placeOrderView.view) {
            applyWebViewLayout(webView)
        }
        if let overlay = loadingOverlay {
            overlay.frame = view.bounds
            view.bringSubviewToFront(overlay)
        }
    }

    private func embedPlaceOrderView() {
        addChild(placeOrderView)
        placeOrderView.view.translatesAutoresizingMaskIntoConstraints = false
        placeOrderView.view.clipsToBounds = true
        placeOrderView.view.backgroundColor = Self.gray100
        view.addSubview(placeOrderView.view)
        NSLayoutConstraint.activate([
            placeOrderView.view.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: Self.webViewTopPadding
            ),
            placeOrderView.view.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -Self.webViewBottomPadding
            ),
            placeOrderView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            placeOrderView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        placeOrderView.didMove(toParent: self)
    }

    private func applyWebViewLayout(_ webView: WKWebView) {
        webView.clipsToBounds = true
        webView.isOpaque = false
        webView.backgroundColor = Self.gray100
        webView.scrollView.backgroundColor = Self.gray100
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.contentInset = .zero
        webView.scrollView.scrollIndicatorInsets = .zero
        if #available(iOS 13.0, *) {
            webView.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        }

        guard let container = webView.superview else { return }
        container.backgroundColor = Self.gray100
        let targetFrame = CGRect(
            x: 0,
            y: 0,
            width: container.bounds.width,
            height: container.bounds.height
        )
        if webView.frame != targetFrame {
            webView.frame = targetFrame
            webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
    }

    private func beginWebViewLoadTracking() {
        guard webViewSearchTimer == nil, webViewObservation == nil else { return }

        webViewSearchTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            guard let webView = findWebView(in: placeOrderView.view) else { return }
            timer.invalidate()
            webViewSearchTimer = nil
            applyWebViewLayout(webView)
            observeWebViewLoad(webView)
        }
    }

    private func observeWebViewLoad(_ webView: WKWebView) {
        if !webView.isLoading {
            reportWebViewLoaded()
            return
        }
        webViewObservation = webView.observe(\.isLoading, options: [.new]) { [weak self] webView, _ in
            guard !webView.isLoading else { return }
            self?.reportWebViewLoaded()
        }
    }

    private func findWebView(in view: UIView) -> WKWebView? {
        if let webView = view as? WKWebView { return webView }
        for subview in view.subviews {
            if let found = findWebView(in: subview) { return found }
        }
        return nil
    }

    private func showLoadingOverlay() {
        let overlay = UIView(frame: view.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.backgroundColor = Self.gray100

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = Self.indicatorColor
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()

        overlay.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
        ])

        view.addSubview(overlay)
        loadingOverlay = overlay
    }

    private func reportWebViewLoaded() {
        guard !didReportLoad else { return }
        didReportLoad = true
        webViewObservation?.invalidate()
        webViewObservation = nil
        loadingOverlay?.removeFromSuperview()
        loadingOverlay = nil
        onWebViewLoaded?()
    }
}
