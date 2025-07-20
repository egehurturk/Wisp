import SwiftUI
import WebKit

struct DotLottieView: UIViewRepresentable {
    let url: String
    let animationSpeed: Float
    let looping: Bool
    
    init(url: String, animationSpeed: Float = 1.0, looping: Bool = true) {
        self.url = url
        self.animationSpeed = animationSpeed
        self.looping = looping
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = UIColor.clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    background: transparent;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    overflow: hidden;
                }
                dotlottie-player {
                    max-width: 100%;
                    max-height: 100%;
                }
            </style>
            <script src="https://unpkg.com/@dotlottie/player-component@latest/dist/dotlottie-player.mjs" type="module"></script>
        </head>
        <body>
            <dotlottie-player 
                src="\(url)" 
                background="transparent" 
                speed="\(animationSpeed)" 
                style="width: 100%; height: 100%;" 
                \(looping ? "loop" : "") 
                autoplay>
            </dotlottie-player>
        </body>
        </html>
        """
        
        webView.loadHTMLString(htmlString, baseURL: nil)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed for this implementation
    }
}

