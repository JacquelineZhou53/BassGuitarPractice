import SwiftUI
import WebKit

struct NotationView: View {
    let musicXML: String
    @State private var isReady = false
    @State private var renderedHeight: CGFloat = 200
    @State private var renderedWidth: CGFloat = 800
    @State private var webView: WKWebView?

    var body: some View {
        ZStack(alignment: .center) {
            Color(.systemBackground)

            if let webView = webView {
                ScrollView(.horizontal, showsIndicators: true) {
                    WebViewContainer(webView: webView)
                        .frame(height: max(renderedHeight, 200))
                        .frame(width: renderedWidth)
                }
            }

            if !isReady {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("渲染中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color(.systemBackground).opacity(0.9))
            }
        }
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onAppear {
            if webView == nil {
                setupWebView()
            }
        }
        .onChange(of: musicXML) { _, newXML in
            if isReady {
                renderMusicXML(newXML)
            }
        }
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        let coordinator = NotationCoordinator(
            onReady: { 
                self.isReady = true
                // WebView初始化完成后，立即渲染当前的musicXML
                if !self.musicXML.isEmpty {
                    self.renderMusicXML(self.musicXML)
                }
            },
            onRendered: { height, width in
                self.renderedHeight = max(height, 100)
                self.renderedWidth = max(width, 800)
            },
            onError: { msg in
                print("Notation error: \(msg)")
            }
        )
        config.userContentController.add(coordinator, name: "notationBridge")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = coordinator
        webView.isInspectable = true

        self.webView = webView

        loadHTML(in: webView)
    }

    private func loadHTML(in webView: WKWebView) {
        guard let htmlPath = Bundle.main.path(forResource: "notation_template", ofType: "html") else {
            print("ERROR: notation_template.html not found in bundle")
            print("Bundle path: \(Bundle.main.bundlePath)")
            let files = try? FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath)
            print("Bundle contents: \(files ?? [])")
            return
        }

        do {
            let htmlContent = try String(contentsOfFile: htmlPath, encoding: .utf8)
            let baseURL = URL(fileURLWithPath: Bundle.main.bundlePath)
            print("Loading HTML with baseURL: \(baseURL)")
            webView.loadHTMLString(htmlContent, baseURL: baseURL)
        } catch {
            print("ERROR: Failed to load HTML: \(error)")
        }
    }

    private func renderMusicXML(_ xml: String) {
        guard let webView = webView else { return }
        let escaped = xml
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
        let js = "loadAndRender(`\(escaped)`);"
        webView.evaluateJavaScript(js) { _, error in
            if let error = error {
                print("Notation JS error: \(error)")
            }
        }
    }
}

class NotationCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    let onReady: () -> Void
    let onRendered: (CGFloat, CGFloat) -> Void
    let onError: (String) -> Void

    init(onReady: @escaping () -> Void, onRendered: @escaping (CGFloat, CGFloat) -> Void, onError: @escaping (String) -> Void) {
        self.onReady = onReady
        self.onRendered = onRendered
        self.onError = onError
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("WebView finished loading HTML")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "notationBridge" else { return }
        guard let body = message.body as? [String: Any],
              let type = body["type"] as? String else { return }
        let data = body["data"] as? [String: Any] ?? [:]

        switch type {
        case "initialized":
            print("OSMD initialized")
            onReady()
        case "rendered":
            let height = data["height"] as? CGFloat ?? 200
            let width = data["width"] as? CGFloat ?? 800
            onRendered(height, width)
        case "error":
            let msg = data["message"] as? String ?? "Unknown"
            onError(msg)
        case "debug":
            let msg = data["message"] as? String ?? "Unknown"
            print("JS Debug: \(msg)")
        default:
            break
        }
    }
}

struct WebViewContainer: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
