import XCTest
@testable import NetworkingMiddle

class RequestModifierHeaderTests: XCTestCase {
    func testModify() {
        let modifier = RequestModifierHeader(forHttpHeaderKey: "Authorization", value: "Bearer test_token")
        var request = RequestFactory.create(
            path: "home/1/test",
            method: .get
        )

        do {
            try modifier.modify(baseURL: "https://example.com", request: &request)
        } catch {
            XCTFail("Error modifying request: \(error.localizedDescription)")
        }

        XCTAssertEqual(request.headers["Authorization"], "Bearer test_token")
    }
}
