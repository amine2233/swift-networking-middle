import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import AnyCodable

/// AnyHashable's Sendable conformance in the stdlib is marked @available(*, unavailable),
/// so [AnyHashable: AnyCodable] (used for response headers) requires this explicit assertion.
extension AnyHashable: @unchecked @retroactive Sendable {}

/// A protocol representing a network response, which includes body, headers, status code, and potential
/// error.
public protocol Response: Sendable, CustomStringConvertible {
    /// The request
    var request: URLRequest { get }
    /// The body response
    var body: Data? { get }
    /// The header response
    var headers: [AnyHashable: AnyCodable] { get }
    /// The status code response
    var statusCode: Int { get }
    /// The error response
    var error: Error? { get }
}

/// The any response
public struct AnyResponse: Response {
    /// The request
    public let request: URLRequest
    /// The body response
    public let body: Data?
    /// The header response
    public let headers: [AnyHashable: AnyCodable]
    /// The status code response
    public let statusCode: Int
    /// The error response
    public let error: Error?

    /// Create an AnyResponse using a response
    ///
    /// - Parameter response: The `Response`
    public init(_ response: any Response) {
        self.request = response.request
        self.body = response.body
        self.headers = response.headers
        self.statusCode = response.statusCode
        self.error = response.error
    }
}

/// A default implementation of the `Response` protocol, allowing initialization of response components like
/// body, headers, status code, and error.
struct ResponseDefault: Response {
    var request: URLRequest
    var statusCode: Int
    var body: Data?
    var headers: [AnyHashable: AnyCodable]
    var error: Error?

    init(
        request: URLRequest,
        statusCode: Int,
        body: Data? = nil,
        headers: [AnyHashable: AnyCodable] = [:],
        error: Error? = nil
    ) {
        self.request = request
        self.body = body
        self.headers = headers
        self.statusCode = statusCode
        self.error = error
    }
}

/// Extension of the `Response` protocol providing utility functions for validation, decoding, mapping, and
/// error handling.
extension Response {
    /// Validates the response by checking for errors.
    ///
    /// - Throws: The response error if present.
    /// - Returns: The validated `Response`.
    @discardableResult
    public func validate() throws -> Self {
        guard let error else {
            return self
        }

        throw error
    }

    /// Decodes the response body into a specified Decodable model using a given JSONDecoder.
    ///
    /// - Parameters:
    ///   - type: The model type to decode.
    ///   - decoder: The decoder to use for decoding.
    /// - Throws: An error if decoding fails or the body is nil.
    /// - Returns: The decoded model.
    public func decode<Model: Decodable>(
        _ type: Model.Type = Model.self,
        using decoder: JSONDecoder
    ) throws -> Model {
        guard let data = body else {
            throw APIError.response(
                "Unable to decode `\(Self.self)` from a `Response`; body was nil."
            )
        }

        return try decoder.decode(type, from: data)
    }

    /// Decodes the response body into a `Result` of a Decodable model, handling success and failure cases.
    ///
    /// - Parameters:
    ///   - type: The model type to decode.
    ///   - decoder: The decoder to use for decoding.
    /// - Returns: A `Result` containing either the decoded model or an error.
    public func decodeResult<Model: Decodable>(
        _ type: Model.Type = Model.self,
        using decoder: JSONDecoder
    ) -> Result<Model, Error> {
        guard let data = body else {
            return Result.failure(
                APIError.response(
                    "Unable to decode `\(Self.self)` from a `Response`; body was nil."
                )
            )
        }

        do {
            let model = try decoder.decode(type, from: data)
            return Result.success(model)
        } catch {
            return Result.failure(APIError.parser(error))
        }
    }

    /// Transforms the response into a `Result` using a provided transformation function.
    ///
    /// - Parameter transform: A closure that transforms the response into a result.
    /// - Returns: A `Result` containing the transformed model or an error.
    public func map<Model>(
        _ transform: (Response) -> Model
    ) -> Model {
        transform(self)
    }

    /// Flattens the response into another response type using a provided transformation function.
    ///
    /// - Parameter transform: A closure that transforms the response into another response.
    /// - Returns: A transformed `Response`.
    public func flatMap<Model: Response>(
        _ transform: (Response) -> Model
    ) -> Model {
        transform(self)
    }

    /// Returns a `Result` representing the success or failure of the response.
    ///
    /// - Returns: A `Result` containing the `Response` on success or an error on failure.
    public func result() -> Result<Response, Error> {
        guard let error else {
            return Result.success(self)
        }

        return Result.failure(error)
    }

    /// Maps the response error into a different error type using a provided transformation function.
    ///
    /// - Parameter transform: A closure that transforms the original error into another error.
    /// - Returns: A `Result` containing the `Response` or the mapped error.
    public func mapError<MapError: Error>(
        _ transform: (Error) -> MapError
    ) -> Result<Response, MapError> {
        guard let error else {
            return Result.success(self)
        }

        return Result.failure(transform(error))
    }

    /// Returns the status code of the response.
    ///
    /// - Returns: The status code of the response.
    /// - Throws: A `NetworkClientError` if the status code is not found.
    public func statusCode() -> Int {
        statusCode
    }

    /// Decodes the response error.
    ///
    /// - Parameters:
    ///   - type: The model type to decode.
    ///   - decoder: The decoder to use for decoding.
    /// - Throws: An error if decoding fails or the body is nil.
    /// - Returns: The decoded model.
    public func decodeError<Model: Decodable>(
        _ type: Model.Type = Model.self,
        using decoder: JSONDecoder
    ) throws -> Model {
        guard let data = body else {
            throw APIError.response(
                "Unable to decode error `\(Self.self)` from a `Response`; body was nil."
            )
        }

        return try decoder.decode(type, from: data)
    }

    /// Decodes the response error into a `Result` of a Decodable model, handling success and failure cases.
    ///
    /// - Parameters:
    ///   - type: The model type to decode.
    ///   - decoder: The decoder to use for decoding.
    /// - Returns: A `Result` containing either the decoded model or an error.
    public func decodeErrorResult<Model: Decodable>(
        _ type: Model.Type = Model.self,
        using decoder: JSONDecoder
    ) -> Result<Model, Error> {
        guard let data = body else {
            return Result.failure(
                APIError.response(
                    "Unable to decode error `\(Self.self)` from a `Response`; body was nil."
                )
            )
        }

        do {
            let model = try decoder.decode(type, from: data)
            return Result.success(model)
        } catch {
            return Result.failure(APIError.parser(error))
        }
    }

    /// Log the response
    ///
    /// - Parameter completion: The formatted response
    /// - Returns: The `Response`
    @discardableResult
    public func log(_ completion: @Sendable (String) -> Void) -> Response {
        completion(description)
        return self
    }

    /// Debug the response
    ///
    /// - Parameter completion: Send the response to debug it
    /// - Returns: The `Response`
    @discardableResult
    public func debug(_ completion: @Sendable (Response) -> Void) -> Response {
        completion(self)
        return self
    }

    /// Check Unauthenticated
    /// - Returns: The `Response`
    public func unauthenticated() throws -> Self {
        guard statusCode == 401 else { return self }

        throw APIError.unauthenticated
    }

    /// Check unauthorized
    /// - Returns: The `Response`
    public func unauthorized() throws -> Self {
        guard statusCode == 403 else { return self }

        throw APIError.unauthorized
    }

    /// Validate status code
    ///
    /// - Parameter statusCode: The status code to validate
    /// - Returns: The `Response`
    public func validate(statusCode: Int) throws -> Self {
        guard self.statusCode == statusCode else { return self }

        throw APIError.statusCode
    }
}

/// Extension to provide static error responses.
extension Response {
    /// Create a new error response
    ///
    /// - Parameter error: The error
    /// - Returns: A `Response`
    public static func error(_ error: Error) -> Response {
        ResponseError(error, request: .empty)
    }
}

struct ResponseError: Response {
    let request: URLRequest
    let _error: Error?
    let code: Int

    init(_ error: Error, request: URLRequest, code: Int = 499) {
        self._error = error
        self.request = request
        self.code = code
    }

    var body: Data? {
        nil
    }

    var headers: [AnyHashable: AnyCodable] {
        [:]
    }

    var statusCode: Int {
        code
    }

    var error: Error? {
        _error
    }
}
