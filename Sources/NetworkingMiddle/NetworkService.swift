import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A protocol defining the basic operations for a network task.
public protocol NetworkTask: Sendable {
    /// Resumes the task, allowing it to start or continue.
    func resume()

    /// Cancels the task, preventing any further operations.
    func cancel()
}

/// Typealias for the network service completion handler.
public typealias NetworkServiceCompletion = @Sendable (Data?, URLResponse?, Error?) -> Void

/// A protocol defining the essential functionality for a network service.
public protocol NetworkService: Sendable {
    /// Creates a network data task with a URL request and completion handler.
    ///
    /// - Parameters:
    ///   - request: The `URLRequest` to be performed.
    ///   - completionHandler: A closure called when the request is completed, providing data, a response, or
    /// an error.
    /// - Returns: A `NetworkTask` that can be resumed or cancelled.
    func dataTask(
        request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) -> NetworkTask

    /// Creates a network data task with a URL and completion handler.
    ///
    /// - Parameters:
    ///   - url: The `URL` to be requested.
    ///   - completionHandler: A closure called when the request is completed, providing data, a response, or
    /// an error.
    /// - Returns: A `NetworkTask` that can be resumed or cancelled.
    func dataTask(
        url: URL,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) -> NetworkTask
}

/// Conform `URLSessionDataTask` to `NetworkTask` protocol.
extension URLSessionDataTask: NetworkTask {}

/// Extend `URLSession` to conform to the `NetworkService` protocol.
extension URLSession: NetworkService {
    /// Creates a network data task with a URL request.
    ///
    /// - Parameters:
    ///   - request: The `URLRequest` to be performed.
    ///   - completionHandler: A closure called when the request is completed, providing data, a response, or
    /// an error.
    /// - Returns: A `NetworkTask` that can be resumed or cancelled.
    public func dataTask(
        request: URLRequest,
        completionHandler: @escaping NetworkServiceCompletion
    ) -> NetworkTask {
        dataTask(with: request, completionHandler: completionHandler) as NetworkTask
    }

    /// Creates a network data task with a URL.
    ///
    /// - Parameters:
    ///   - url: The `URL` to be requested.
    ///   - completionHandler: A closure called when the request is completed, providing data, a response, or
    /// an error.
    /// - Returns: A `NetworkTask` that can be resumed or cancelled.
    public func dataTask(
        url: URL,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) -> NetworkTask {
        dataTask(with: url, completionHandler: completionHandler) as NetworkTask
    }
}
