import XCTest
@testable import NetworkingMiddle

class RequestModifierTokenTests: XCTestCase {
    func testModify() {
        let modifier = RequestModifierToken(token: "test_token")
        var request = RequestFactory.create(
            path: "home/1/test",
            method: .get
        )

        do {
            try modifier.modify(baseURL: "https://example.com", request: &request)
        } catch {
            XCTFail("Error modifying request: \(error.localizedDescription)")
        }

        XCTAssertEqual(request.headers["Authorization"], "token test_token")
    }
}
