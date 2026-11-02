import RegexBuilder
import XCTest
@testable import NetworkingMiddle

@available(iOS 16.0, *)
class InterceptorTimeLoggerTests: XCTestCase {
    func testIntercept() {
        let expectations = expectation(description: "Request should complete")

        let printer = LoggerPrinterMock()

        let interceptor = InterceptorTimeLogger { message in
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
                        sleep(2)
                        return try await ResponseDefault(
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

        let regexPattern = Regex {
            "[Request][Time]"
            One(.whitespace)
            OneOrMore(.digit)
            "."
            Repeat(count: 2) {
                One(.digit)
            }
            One(.whitespace)
            "seconds"
        }
        .anchorsMatchLineEndings()

        if let match = printer.printerCalls.first?.firstMatch(of: regexPattern) {
            XCTAssertTrue(match.output == printer.printerCalls.first!)
        } else {
            XCTFail("Not matching found")
        }
    }
}
