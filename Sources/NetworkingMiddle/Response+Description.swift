import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Response {
    /// A human-readable description of the object.
    ///
    /// - Returns: A string describing the object.
    public var description: String {
        var value = "--- Request ---"

        if let url = request.url {
            value +=
                "\n[\(request.httpMethod ?? "unknown")] [\(url.scheme ?? "unknown")] \(url.hostString() ?? "unknown")"

            if url.pathComponents.count > 1 {
                value += "\nPath: \(url.relativePath)"
            }

            if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                value +=
                    "\n\tQueryItems: \(urlComponents.queryItems?.sorted { $0.name < $1.name } ?? [])"
            }

            if let query = url.queryString()?.split(separator: "&").sorted(by: <).joined(separator: "&") {
                value += "\n\tQuery: \(query)"
            }

            if let body = request.httpBody {
                value += "\n\tBody[\(body.count)]:"
                if let bodyString = String(data: body, encoding: .utf8) {
                    value += "\n\t\(bodyString)"
                }
            }

            if let allHTTPHeaderFields = request.allHTTPHeaderFields, !allHTTPHeaderFields.isEmpty {
                value +=
                    "\nHeaders:\n\t[\(allHTTPHeaderFields.map { "\($0.key): \($0.value)" }.joined(separator: ","))]"
            }
        }

        value += "\n--- Response ---"

        value += "\nStatusCode: \(statusCode)"

        if !headers.isEmpty {
            value +=
                "\nHeaders:\n\t[\(headers.map { "\($0.key.base): \($0.value.value)" }.joined(separator: ","))]"
        }

        if let error {
            value += "\nError: \(String(describing: error))"
            value += "\nError description: \(error.localizedDescription)"
        }

        if let body, !body.isEmpty {
            value += "\nBody[\(body.count)]:"
            if let bodyString = String(data: body, encoding: .utf8) {
                value += "\n\(bodyString)"
            }
        }

        value += "\n--- End Response ---"

        return value
    }
}

extension URLRequest {
    static var empty: URLRequest {
        URLRequest(url: URL(string: "https://example.com")!)
    }
}

extension URL {
    func pathString() -> String {
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            path(percentEncoded: false)
        } else {
            path
        }
    }

    func hostString() -> String? {
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            host(percentEncoded: false)
        } else {
            host
        }
    }

    func queryString() -> String? {
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            query(percentEncoded: false)
        } else {
            query
        }
    }
}
