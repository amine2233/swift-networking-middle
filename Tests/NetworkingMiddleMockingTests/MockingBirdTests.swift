import XCTest
@testable import NetworkingMiddleMocking
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class mockingbirdTests: XCTestCase {
    var session: URLSession = .shared
    var timeout: TimeInterval = 5

    override func setUp() {
        super.setUp()

        MockingBird.register(inSession: session)
        URLProtocol.registerClass(MockingBird.self)

        let bundle = Bundle.module.resourcePath!
        do {
            try MockingBird.setMockBundle(withPath: bundle)
        } catch {
            XCTFail("Could not reset mock bundle")
        }
    }

    override func tearDown() {
        URLProtocol.unregisterClass(MockingBird.self)

        do {
            try MockingBird.setMockBundle(withPath: nil)
        } catch {
            XCTFail("Could not reset mock bundle")
        }

        // Put teardown code here. This method is called after the invocation of each test method in the
        // class.
        super.tearDown()
    }

    func xtestReal() {
        let expectation = expectation(description: "testReal")

        do {
            try MockingBird.setMockBundle(withPath: nil)
        } catch {
            XCTFail("Could not disable mock bundle")
        }

        session.dataTask(
            with: URLRequest(url: URL(string: "http://httpbin.org/ip")!)
        ) { data, _, _ in
            if let data {
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: String]
                guard let ip = json?["origin"] else {
                    XCTFail("Invalid data returned")
                    expectation.fulfill()
                    return
                }

                XCTAssert(ip != "127.0.0.1")
                expectation.fulfill()
            } else {
                XCTFail("No data returned")
                expectation.fulfill()
            }
        }
        .resume()

        wait(for: [expectation], timeout: 10)
    }

    func testHandleAll() throws {
        let expectation = expectation(description: "testHandleAll")

        MockingBird.handleAllRequests = true
        try session.dataTask(
            with: URLRequest(url: XCTUnwrap(URL(string: "http://httpbin.org/html")))
        ) { _, response, _ in
            XCTAssertTrue((response as? HTTPURLResponse)?.statusCode == 501)
            expectation.fulfill()
        }
        .resume()
        wait(for: [expectation], timeout: timeout)
    }

    func testMock() throws {
        let expectation = expectation(description: "testMock")

        try session.dataTask(
            with: URLRequest(url: XCTUnwrap(URL(string: "http://httpbin.org/ip")))
        ) { data, _, _ in
            if let data {
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: String]
                XCTAssertNotNil(json)
                guard let ip = json?["origin"] else {
                    XCTFail("Invalid data returned")
                    expectation.fulfill()
                    return
                }

                XCTAssert(ip == "127.0.0.1")
                expectation.fulfill()
            } else {
                XCTFail("No data returned")
                expectation.fulfill()
            }
        }
        .resume()

        wait(for: [expectation], timeout: timeout)
    }

    @available(iOS 16.0, *)
    func testArguments() throws {
        let expectation = expectation(description: "testArguments")

        var urlRequest = try URLRequest(url: XCTUnwrap(URL(string: "http://httpbin.org/get")))
        urlRequest.url?.append(
            queryItems: [
                .init(
                    name: "arg1",
                    value: "test"
                ),
                .init(
                    name: "arg2",
                    value: "test"
                )
            ]
        )

        session.dataTask(with: urlRequest) { data, _, _ in
            if let data, !data.isEmpty {
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                XCTAssertNotNil(json)
                guard let ip = json?["origin"] as? String,
                      let args = json?["args"] as? [String: String] else {
                    XCTFail("Invalid data returned")
                    expectation.fulfill()
                    return
                }

                XCTAssert(ip == "127.0.0.1")
                XCTAssertNotNil(args["arg1"])
                XCTAssertNotNil(args["arg2"])

                expectation.fulfill()
            } else {
                XCTFail("No data returned")
                expectation.fulfill()
            }
        }
        .resume()

        wait(for: [expectation], timeout: timeout)
    }

    @available(iOS 16.0, *)
    func testOtherArgument() throws {
        let expectation = expectation(description: "testArguments")

        var urlRequest = try URLRequest(url: XCTUnwrap(URL(string: "http://httpbin.org/get")))
        urlRequest.url?.append(
            queryItems: [
                .init(
                    name: "arg1",
                    value: "foobar"
                )
            ]
        )

        session.dataTask(with: urlRequest) { data, _, _ in
            if let data {
                let jsonString = String(data: data, encoding: String.Encoding.utf8)
                XCTAssertNotNil(jsonString)
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                XCTAssertNotNil(json)
                guard let ip = json?["origin"] as? String,
                      let args = json?["args"] as? [String: String] else {
                    XCTFail("Invalid data returned")
                    expectation.fulfill()
                    return
                }

                XCTAssert(ip == "127.0.0.1")
                XCTAssertNotNil(args["arg1"])
                XCTAssertNil(args["arg2"])

                expectation.fulfill()
            } else {
                XCTFail("No data returned")
                expectation.fulfill()
            }
        }
        .resume()

        wait(for: [expectation], timeout: 10)
    }

    /// flaky test
    @available(iOS 16.0, *)
    func xtestNonMatchingArgument() {
        let expectation = expectation(description: "testArguments")
        var urlRequest = URLRequest(url: URL(string: "http://httpbin.org/get")!)
        urlRequest.url?.append(
            queryItems: [
                .init(
                    name: "other",
                    value: "foobar"
                )
            ]
        )

        session.dataTask(with: urlRequest) { data, _, _ in
            if let data {
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                XCTAssertNotNil(json)
                guard let ip = json?["origin"] as? String,
                      let args = json?["args"] as? [String: String] else {
                    XCTFail("Invalid data returned")
                    expectation.fulfill()
                    return
                }

                XCTAssert(ip != "127.0.0.1")
                XCTAssertNotNil(args["other"])
                XCTAssertNil(args["arg1"])
                XCTAssertNil(args["arg2"])

                expectation.fulfill()
            } else {
                XCTFail("No data returned")
                expectation.fulfill()
            }
        }
        .resume()

        wait(for: [expectation], timeout: 10)
    }
}
