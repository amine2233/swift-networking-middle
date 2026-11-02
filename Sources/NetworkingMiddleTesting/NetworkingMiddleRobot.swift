import Foundation
import NetworkingMiddle
import XCTest

final class NetworkProviderTestRobot: Sendable {
    private let provider: NetworkClientSpy = .init()

    // MARK: - Given

    func givenStubbedResponse(_ response: Response) -> Self {
        provider.stubbedRequestResult = response
        return self
    }

    func givenStubbedNewBuilder(_ request: Request) -> Self {
        provider.stubbedNewBuilderResult = request
        return self
    }

    func givenStubbedModifyRequest(baseURL: String, request: Request) -> Self {
        provider.stubbedModifyRequestsActionResult = (baseURL, request)
        return self
    }

    // MARK: - When

    @discardableResult
    func whenRequestIsMade(baseURL: String, request: Request) async -> Self {
        _ = try? await provider.request(baseURL: baseURL, request: request)
        return self
    }

    func whenModifyRequestIsCalled() -> Self {
        XCTAssertTrue(provider.invokedModifyRequests, "Expected modifyRequests to be called.")
        return self
    }

    func whenInterceptIsCalled() -> Self {
        XCTAssertTrue(provider.invokedIntercept, "Expected intercept to be called.")
        return self
    }

    func whenModifyRequestIsCalled(times: Int = 1) -> Self {
        XCTAssertEqual(
            provider.invokedModifyRequestsCount,
            times,
            "Expected modify to be called \(times) times."
        )
        return self
    }

    func whenInterceptIsCalled(times: Int = 1) -> Self {
        XCTAssertEqual(
            provider.invokedInterceptCount,
            times,
            "Expected ntercept to be called \(times) times."
        )
        return self
    }

    func whenBuilderIsCreated(
        path: String = "/default",
        method: HTTPMethod = .get,
        parameters: RequestParameters? = nil,
        body: RequestBody? = nil,
        headers: [String: String] = [:]
    ) -> Self {
        _ = provider.newBuilder(
            path: path,
            method: method,
            parameters: parameters,
            body: body,
            headers: headers
        )
        return self
    }

    // MARK: - Then

    func thenVerifyRequestCalled(times: Int = 1) -> Self {
        XCTAssertEqual(provider.invokedRequestCount, times, "Expected request to be called \(times) times.")
        return self
    }

    func thenVerifyRequestParameters(baseURL: String, request: any Request) -> Self {
        let actual = provider.invokedRequestParameters
        XCTAssertEqual(actual?.baseURL, baseURL)
        XCTAssertEqual(actual?.request.path, request.path)
        XCTAssertEqual(actual?.request.method, request.method)
        XCTAssertEqual(actual?.request.headers, request.headers)
        return self
    }

    func thenVerifyModifyCalled(times: Int = 1) -> Self {
        XCTAssertEqual(
            provider.invokedModifyRequestsCount,
            times,
            "Expected modifyRequests to be called \(times) times."
        )
        return self
    }

    func thenVerifyInterceptCalled(times: Int = 1) -> Self {
        XCTAssertEqual(
            provider.invokedInterceptCount,
            times,
            "Expected intercept to be called \(times) times."
        )
        return self
    }

    func thenVerifyNewBuilderCalled(times: Int = 1) -> Self {
        XCTAssertEqual(
            provider.invokedNewBuilderCount,
            times,
            "Expected newBuilder to be called \(times) times."
        )
        return self
    }
}

struct InterceptorSpy: Interceptor {
    typealias Action = @Sendable (String, Request, Interceptor.Next) async throws -> Response

    let action: Action

    func intercept(
        baseURL: String,
        request: Request,
        next: Interceptor.Next
    ) async throws -> Response {
        try await action(baseURL, request, next)
    }
}

struct ModifierSpy: RequestModifier {
    typealias Action = @Sendable (String, inout Request) throws -> Void

    let action: Action

    func modify(baseURL: String, request: inout Request) throws {
        try action(baseURL, &request)
    }
}

final class NetworkClientSpy: NetworkProvider, @unchecked Sendable {
    var invokedModifyRequests = false
    var invokedModifyRequestsCount = 0
    var invokedModifyParameters: [ModifierSpy] = []
    var stubbedModifyRequestsActionResult: (String, Request)?

    func modifyRequests(
        action: @escaping @Sendable (String, inout Request) throws -> Void
    ) -> NetworkProvider {
        invokedModifyRequests = true
        invokedModifyRequestsCount += 1
        invokedModifyParameters.append(ModifierSpy(action: action))
        if var result = stubbedModifyRequestsActionResult {
            try? action(result.0, &result.1)
        }
        return self
    }

    var invokedIntercept = false
    var invokedInterceptCount = 0
    var invokedInterceptParameters: [InterceptorSpy] = []
    var stubbedInterceptError: Error?
    var stubbedInterceptResult: Response!

    func intercept(
        action: @escaping @Sendable (String, Request, (String, Request) async throws -> Response) async throws
            -> Response
    ) -> NetworkProvider {
        invokedIntercept = true
        invokedInterceptCount += 1
        invokedInterceptParameters.append(InterceptorSpy(action: action))
        return self
    }

    var invokedRequest = false
    var invokedRequestCount = 0
    var invokedRequestParameters: (baseURL: String, request: Request)?
    var invokedRequestParametersList = [(baseURL: String, request: Request)]()
    var stubbedRequestResult: Response!

    func request(baseURL: String, request: Request) async throws -> Response {
        invokedRequest = true
        invokedRequestCount += 1
        invokedRequestParameters = (baseURL, request)
        invokedRequestParametersList.append((baseURL, request))
        return stubbedRequestResult
    }

    var invokedNewBuilder = false
    var invokedNewBuilderCount = 0
    var invokedNewBuilderParameters: (
        path: String,
        method: HTTPMethod,
        parameters: RequestParameters?,
        body: RequestBody?,
        headers: [String: String]
    )?
    var invokedNewBuilderParametersList = [(
        path: String,
        method: HTTPMethod,
        parameters: RequestParameters?,
        body: RequestBody?,
        headers: [String: String]
    )]()
    var stubbedNewBuilderResult: Request!

    func newBuilder(
        path: String,
        method: HTTPMethod,
        parameters: RequestParameters?,
        body: RequestBody?,
        headers: [String: String]
    ) -> Request {
        invokedNewBuilder = true
        invokedNewBuilderCount += 1
        invokedNewBuilderParameters = (path, method, parameters, body, headers)
        invokedNewBuilderParametersList.append((path, method, parameters, body, headers))
        return stubbedNewBuilderResult
    }
}
