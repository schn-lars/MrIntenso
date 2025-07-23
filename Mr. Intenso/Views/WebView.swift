import WebKit
import Foundation
import SwiftUI

/**
 
    Code from https://sarunw.com/posts/swiftui-webview/
 
 */

struct WebView: UIViewRepresentable {
    @Binding var webView: WKWebView
    var url: URL
    var state: WebViewState

    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    // here we could possibly add logic to reload, extraction???
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }
        

    func makeCoordinator() -> Coordinator {
        Coordinator(self, state: state)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var state: WebViewState

        init(_ parent: WebView, state: WebViewState) {
            self.parent = parent
            self.state = state
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            state.canGoBack = webView.canGoBack
            state.canGoForward = webView.canGoForward
            
            let currentURL = webView.url?.absoluteString ?? "Unknown URL"
            print("Finished loading of \(currentURL)")
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            state.canGoBack = webView.canGoBack
            state.canGoForward = webView.canGoForward
        }
    }
}

// We need something to track the state. Because webView does not know when things change on its own
class WebViewState: ObservableObject {
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
}

struct WebObjectView: View {
    var url: URL?
    var errorMessage: String?
    @State private var webView = WKWebView()
    @StateObject private var webViewState = WebViewState()

    var body: some View {
        VStack {
            if let error = errorMessage {
                Text(error)
            } else if let url = url {
                WebView(webView: $webView, url: url, state: webViewState)
                    .frame(maxHeight: .infinity)

                HStack {
                    Button(action: {
                        if webViewState.canGoBack {
                            webView.goBack()
                        }
                    }) {
                        Label("Back", systemImage: "chevron.left")
                            .labelsHidden()
                    }
                    .disabled(!webViewState.canGoBack)
                    Spacer()
                    Button(action: {
                        if webViewState.canGoForward {
                            webView.goForward()
                        }
                    }) {
                        Label("Forward", systemImage: "chevron.right")
                            .labelsHidden()
                    }
                    .disabled(!webViewState.canGoForward)
                }
                .padding()
            }
        }
    }
}
