import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import AnyCodable

private final class TaskHolder: @unchecked Sendable {
    private let lock = NSLock()
    private var task: NetworkTask?
    private var cancelled = false

    func set(_ task: NetworkTask) {
        lock.lock()
        defer { lock.unlock() }
        self.task = task
        if cancelled { task.cancel() }
    }

    func cancel() {
        lock.lock()
        defer { lock.unlock() }
        cancelled = true
        task?.cancel()
    }
}

extension NetworkService {
    /// Run the request
    /// - Parameters:
    ///   - request: The `Request` Object
    ///   - completion: The completion block
    /// - Returns: The `URLSessionTask`
    package func performTask(
        baseURL: String,
        request: URLRequest,
        completion: @escaping @Sendable (Response) -> Void
    ) throws -> NetworkTask {
        dataTask(request: request) { data, urlResponse, error in
            if let error {
                return completion(
                    ResponseError(error, request: request)
                )
            }

            guard let urlResponse = urlResponse as? HTTPURLResponse else {
                return completion(
                    ResponseError(
                        APIError.client("Not found HTTPURLResponse"),
                        request: request
                    )
                )
            }

            let response = ResponseDefault(
                request: request,
                statusCode: urlResponse.statusCode,
                body: data,
                headers: urlResponse.allHeaderFields.map { ($0, AnyCodable($1)) }
            )

            completion(response)
        }
    }

    /// Run the request using async/await
    /// - Parameters:
    ///   - baseURL: The base url string
    ///   - request: The `Request` Object
    /// - Returns: The response or throw an error
    package func perform(
        baseURL: String,
        request: Request
    ) async throws -> Response {
        let urlRequest = try await request.asURLRequest(baseURL: baseURL)
        let holder = TaskHolder()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                do {
                    let task = try self.performTask(baseURL: baseURL, request: urlRequest) { response in
                        continuation.resume(returning: response)
                    }
                    holder.set(task)
                    task.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            holder.cancel()
        }
    }
}
