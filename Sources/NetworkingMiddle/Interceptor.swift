import Foundation

/// A protocol for intercepting network requests before they are executed.
public protocol Interceptor: Sendable {
    /// A typealias for the next handler in the chain of interceptors.
    typealias Next = (String, Request) async throws -> Response

    /// Intercepts the network request, performs any modifications or logging, and passes the request to the
    /// next handler.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL of the request.
    ///   - request: The `Request` object to be intercepted.
    ///   - next: A closure representing the next handler to invoke.
    /// - Returns: A `Response` object representing the result of the intercepted request.
    func intercept(baseURL: String, request: Request, next: Next) async throws -> Response
}

/// A factory for creating interceptors.
///
/// Interceptors are used to modify or intercept network requests and responses in a consistent manner,
/// allowing you to add common functionality such as authentication, logging, or request/response validation.
public enum InterceptorFactory: Sendable {
    /// Create a logger interceptor
    /// - Parameter printer: The callback to print the logger description
    /// - Returns: A new `Interceptor`
    public static func interceptorLogger(
        _ printer: @escaping @Sendable (String) -> Void
    ) -> any Interceptor {
        InterceptorLogger(printer)
    }

    /// Create a time logger interceptor
    /// - Parameter printer: The callback to print the logger description
    /// - Returns: A new `Interceptor`
    public static func interceptorTimeLogger(
        _ printer: @escaping @Sendable (String) -> Void
    ) -> any Interceptor {
        InterceptorTimeLogger(printer: printer)
    }
}

struct InterceptorLogger: Interceptor {
    private let printer: @Sendable (String) -> Void

    init(_ printer: @escaping @Sendable (String) -> Void) {
        self.printer = printer
    }

    func intercept(
        baseURL: String,
        request: any Request,
        next: (String, any Request) async throws -> any Response
    ) async throws -> any Response {
        let _next = try await next(baseURL, request)
        printer(_next.description)
        return _next
    }
}

struct InterceptorTimeLogger: Interceptor {
    private let printer: @Sendable (String) -> Void
    private let formatter: NumberFormatter

    init(
        formatter: NumberFormatter = .seconds,
        printer: @escaping @Sendable (String) -> Void
    ) {
        self.formatter = formatter
        self.printer = printer
    }

    func intercept(
        baseURL: String,
        request: any Request,
        next: (String, any Request) async throws -> any Response
    ) async throws -> any Response {
        let startTime = Date()
        let _next = try await next(baseURL, request)
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        if let formattedDuration = formatter.string(from: NSNumber(value: duration)) {
            printer("[Request][Time] \(formattedDuration) seconds")
        } else {
            printer("[Request][Time] \(duration) s")
        }
        return _next
    }
}

extension NumberFormatter {
    static let seconds: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = "."
        return formatter
    }()
}
