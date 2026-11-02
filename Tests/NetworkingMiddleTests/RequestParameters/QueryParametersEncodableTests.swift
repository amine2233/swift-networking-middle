import XCTest
@testable import NetworkingMiddle

final class QueryParametersEncodableTests: XCTestCase {
    struct QueryParameter: Encodable {
        let count: Int
    }

    func testExample() async throws {
        // given
        let queryParameters = QueryParameter(count: 50)

        // when
        let requestParameters = RequestParametersFactory
            .queryEncodableParameters(queryParameters)
        let requestBuilder = try await RequestBuilder(
            path: "photos/random",
            method: .get,
            parameters: requestParameters
        )
        .asURLRequest(baseURL: "https://google.com")

        // then
        XCTAssertEqual(requestBuilder.url?.absoluteString, "https://google.com/photos/random?count=50")
    }

    func test() async throws {
        // given
        let queryParameters = QueryParameter(count: 50)
        let requestBuilder = try await RequestBuilder(
            path: "photos/random",
            method: .get
        )
        .asURLRequest(baseURL: "https://google.com")

        // when
        let parameters = QueryParametersEncodable(queryParameters)
        let result = try parameters.apply(urlRequest: requestBuilder)

        // then
        XCTAssertEqual(result.url?.absoluteString, "https://google.com/photos/random?count=50")
    }
}
