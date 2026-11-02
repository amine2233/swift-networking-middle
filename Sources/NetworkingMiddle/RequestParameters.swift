import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A protocol representing request parameters that can be applied to a `URLRequest`.
/// It allows customization or modification of the `URLRequest` with additional parameters.
public protocol RequestParameters: Sendable {
    /// Applies the parameters to a given `URLRequest`.
    ///
    /// - Parameter urlRequest: The original `URLRequest` to modify.
    /// - Returns: A modified `URLRequest` with the applied parameters.
    /// - Throws: An error if applying the parameters fails.
    func apply(urlRequest: URLRequest) throws -> URLRequest
}

/// A factory enum for creating various types of `RequestParameters`.
/// This provides different implementations to apply parameters to `URLRequest` such as encoding models, JSON,
/// or query parameters.
public enum RequestParametersFactory: Sendable {
    /// Creates `RequestParameters` for query parameters.
    ///
    /// - Parameter query: A dictionary representing query parameters to be applied to the request.
    /// - Returns: A `RequestParameters` instance for the query parameters.
    public static func queryParameters(
        query: [String: String]
    ) -> RequestParameters {
        QueryParameters(query)
    }

    /// Converts an `Encodable` object into a `RequestParameters` instance using JSON encoding.
    ///
    /// This function encodes the given `query` object and wraps it in a `RequestParameters`
    /// implementation, making it suitable for use in URL query strings or request bodies.
    ///
    /// - Parameters:
    ///   - query: An object conforming to `Encodable` to be converted into parameters.
    ///   - encoder: A `JSONEncoder` used to encode the object. Defaults to a new `JSONEncoder` instance.
    ///   - options: Options for how the resulting JSON is read. Defaults to an empty set.
    /// - Returns: A `RequestParameters` instance wrapping the encoded parameters.
    public static func queryEncodableParameters(
        _ query: any Encodable & Sendable,
        using encoder: JSONEncoder = .init(),
        options: JSONSerialization.ReadingOptions = []
    ) -> RequestParameters {
        QueryParametersEncodable(
            query,
            using: encoder,
            options: options
        )
    }

    public static func stringRequestParameters(
        _ query: String
    ) -> RequestParameters {
        RequestParametersString(string: query)
    }
}

/// Create a `QueryParameters`
struct QueryParameters: RequestParameters {
    let query: [String: String]

    init(_ query: [String: String]) {
        self.query = query
    }

    func apply(urlRequest: URLRequest) -> URLRequest {
        var request = urlRequest
        guard let url = request.url else { return urlRequest }
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return urlRequest
        }

        var items = urlComponents.queryItems ?? []
        items.append(contentsOf: query.map { URLQueryItem(name: $0.key, value: $0.value) })
        urlComponents.queryItems = items
        request.url = urlComponents.url
        return request
    }
}

struct QueryParametersEncodable: RequestParameters {
    private let query: any Encodable & Sendable
    private let encoder: JSONEncoder
    private let options: JSONSerialization.ReadingOptions

    init(
        _ query: any Encodable & Sendable,
        using encoder: JSONEncoder = .init(),
        options: JSONSerialization.ReadingOptions = []
    ) {
        self.query = query
        self.encoder = encoder
        self.options = options
    }

    func apply(urlRequest: URLRequest) throws -> URLRequest {
        var request = urlRequest
        guard let url = request.url else { return urlRequest }
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return urlRequest
        }

        var items = urlComponents.queryItems ?? []
        let dictionary: [String: Any] = try query.dictionary(using: encoder, options: options)
        items.append(contentsOf: dictionary.map { URLQueryItem(name: $0.key, value: "\($0.value)") })
        urlComponents.queryItems = items
        request.url = urlComponents.url
        return request
    }
}

struct RequestParametersString: RequestParameters {
    let string: String

    func apply(urlRequest: URLRequest) throws -> URLRequest {
        let items = string.split(separator: "&")
            .reduce(into: [String: String]()) { partialResult, queryItem in
                let parts = queryItem.split(separator: "=", maxSplits: 1)
                guard !parts.isEmpty else { return }

                let key = String(parts[0])
                let value = parts.count > 1 ? String(parts[1]) : ""
                partialResult[key] = value
            }

        return QueryParameters(items)
            .apply(urlRequest: urlRequest)
    }
}
