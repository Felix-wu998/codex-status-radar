import Foundation

struct CodexAppServerEndpoint: Equatable {
    let url: URL

    static let `default` = CodexAppServerEndpoint(
        url: URL(string: "ws://127.0.0.1:8794")!
    )
}

final class CodexAppServerClient {
    private let endpoint: CodexAppServerEndpoint
    private var task: URLSessionWebSocketTask?

    init(endpoint: CodexAppServerEndpoint = .default) {
        self.endpoint = endpoint
    }

    func connect() {
        task = URLSession.shared.webSocketTask(with: endpoint.url)
        task?.resume()
    }

    func disconnect() {
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }
}
