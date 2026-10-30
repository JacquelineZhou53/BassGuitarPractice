import SwiftUI
import WebKit

struct NotationWebView: UIViewRepresentable {
    let musicXML: String
    @Binding var renderedHeight: CGFloat
    @Binding var isReady: Bool
    var onNoteClicked: ((Int?) -> Void)? = nil

    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "notationBridge")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator
        
        context.coordinator.webView = webView

        loadHTML(in: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.lastMusicXML != musicXML && context.coordinator.isOSMDReady {
            renderMusicXML(musicXML, in: webView)
            context.coordinator.lastMusicXML = musicXML
        }
    }

    private func loadHTML(in webView: WKWebView) {
        guard let htmlPath = Bundle.main.path(forResource: "notation_template", ofType: "html") else {
            webView.loadHTMLString(fallbackHTML, baseURL: nil)
            return
        }

        let htmlURL = URL(fileURLWithPath: htmlPath)
        webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
    }

    func renderMusicXML(_ xml: String, in webView: WKWebView) {
        let escaped = xml
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")

        let js = "loadAndRender(`\(escaped)`);"
        webView.evaluateJavaScript(js) { result, error in
            if let error = error {
                print("JavaScript error: \(error)")
            }
        }
    }

    func highlightNote(at index: Int?, in webView: WKWebView) {
        let js: String
        if let idx = index {
            js = "highlightNote(0, \(idx));"
        } else {
            js = "clearHighlights();"
        }
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    private var fallbackHTML: String {
        """
        <!DOCTYPE html>
        <html>
        <head><style>body{font-family:sans-serif;padding:20px;color:#666;}</style></head>
        <body>
        <p>OSMD resources not found. Please add OpenSheetMusicDisplay files to the app bundle.</p>
        <script>
        if (window.webkit && window.webkit.messageHandlers.notationBridge) {
            window.webkit.messageHandlers.notationBridge.postMessage({type: "error", data: {message: "OSMD not bundled"}});
        }
        </script>
        </body>
        </html>
        """
    }
}

class WebViewCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    var parent: NotationWebView
    var isOSMDReady = false
    var lastMusicXML: String? = nil
    weak var webView: WKWebView?

    init(_ parent: NotationWebView) {
        self.parent = parent
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("WebView finished loading")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "notationBridge" else { return }

        guard let body = message.body as? [String: Any],
              let type = body["type"] as? String else { return }

        let data = body["data"] as? [String: Any] ?? [:]

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            switch type {
            case "initialized":
                self.isOSMDReady = true
                self.parent.isReady = true
                if let xml = self.lastMusicXML ?? Optional(self.parent.musicXML),
                   let webView = self.webView {
                    self.parent.renderMusicXML(xml, in: webView)
                    self.lastMusicXML = xml
                }

            case "rendered":
                if let height = data["height"] as? CGFloat {
                    self.parent.renderedHeight = height
                }

            case "noteClicked":
                self.parent.onNoteClicked?(nil)

            case "error":
                let message = data["message"] as? String ?? "Unknown error"
                print("Notation error: \(message)")

            default:
                break
            }
        }
    }
}
