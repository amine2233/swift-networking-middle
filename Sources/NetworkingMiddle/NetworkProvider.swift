import Foundation

// sourcery: AutoMockable
/// A protocol defining a network provider capable of sending requests, applying request modifiers, and
/// intercepting requests.
public protocol NetworkProvider: Sendable {
    /// Adds a request modification action to the network provider.
    ///
    /// - Parameter action: A closure that modifies the request before it is sent.
    /// - Returns: The updated `NetworkProvider`.
    func modifyRequests(
        action: @escaping @Sendable (String, inout Request) throws -> Void
    ) -> NetworkProvider

    /// Adds an interceptor action to the network provider.
    ///
    /// - Parameter action: A closure that intercepts and processes the request before it is sent.
    /// - Returns: The updated `NetworkProvider`.
    @discardableResult
    func intercept(
        action: @escaping @Sendable (String, Request, (String, Request) async throws -> Response) async throws
            -> Response
    ) -> NetworkProvider

    /// Sends a network request and returns a response.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL of the request.
    ///   - request: The `Request` object to be sent.
    /// - Returns: A `Response` object representing the result of the request.
    func request(baseURL: String, request: Request) async throws -> Response

    /// Creates a new request builder.
    ///
    /// - Parameters:
    ///   - path: The path for the request.
    ///   - method: The HTTP method for the request.
    ///   - parameters: Optional request parameters.
    ///   - body: Optional request body.
    ///   - headers: Optional headers for the request.
    /// - Returns: A `Request` object representing the new request.
    func newBuilder(
        path: String,
        method: HTTPMethod,
        parameters: RequestParameters?,
        body: RequestBody?,
        headers: [String: String]
    ) -> Request
}

/// A factory for creating network providers with configurable services, modifiers, and interceptors.
public enum NetworkProviderFactory {
    /// Creates a new `NetworkProvider`.
    ///
    /// - Parameters:
    ///   - networkService: The underlying network service responsible for making requests.
    ///   - modifiers: An array of `RequestModifier` objects to modify the requests.
    ///   - interceptors: An array of `Interceptor` objects to intercept and process the requests.
    /// - Returns: A `NetworkProvider` configured with the given services, modifiers, and interceptors.
    public static func create(
        networkService: NetworkService,
        modifiers: [RequestModifier] = [],
        interceptors: [Interceptor] = [],
        configuration: NetworkClientConfiguration = NetworkClientConfiguration()
    ) -> NetworkProvider {
        NetworkClientDefault(
            http: networkService,
            modifiers: modifiers,
            interceptors: interceptors,
            configuration: configuration
        )
    }
}

public struct NetworkClientConfiguration: Sendable {
    public struct Logging: Sendable {
        public init() {}
    }

    public let logging: Logging

    public init(logging: Logging = .init()) {
        self.logging = logging
    }
}

struct NetworkClientDefault: NetworkProvider, Sendable {
    private let http: NetworkService
    private let interceptors: [Interceptor]
    private let modifiers: [RequestModifier]
    private let configuration: NetworkClientConfiguration

    init(
        http: NetworkService,
        modifiers: [RequestModifier] = [],
        interceptors: [Interceptor] = [],
        configuration: NetworkClientConfiguration
    ) {
        self.http = http
        self.interceptors = interceptors
        self.modifiers = modifiers
        self.configuration = configuration
    }

    func newBuilder(
        path: String,
        method: HTTPMethod,
        parameters: RequestParameters? = nil,
        body: RequestBody? = nil,
        headers: [String: String] = [:]
    ) -> Request {
        RequestBuilder(
            path: path,
            method: method,
            parameters: parameters,
            body: body,
            headers: headers
        )
    }

    func modifyRequests(
        action: @escaping @Sendable (String, inout Request) throws -> Void
    ) -> NetworkProvider {
        struct AnonymousModifier: RequestModifier {
            private typealias Action = @Sendable (String, inout Request) throws -> Void

            let action: Action

            func modify(baseURL: String, request: inout Request) throws {
                try action(baseURL, &request)
            }
        }

        var _modifiers = modifiers
        _modifiers.append(AnonymousModifier(action: action))
        return copy(modifiers: _modifiers)
    }

    @discardableResult
    func intercept(
        action: @escaping @Sendable (String, Request, (String, Request) async throws -> Response) async throws
            -> Response
    ) -> NetworkProvider {
        struct AnonymousInterceptor: Interceptor {
            private typealias Action = @Sendable (String, Request, Interceptor.Next) async throws -> Response

            let action: Action

            func intercept(
                baseURL: String,
                request: Request,
                next: Interceptor.Next
            ) async throws -> Response {
                try await action(baseURL, request, next)
            }
        }

        var _interceptors = interceptors
        _interceptors.append(AnonymousInterceptor(action: action))
        return copy(interceptors: _interceptors)
    }

    func request(baseURL: String, request: Request) async throws -> Response { // RequestBuilder
        let builder = try createRequest(baseURL: baseURL, request: request)

        var next: (String, Request) async throws -> Response = http.perform

        for interceptor in interceptors.reversed() {
            let _next = next
            next = { try await interceptor.intercept(baseURL: $0, request: $1, next: _next) }
        }

        return try await next(builder.baseURL, builder.request)
    }

    private func createRequest(
        baseURL: String,
        request: any Request
    ) throws -> (baseURL: String, request: any Request) {
        var _request = request
        for modifier in modifiers {
            try modifier.modify(baseURL: baseURL, request: &_request)
        }
        return (baseURL, _request)
    }

    private func copy(
        http: NetworkService? = nil,
        modifiers: [RequestModifier]? = nil,
        interceptors: [Interceptor]? = nil
    ) -> NetworkClientDefault {
        NetworkClientDefault(
            http: http ?? self.http,
            modifiers: modifiers ?? self.modifiers,
            interceptors: interceptors ?? self.interceptors,
            configuration: configuration
        )
    }
}
