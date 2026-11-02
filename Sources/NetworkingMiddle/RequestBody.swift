import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A protocol representing request parameters that can be applied to a `URLRequest`.
/// It allows customization or modification of the `URLRequest` with additional parameters.
public protocol RequestBody: Sendable {
    /// Applies the parameters to a given `URLRequest`.
    ///
    /// - Parameter urlRequest: The original `URLRequest` to modify.
    /// - Returns: A modified `URLRequest` with the applied parameters.
    /// - Throws: An error if applying the parameters fails.
    func apply(urlRequest: URLRequest) async throws -> URLRequest
}

/// A factory enum for creating various types of `RequestParameters`.
/// This provides different implementations to apply parameters to `URLRequest` such as encoding models, JSON,
/// or query parameters.
public enum RequestBodyFactory: Sendable {
    /// Creates `RequestBody` for an encodable model.
    ///
    /// - Parameter model: An encodable model that will be applied to the request.
    /// - Returns: A `RequestParameters` instance for the encodable model.
    public static func encodableBody<T: Encodable & Sendable>(
        model: T,
        encoder: JSONEncoder = JSONEncoder()
    ) -> any RequestBody {
        EncodableBodyRequest(model, encoder: encoder)
    }

    /// Creates `RequestBody` for form parameters.
    ///
    /// - Parameter data: A dictionary representing query parameters to be applied to the request.
    /// - Returns: A `RequestParameters` instance for the query parameters.
    public static func formBody(data: [String: any Sendable]) -> any RequestBody {
        FormBodyRequest(data)
    }

    /// Creates `RequestBody` for a generic JSON object.
    ///
    /// - Parameter model: A generic JSON object to be applied to the request.
    /// - Returns: A `RequestParameters` instance for the JSON object.
    public static func jsonBody(
        model: any Sendable
    ) -> any RequestBody {
        JSONBodyRequest(model)
    }

    /// Creates `RequestBody` with a string.
    ///
    /// - Parameter value: A String to be applied to the request
    public static func stringBody(
        _ value: String
    ) -> any RequestBody {
        StringBodyRequest(value)
    }

    /// Creates `RequestBody` with a data.
    ///
    /// - Parameter value: A String to be applied to the request
    public static func dataBody(
        _ value: Data
    ) -> any RequestBody {
        DataBodyRequest(value)
    }
}

/// Create a body with `Encodable` object
struct EncodableBodyRequest: RequestBody {
    let model: any Encodable & Sendable
    let encoder: JSONEncoder

    init(_ model: any Encodable & Sendable, encoder: JSONEncoder = JSONEncoder()) {
        self.encoder = encoder
        self.model = model
    }

    func apply(urlRequest: URLRequest) throws -> URLRequest {
        var request = urlRequest
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let data = try encoder.encode(model)
            request.httpBody = data
        } catch {
            throw APIError.requestParameters(error)
        }

        return request
    }
}

/// Create a `FormParameters`
struct FormBodyRequest: RequestBody {
    let data: [String: any Sendable]

    init(_ data: [String: any Sendable]) {
        self.data = data
    }

    func apply(urlRequest: URLRequest) -> URLRequest {
        var request = urlRequest
        request.setValue(
            "application/x-www-form-urlencoded;charset=UTF-8",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = data.keyValuePairs.data(using: .utf8)
        return request
    }
}

/// Create a `JSONParameters`
struct JSONBodyRequest: RequestBody {
    let json: any Sendable

    init(_ json: any Sendable) {
        self.json = json
    }

    func apply(urlRequest: URLRequest) throws -> URLRequest {
        var request = urlRequest
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            request.httpBody = data
        } catch {
            throw APIError.requestParameters(error)
        }

        return request
    }
}

/// Create a `StringParameter`
struct StringBodyRequest: RequestBody {
    let string: String

    init(_ string: String) {
        self.string = string
    }

    func apply(urlRequest: URLRequest) -> URLRequest {
        var request = urlRequest
        request.httpBody = string.data(using: .utf8)
        return request
    }
}

/// Create a `DataParameter`
struct DataBodyRequest: RequestBody {
    let data: Data

    init(_ data: Data) {
        self.data = data
    }

    func apply(urlRequest: URLRequest) -> URLRequest {
        var request = urlRequest
        request.httpBody = data
        return request
    }
}
