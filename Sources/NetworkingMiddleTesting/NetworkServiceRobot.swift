import Foundation
import NetworkingMiddle
import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class NetworkServiceTestRobot: Sendable {
    private let robot: NetworkServiceSpy = .init()

    /// Given
    func givenRequest(data: Data?, urlResponse: URLResponse?, error: Error?) -> Self {
        robot.stubbedDataTaskRequestCompletionHandlerResult = (data, urlResponse, error)
        return self
    }

    func givenRequest(data: Data?) -> Self {
        givenRequest(data: data, urlResponse: nil, error: nil)
    }

    func givenRequest(urlResponse: URLResponse?) -> Self {
        givenRequest(data: nil, urlResponse: urlResponse, error: nil)
    }

    func givenRequest(error: Error?) -> Self {
        givenRequest(data: nil, urlResponse: nil, error: error)
    }

    func givenRequestModel<T: Encodable & Sendable>(
        _ model: T,
        jsonEncoder: JSONEncoder = JSONEncoder()
    ) throws -> Self {
        let data = try jsonEncoder.encode(model)
        return givenRequest(data: data, urlResponse: nil, error: nil)
    }

    func givenURL(data: Data?, urlResponse: URLResponse?, error: Error?) -> Self {
        robot.stubbedDataTaskRequestCompletionHandlerResult = (data, urlResponse, error)
        return self
    }

    func givenURL(data: Data?) -> Self {
        givenURL(data: data, urlResponse: nil, error: nil)
    }

    func givenURL(urlResponse: URLResponse?) -> Self {
        givenURL(data: nil, urlResponse: urlResponse, error: nil)
    }

    func givenURL(error: Error?) -> Self {
        givenURL(data: nil, urlResponse: nil, error: error)
    }

    func givenURLModel<T: Encodable & Sendable>(
        _ model: T,
        jsonEncoder: JSONEncoder = JSONEncoder()
    ) throws -> Self {
        let data = try jsonEncoder.encode(model)
        return givenURL(data: data, urlResponse: nil, error: nil)
    }

    /// When
    func whenCallingDataTaskWithURL(_ url: URL) -> Self {
        _ = robot.dataTask(url: url) { _, _, _ in }
        return self
    }

    func whenCallingDataTaskWithRequest(_ request: URLRequest) -> Self {
        _ = robot.dataTask(request: request) { _, _, _ in }
        return self
    }

    /// Then
    func thenVerifyDataTaskWithURLCalled() -> Self {
        XCTAssertTrue(robot.invokedDataTaskUrl, "Expected dataTask(url:) to be called.")
        return self
    }

    func thenVerifyDataTaskWithRequestCalled() -> Self {
        XCTAssertTrue(robot.invokedDataTaskRequest, "Expected dataTask(request:) to be called.")
        return self
    }

    func thenVerifyURLWas(_ expectedURL: URL) -> Self {
        XCTAssertEqual(robot.invokedDataTaskUrlParameters?.url, expectedURL, "Expected URL to match.")
        return self
    }

    func thenVerifyRequestWas(_ expectedRequest: URLRequest) -> Self {
        XCTAssertEqual(
            robot.invokedDataTaskRequestParameters?.request,
            expectedRequest,
            "Expected request to match."
        )
        return self
    }

    func thenVerifyURLTask(_ verify: (NetworkTaskTestRobot) -> Void) -> Self {
        verify(NetworkTaskTestRobot(task: robot.stubbedDataTaskUrlResult))
        return self
    }

    func thenVerifyRequestTask(_ verify: (NetworkTaskTestRobot) -> Void) -> Self {
        verify(NetworkTaskTestRobot(task: robot.stubbedDataTaskRequestResult))
        return self
    }
}

final class NetworkServiceSpy: NetworkService, @unchecked Sendable {
    var invokedDataTaskRequest = false
    var invokedDataTaskRequestCount = 0
    var invokedDataTaskRequestParameters: (request: URLRequest, Void)?
    var invokedDataTaskRequestParametersList = [(request: URLRequest, Void)]()
    var stubbedDataTaskRequestCompletionHandlerResult: (Data?, URLResponse?, Error?)?
    var stubbedDataTaskRequestResult: NetworkTaskSpy = .init()

    func dataTask(
        request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) -> NetworkTask {
        invokedDataTaskRequest = true
        invokedDataTaskRequestCount += 1
        invokedDataTaskRequestParameters = (request, ())
        invokedDataTaskRequestParametersList.append((request, ()))
        if let result = stubbedDataTaskRequestCompletionHandlerResult {
            completionHandler(result.0, result.1, result.2)
        }
        return stubbedDataTaskRequestResult
    }

    var invokedDataTaskUrl = false
    var invokedDataTaskUrlCount = 0
    var invokedDataTaskUrlParameters: (url: URL, Void)?
    var invokedDataTaskUrlParametersList = [(url: URL, Void)]()
    var stubbedDataTaskUrlCompletionHandlerResult: (Data?, URLResponse?, Error?)?
    var stubbedDataTaskUrlResult: NetworkTaskSpy = .init()

    func dataTask(
        url: URL,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) -> NetworkTask {
        invokedDataTaskUrl = true
        invokedDataTaskUrlCount += 1
        invokedDataTaskUrlParameters = (url, ())
        invokedDataTaskUrlParametersList.append((url, ()))
        if let result = stubbedDataTaskUrlCompletionHandlerResult {
            completionHandler(result.0, result.1, result.2)
        }
        return stubbedDataTaskUrlResult
    }
}
