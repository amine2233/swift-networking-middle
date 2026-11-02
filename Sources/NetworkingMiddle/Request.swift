import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// The HTTP request method types.
public struct HTTPMethod: RawRepresentable, Sendable, Equatable {
    /// The raw value of the HTTP method.
    public let rawValue: String

    /// Creates an instance of `HTTPMethod` with the given raw value.
    ///
    /// - Parameter rawValue: The raw value of the HTTP method.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension HTTPMethod {
    /// The GET method requests a representation of the specified resource.
    public static let get = HTTPMethod(rawValue: "GET")

    /// The PUT method replaces all current representations of the target resource with the request payload.
    public static let put = HTTPMethod(rawValue: "PUT")

    /// The POST method is used to submit an entity to the specified resource, often causing a change in state
    /// or side effects on the server.
    public static let post = HTTPMethod(rawValue: "POST")

    /// The PATCH method is used to apply partial modifications to a resource.
    public static let patch = HTTPMethod(rawValue: "PATCH")

    /// The DELETE method deletes the specified resource.
    public static let delete = HTTPMethod(rawValue: "DELETE")

    /// The HEAD method requests the headers that would be returned if the specified resource were requested.
    public static let head = HTTPMethod(rawValue: "HEAD")
}

/// The possible errors related to requests.
public enum RequestError: Swift.Error, Sendable {
    case cantHandleEmptyData
    case cantConvertEmptyData
    case invalidURL(String)

    /// A human-readable description of the error.
    public var failureRaison: String {
        switch self {
        case .cantHandleEmptyData:
            "Can't handle empty response, this request doesn't return an empty data"
        case .cantConvertEmptyData:
            "Can't convert EmptyResponse to a valid resource"
        case let .invalidURL(url):
            "Can't create URL(\(url))"
        }
    }
}

/// A protocol that defines a network request with its essential components.
public protocol Request: Sendable {
    /// The path
    var path: String { get }
    /// The method
    var method: HTTPMethod { get }
    /// The query parameters
    var parameters: (any RequestParameters)? { get }
    /// The body parameters
    var body: (any RequestBody)? { get }
    /// The headers parameter
    var headers: [String: String] { get }
}

/// A factory enum for creating `Request` instances with various parameters.
public enum RequestFactory: Sendable {
    /// Creates a new `Request` instance.
    ///
    /// - Parameters:
    ///   - path: The path for the request.
    ///   - method: The HTTP method for the request.
    ///   - parameters: The query parameters to be applied to the request.
    ///   - body: The body parameters to be applied to the request.
    ///   - headers: A dictionary of headers to be applied to the request.
    /// - Returns: A `Request` instance.
    public static func create(
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
}

extension Request {
    /// Converts the current request into a `URLRequest` using the provided base URL.
    ///
    /// This method resolves the full URL by combining the `baseURL` and request path,
    /// and applies method, headers, parameters, and body to build the final `URLRequest`.
    ///
    /// - Parameter baseURL: The base URL to prepend to the request's path.
    /// - Returns: A fully-formed `URLRequest` ready for execution.
    /// - Throws: An error if parameters or body application fails.
    public func asURLRequest(baseURL: String) async throws -> URLRequest {
        let url = try requestUrl(baseURL: baseURL)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        headers.forEach { urlRequest.addValue($1, forHTTPHeaderField: $0) }

        if let parameters {
            do {
                urlRequest = try parameters.apply(urlRequest: urlRequest)
            } catch {
                throw APIError.requestParameters(error)
            }
        }

        if let body {
            do {
                urlRequest = try await body.apply(urlRequest: urlRequest)
            } catch {
                throw APIError.body(error)
            }
        }

        return urlRequest
    }

    /// Returns a new request with the `Authorization` header set to a bearer token.
    ///
    /// - Parameter bearer: The bearer token value.
    /// - Returns: A modified request with the `Authorization` header.
    public func authorised(bearer: String) -> any Request {
        set("Bearer " + bearer, forHttpHeaderKey: "Authorization")
    }

    /// Mutates the request by setting the `Authorization` header to a bearer token.
    ///
    /// - Parameter value: The bearer token value.
    /// - Returns: A modified request with the `Authorization` header.
    public mutating func bearer(_ value: String) -> any Request {
        set("Bearer " + value, forHttpHeaderKey: "Authorization")
    }

    /// Returns a new request with the `Authorization` header set to a plain token.
    ///
    /// - Parameter token: The token value.
    /// - Returns: A modified request with the `Authorization` header.
    public func token(token: String) -> any Request {
        set("token " + token, forHttpHeaderKey: "Authorization")
    }

    /// Returns a new request with a custom HTTP header key and value.
    ///
    /// - Parameters:
    ///   - value: The header value to set. If `nil`, the header is removed.
    ///   - key: The HTTP header field name.
    /// - Returns: A modified request with the updated headers.
    public func set(_ value: String?, forHttpHeaderKey key: String) -> any Request {
        var headers = headers
        headers[key] = value
        return RequestBuilder(
            path: path,
            method: method,
            parameters: parameters,
            body: body,
            headers: headers
        )
    }

    /// Create an url
    /// - Parameter request: The `Request` object, to configure url
    /// - Returns: The `URL`
    private func requestUrl(baseURL: String) throws -> URL {
        let urlString = baseURL.appendingPathComponent(path)
        guard let url = URL(string: urlString) else {
            throw RequestError.invalidURL(urlString)
        }

        return url
    }
}

/// The request builder `Request`
struct RequestBuilder: Request {
    /// The request path
    let path: String
    /// The request method type `HTTPMethod`
    let method: HTTPMethod
    /// The query parameters
    let parameters: RequestParameters?
    /// The content body
    let body: RequestBody?
    /// The headers parameters
    let headers: [String: String]

    /// Create a new Request
    init(
        path: String,
        method: HTTPMethod,
        parameters: RequestParameters? = nil,
        body: RequestBody? = nil,
        headers: [String: String] = [:]
    ) {
        self.path = path
        self.method = method
        self.parameters = parameters
        self.body = body
        self.headers = headers
    }
}

/// A type-erased wrapper around any type conforming to the `Request` protocol.
///
/// `AnyRequest` enables you to store or pass around heterogeneous `Request` values
/// in a type-safe and uniform way.
public struct AnyRequest: Request, Sendable {
    /// The path component of the request URL.
    public let path: String

    /// The HTTP method to be used (e.g., GET, POST).
    public let method: HTTPMethod

    /// Optional query parameters for the request.
    public let parameters: (any RequestParameters)?

    /// Optional body content for the request.
    public let body: (any RequestBody)?

    /// HTTP headers to include in the request.
    public let headers: [String: String]

    /// Creates an `AnyRequest` by wrapping another request.
    ///
    /// - Parameter request: A concrete type conforming to the `Request` protocol.
    public init(_ request: any Request) {
        self.path = request.path
        self.method = request.method
        self.parameters = request.parameters
        self.body = request.body
        self.headers = request.headers
    }

    /// Creates an `AnyRequest` by lazily evaluating a closure that returns a `Request`.
    ///
    /// - Parameter request: A closure that returns a `Request` when invoked.
    public init(_ request: () -> any Request) {
        let _request = request()
        self.init(_request)
    }
}

extension Request {
    /// transform request into `AnyRequest`
    public func toAnyRequest() -> AnyRequest {
        AnyRequest(self)
    }
}
