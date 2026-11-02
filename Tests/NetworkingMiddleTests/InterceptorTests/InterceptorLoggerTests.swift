import XCTest
@testable import NetworkingMiddle

class InterceptorLoggerTests: XCTestCase {
    func testIntercept() {
        let expectations = expectation(description: "Request should complete")

        let printer = LoggerPrinterMock()

        let interceptor = InterceptorLogger { message in
            printer.printer(message)
            expectations.fulfill()
        }

        let request = RequestFactory.create(
            path: "home/1/test",
            method: .get
        )

        Task {
            do {
                _ = try await interceptor
                    .intercept(baseURL: "https://example.com", request: request) { baseURL, request in
                        try await ResponseDefault(
                            request: request.asURLRequest(baseURL: baseURL),
                            statusCode: 200,
                            error: nil
                        )
                    }
            } catch {
                XCTFail("Error intercepting request: \(error.localizedDescription)")
            }
        }

        wait(for: [expectations], timeout: 5.0)

        var expectedString = "--- Request ---"
        expectedString += "\n[GET] [https] example.com"
        expectedString += "\nPath: /home/1/test"
        expectedString += "\n\tQueryItems: []"
        expectedString += "\n--- Response ---"
        expectedString += "\nStatusCode: 200"
        expectedString += "\n--- End Response ---"

        XCTAssertEqual(printer.printerCalls.first, expectedString)
    }
}
