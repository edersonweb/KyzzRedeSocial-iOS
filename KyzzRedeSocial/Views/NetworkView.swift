import SwiftUI
import UIKit
import WebKit

struct NetworkView: View {
    @ObservedObject var model: WebViewModel

    var body: some View {
        ZStack(alignment: .top) {
            WebView(model: model)

            if model.isLoading && model.hasLoadedOnce {
                ProgressView(value: model.progress)
                    .progressViewStyle(.linear)
                    .tint(Theme.secondary)
                    .frame(height: 3)
                    .background(Color.white.opacity(0.5))
            }

            if let message = model.errorMessage {
                NetworkErrorView(message: message) {
                    model.reload()
                }
            } else if !model.hasLoadedOnce {
                NetworkLoadingView()
            }
        }
        .background(Theme.background.ignoresSafeArea())
    }
}

@MainActor
final class WebViewModel: ObservableObject {
    @Published var progress: Double = 0
    @Published var isLoading = false
    @Published var hasLoadedOnce = false
    @Published var errorMessage: String?

    var pendingURL: URL = AppConfig.signupURL
    weak var webView: WKWebView?

    func open(url: URL) {
        pendingURL = url
        errorMessage = nil
        isLoading = true

        if let webView {
            webView.load(URLRequest(url: url))
        }
    }

    func reload() {
        errorMessage = nil
        isLoading = true

        guard let webView else { return }

        if webView.url != nil {
            webView.reload()
        } else {
            webView.load(URLRequest(url: pendingURL))
        }
    }
}

struct WebView: UIViewRepresentable {
    @ObservedObject var model: WebViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 13.0 / 255.0, green: 59.0 / 255.0, blue: 102.0 / 255.0, alpha: 1)
        webView.scrollView.backgroundColor = .white
        webView.applicationNameForUserAgent = "KyzzRedeSocial/1.0"

        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor(red: 13.0 / 255.0, green: 59.0 / 255.0, blue: 102.0 / 255.0, alpha: 1)
        refreshControl.addTarget(
            context.coordinator,
            action: #selector(Coordinator.refresh(_:)),
            for: .valueChanged
        )
        webView.scrollView.refreshControl = refreshControl

        context.coordinator.webView = webView
        context.coordinator.startObservingProgress()

        model.webView = webView
        model.isLoading = true
        webView.load(URLRequest(url: model.pendingURL))

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.model = model
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        coordinator.stopObservingProgress()
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var model: WebViewModel
        weak var webView: WKWebView?
        private var progressObservation: NSKeyValueObservation?

        init(model: WebViewModel) {
            self.model = model
        }

        func startObservingProgress() {
            guard let webView else { return }

            progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
                let progress = webView.estimatedProgress
                Task { @MainActor [weak self] in
                    self?.model.progress = progress
                }
            }
        }

        func stopObservingProgress() {
            progressObservation?.invalidate()
            progressObservation = nil
        }

        @objc func refresh(_ sender: UIRefreshControl) {
            webView?.reload()
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            Task { @MainActor in
                self.model.isLoading = true
                self.model.errorMessage = nil
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                self.model.isLoading = false
                self.model.hasLoadedOnce = true
                self.model.errorMessage = nil
                webView.scrollView.refreshControl?.endRefreshing()
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handleFailure(error)
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            handleFailure(error)
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            webView.reload()
        }

        private func handleFailure(_ error: Error) {
            Task { @MainActor in
                self.model.isLoading = false
                self.webView?.scrollView.refreshControl?.endRefreshing()

                let nsError = error as NSError
                if nsError.code != NSURLErrorCancelled {
                    self.model.errorMessage = "Verifique sua conexão com a internet e tente novamente."
                }
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            let scheme = url.scheme?.lowercased() ?? ""

            if ["about", "blob", "data"].contains(scheme) {
                decisionHandler(.allow)
                return
            }

            if scheme != "http" && scheme != "https" {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            if let host = url.host?.lowercased(),
               AppConfig.allowedHosts.contains(where: { host == $0 || host.hasSuffix("." + $0) }) {
                decisionHandler(.allow)
            } else {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            }
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptAlertPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping () -> Void
        ) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
            topViewController()?.present(alert, animated: true)
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptConfirmPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (Bool) -> Void
        ) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel) { _ in completionHandler(false) })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
            topViewController()?.present(alert, animated: true)
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptTextInputPanelWithPrompt prompt: String,
            defaultText: String?,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (String?) -> Void
        ) {
            let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.text = defaultText
            }
            alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel) { _ in completionHandler(nil) })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completionHandler(alert.textFields?.first?.text)
            })
            topViewController()?.present(alert, animated: true)
        }

        private func topViewController() -> UIViewController? {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first(where: { $0.isKeyWindow }),
                  let root = window.rootViewController else {
                return nil
            }

            var top = root
            while let presented = top.presentedViewController {
                top = presented
            }
            return top
        }
    }
}

private struct NetworkLoadingView: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 16) {
                Image("LogoKyzz")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)

                Text("Abrindo a Rede Social...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.textSecondary)

                ProgressView()
                    .tint(Theme.primary)
            }
        }
    }
}

private struct NetworkErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 44))
                    .foregroundColor(Theme.primary)

                Text("Não foi possível conectar")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Theme.primary)

                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)

                Button(action: retry) {
                    Text("Tentar novamente")
                }
                .buttonStyle(FilledButtonStyle())
                .padding(.top, 8)
            }
            .padding(32)
        }
    }
}
