import XCTest
@testable import NetworkingMiddle

final class ResponseLogTests: XCTestCase {
    func test_log_response() async throws {
        // GIVEN
        let baseURL = "https://example.com"
        let request = RequestFactory.create(
            path: "home/1/test",
            method: .put,
            parameters: RequestParametersFactory.queryParameters(query: ["page": "1", "total_page": "10"]),
            headers: ["Authorization": "Bearer token"]
        )
        let response = try await ResponseDefault(
            request: request.asURLRequest(baseURL: baseURL),
            statusCode: 200,
            headers: ["Authorization": "Bearer token"],
            error: nil
        )

        let printer = LoggerPrinterMock()

        // WHEN
        response.log { value in
            printer.printer(value)
        }

        // THEN
        var expectedString = "--- Request ---"
        expectedString += "\n[PUT] [https] example.com"
        expectedString += "\nPath: /home/1/test"
        expectedString += "\n\tQueryItems: [page=1, total_page=10]"
        expectedString += "\n\tQuery: page=1&total_page=10"
        expectedString += "\nHeaders:"
        expectedString += "\n\t[Authorization: Bearer token]"
        expectedString += "\n--- Response ---"
        expectedString += "\nStatusCode: 200"
        expectedString += "\nHeaders:"
        expectedString += "\n\t[Authorization: Bearer token]"
        expectedString += "\n--- End Response ---"

        XCTAssertEqual(printer.printerCalls.first, expectedString)
    }

    func test_debug_response() async throws {
        // GIVEN
        struct ModelExample: Encodable {
            let start: Bool
            let text: String
        }

        // GIVEN
        let baseURL = "https://example.com"
        let request = RequestFactory.create(
            path: "home/1/test",
            method: .put,
            parameters: RequestParametersFactory.queryParameters(query: ["page": "1", "total_page": "10"]),
            headers: ["Authorization": "Bearer token"]
        )
        let response = try await ResponseDefault(
            request: request.asURLRequest(baseURL: baseURL),
            statusCode: 200,
            headers: ["Authorization": "Bearer token"],
            error: nil
        )
        let printer = LoggerPrinterMock()

        // WHEN
        response.debug { response in
            printer.printer(response.description)
        }

        // THEN
        var expectedString = "--- Request ---"
        expectedString += "\n[PUT] [https] example.com"
        expectedString += "\nPath: /home/1/test"
        expectedString += "\n\tQueryItems: [page=1, total_page=10]"
        expectedString += "\n\tQuery: page=1&total_page=10"
        expectedString += "\nHeaders:"
        expectedString += "\n\t[Authorization: Bearer token]"
        expectedString += "\n--- Response ---"
        expectedString += "\nStatusCode: 200"
        expectedString += "\nHeaders:"
        expectedString += "\n\t[Authorization: Bearer token]"
        expectedString += "\n--- End Response ---"

        XCTAssertEqual(printer.printerCalls.first, expectedString)
    }
}
