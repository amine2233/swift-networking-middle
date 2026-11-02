import Foundation

/// A protocol for modifying network requests before they are executed.
public protocol RequestModifier: Sendable {
    /// Modifies the network request by altering its parameters or headers.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL of the request.
    ///   - request: An inout `Request` object to be modified.
    /// - Throws: An error if the modification fails.
    func modify(baseURL: String, request: inout Request) throws
}

/// A factory for creating request modifiers.
public enum RequestModifierFactory: Sendable {
    /// Creates a `RequestModifier` that adds a bearer token to the request headers.
    ///
    /// - Parameter token: The bearer token to add to the request.
    /// - Returns: An instance of `RequestModifierBearerToken`.
    public static func bearerToken(token: String) -> any RequestModifier {
        RequestModifierBearerToken(token: token)
    }

    /// Creates a `RequestModifier` that adds an authorization token to the request headers.
    ///
    /// - Parameter token: The authorization token to add to the request.
    /// - Returns: An instance of `RequestModifierToken`.
    public static func token(token: String) -> any RequestModifier {
        RequestModifierToken(token: token)
    }

    /// Creates a `RequestModifier` that adds a custom HTTP header to the request.
    ///
    /// - Parameters:
    ///   - key: The HTTP header key.
    ///   - value: The value for the HTTP header.
    /// - Returns: An instance of `RequestModifierHeader`.
    public static func header(forHttpHeaderKey key: String, value: String) -> any RequestModifier {
        RequestModifierHeader(forHttpHeaderKey: key, value: value)
    }
}

struct RequestModifierBearerToken: RequestModifier {
    var token: String

    func modify(baseURL: String, request: inout Request) throws {
        request = request.set("Bearer \(token)", forHttpHeaderKey: "Authorization")
    }
}

struct RequestModifierToken: RequestModifier {
    var token: String

    func modify(baseURL: String, request: inout Request) throws {
        request = request.set("token \(token)", forHttpHeaderKey: "Authorization")
    }
}

struct RequestModifierHeader: RequestModifier {
    var key: String
    var value: String

    init(forHttpHeaderKey key: String, value: String) {
        self.key = key
        self.value = value
    }

    func modify(baseURL: String, request: inout Request) throws {
        request = request.set(value, forHttpHeaderKey: key)
    }
}
