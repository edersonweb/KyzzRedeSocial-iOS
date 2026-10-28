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
        configuration.applicationNameForUserAgent = "KyzzRedeSocial/1.0"

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 13.0 / 255.0, green: 59.0 / 255.0, blue: 102.0 / 255.0, alpha: 1)
        webView.scrollView.backgroundColor = .white

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
        private static let rememberTokenKey = "kyzz_remember_token"

        var model: WebViewModel
        weak var webView: WKWebView?
        private var progressObservation: NSKeyValueObservation?
        private var didAttemptReauth = false

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

            hideCommercialLinks(in: webView)
            injectBackButtonIfNeeded(in: webView)
            captureRememberToken()
            attemptTokenReauthentication(in: webView)
        }

        /// Mostra um botão flutuante "Voltar" nas páginas internas (ex.: exclusão de conta).
        private func injectBackButtonIfNeeded(in webView: WKWebView) {
            let path = webView.url?.path.lowercased() ?? ""
            guard !path.hasSuffix("rede_social.php"), !path.hasSuffix("cadastro_rede_social.php") else { return }

            let script = """
            (function() {
                if (document.getElementById('kyzz-app-back')) { return; }
                var b = document.createElement('button');
                b.id = 'kyzz-app-back';
                b.textContent = '‹ Voltar';
                b.style.cssText = 'position:fixed;top:10px;left:10px;z-index:2147483647;background:rgba(13,59,102,0.92);color:#fff;border:0;border-radius:18px;padding:7px 16px;font:600 14px -apple-system,system-ui,sans-serif;box-shadow:0 2px 8px rgba(0,0,0,0.3)';
                b.addEventListener('click', function() {
                    if (window.history.length > 1) {
                        window.history.back();
                    } else {
                        window.location.href = 'https://kyzz.com.br/cadastro_rede_social.php';
                    }
                });
                document.body.appendChild(b);
            })();
            """
            webView.evaluateJavaScript(script, completionHandler: nil)
        }

        /// Remove do conteúdo qualquer link para páginas comerciais (planos/escolas) e para a home do site.
        private func hideCommercialLinks(in webView: WKWebView) {
            let script = """
            (function() {
                var style = document.getElementById('kyzz-app-hide-commercial');
                if (!style) {
                    style = document.createElement('style');
                    style.id = 'kyzz-app-hide-commercial';
                    document.head.appendChild(style);
                }
                style.textContent = 'a[href*="kyzz_para_escolas"], a[href*="checkout_plano"], a[href*="obrigado_plano"], a[href$="index.php"], a[href="/"], a[href="../"], .btn-voltar-inicio { display: none !important; }';
            })();
            """
            webView.evaluateJavaScript(script, completionHandler: nil)
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

            if let host = url.host?.lowercased(),
               (host == "kyzz.com.br" || host.hasSuffix(".kyzz.com.br")),
               url.path.lowercased().contains("logout") {
                KeychainStore.delete(Self.rememberTokenKey)
            }

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
                let path = url.path.lowercased()
                if AppConfig.blockedPaths.contains(where: { path.hasSuffix($0) }) {
                    decisionHandler(.cancel)
                    if path.hasSuffix("index.php") {
                        // Home comercial do site: volta para a página principal do aplicativo.
                        webView.load(URLRequest(url: AppConfig.signupURL))
                    } else {
                        showUnavailableAlert()
                    }
                    return
                }
                decisionHandler(.allow)
            } else {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            }
        }

        private func showUnavailableAlert() {
            let alert = UIAlertController(
                title: "Indisponível no aplicativo",
                message: "Este conteúdo não está disponível no aplicativo do Kyzz.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            topViewController()?.present(alert, animated: true)
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

        private func captureRememberToken() {
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
                guard let token = cookies.first(where: {
                    $0.name == Self.rememberTokenKey && $0.domain.lowercased().contains("kyzz.com.br")
                })?.value, token.count > 20 else {
                    return
                }

                KeychainStore.save(token, for: Self.rememberTokenKey)
            }
        }

        private func attemptTokenReauthentication(in webView: WKWebView) {
            guard !didAttemptReauth else { return }
            guard let host = webView.url?.host?.lowercased(),
                  host == "kyzz.com.br" || host.hasSuffix(".kyzz.com.br") else {
                return
            }
            guard let token = KeychainStore.read(Self.rememberTokenKey), token.count > 20 else {
                didAttemptReauth = true
                return
            }

            didAttemptReauth = true

            let script = """
            const response = await fetch('/actions/login_token.php', {
                method: 'POST',
                credentials: 'include',
                headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                body: 'token=\(token)'
            });
            return await response.text();
            """

            webView.callAsyncJavaScript(script, arguments: [:], in: nil, in: .page) { [weak webView] result in
                guard let webView else { return }

                guard case .success(let value) = result,
                      let text = value as? String,
                      let data = text.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let ok = json["ok"] as? Bool else {
                    return
                }

                if ok {
                    Task { @MainActor in
                        webView.load(URLRequest(url: AppConfig.feedURL))
                    }
                } else {
                    KeychainStore.delete(Self.rememberTokenKey)
                }
            }
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
