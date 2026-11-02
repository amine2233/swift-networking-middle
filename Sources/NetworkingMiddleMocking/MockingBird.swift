import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// The mocking Bundle entry this is a json representation of json inside Bundle.json
///
///     [
///          {
///             "request": {
///                 "url": "://httpbin.org/ip"
///             },
///
///             "response" : {
///                 "code": 200,
///                 "file": "ip.json",
///                 "mime_type": "application/json"
///             }
///          }
///     ]
struct MockBundleEntry: Decodable {
    struct Request: Decodable {
        var url: String
        var parameters: [String: String?]?
        var method: String = "GET"

        enum CodingKeys: String, CodingKey {
            case url
            case method
            case parameters
        }
    }

    struct Response: Decodable {
        var code: Int = 200
        var headers: [String: String]?
        var file: String?
        var mimeType: String?

        enum CodingKeys: String, CodingKey {
            case code
            case headers
            case file
            case mimeType = "mime_type"
        }
    }

    let request: Request
    let response: Response
}

public final class MockingBird: URLProtocol {
    private static let lock = NSLock()
    // Backing storage: access only through the lock-protected computed properties below.
    private nonisolated(unsafe) static var _currentMockBundle: [MockBundleEntry]?
    private nonisolated(unsafe) static var _currentMockBundlePath: String?
    private nonisolated(unsafe) static var _handleAllRequests: Bool = false

    static var currentMockBundle: [MockBundleEntry]? {
        get { lock.lock(); defer { lock.unlock() }; return _currentMockBundle }
        set { lock.lock(); defer { lock.unlock() }; _currentMockBundle = newValue }
    }

    static var currentMockBundlePath: String? {
        get { lock.lock(); defer { lock.unlock() }; return _currentMockBundlePath }
        set { lock.lock(); defer { lock.unlock() }; _currentMockBundlePath = newValue }
    }

    /// Handle all request
    ///
    /// If this is true, we'll claim to answer all URL requests.
    /// If this is false, URLs that don't match will be passed on
    ///      through to normal handlers.
    public static var handleAllRequests: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _handleAllRequests }
        set { lock.lock(); defer { lock.unlock() }; _handleAllRequests = newValue }
    }

    public enum MockingBirdError: Error {
        case mockBundleNotFound
        case invalidMockBundle
        case invalidBundleDescriptionFile
    }

    /// Register MockingBird with a NSURLSession
    ///
    /// - parameter session: the session to mock
    public final class func register(inSession session: URLSession) {
        register(inConfig: session.configuration)
    }

    /// Register MockingBird in a NSURLSessionConfiguration
    ///
    /// - parameter config: session configuration to mock
    public final class func register(inConfig config: URLSessionConfiguration) {
        var protocolClasses = config.protocolClasses
        if protocolClasses == nil {
            protocolClasses = [AnyClass]()
        }
        protocolClasses!.insert(MockingBird.self, at: 0)
        config.protocolClasses = protocolClasses
    }

    /// Set mock bundle to use
    ///
    /// - parameter bundlePath: path to the bundle
    /// - throws: MockingBird.Error when bundle could not be loaded
    public final class func setMockBundle(withPath bundlePath: String?) throws {
        guard let bundlePath else {
            currentMockBundle = nil
            currentMockBundlePath = nil
            return
        }

        do {
            var isDir = ObjCBool(false)
            if FileManager.default.fileExists(atPath: bundlePath, isDirectory: &isDir), isDir.boolValue {
                if let data = FileManager.default.contents(atPath: "\(bundlePath)/bundle.json") {
                    currentMockBundle = try JSONDecoder().decode([MockBundleEntry].self, from: data)
                } else {
                    throw MockingBird.MockingBirdError.invalidBundleDescriptionFile
                }
            } else {
                throw MockingBird.MockingBirdError.mockBundleNotFound
            }
        } catch MockingBird.MockingBirdError.invalidBundleDescriptionFile {
            throw MockingBird.MockingBirdError.invalidBundleDescriptionFile
        } catch {
            throw MockingBird.MockingBirdError.invalidMockBundle
        }
        currentMockBundlePath = bundlePath
    }

    override public class func canInit(with request: URLRequest) -> Bool {
        // we can only answer if we have a mockBundle
        guard currentMockBundle != nil else { return false }

        // we can answer all http and https requests
        guard let url = request.url, let method = request.httpMethod else { return false }

        if getBundleItem(inURL: url, method: method) != nil {
            return true
        }
        return handleAllRequests
    }

    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        // canonical request is same as request
        request
    }

    override public class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool {
        // nothing is cacheable
        false
    }

    override public func startLoading() {
        guard let url = request.url, let method = request.httpMethod else {
            client?.urlProtocol(
                self,
                didFailWithError: NSError(domain: "mockingbird", code: 1_001, userInfo: nil)
            )
            return
        }

        // fetch item
        guard let entry = MockingBird.getBundleItem(inURL: url, method: method) else {
            if MockingBird.handleAllRequests {
                // We're handling all requests, but no bundle item found
                // so reply with server error 501 and no data
                var headers = [String: String]()
                headers["Content-Type"] = "text/plain"

                let errorMsg = "Mockingbird response not available. Please add a response to the mock bundle."
                let data = errorMsg.data(using: String.Encoding.utf8)
                if let data {
                    headers["Content-Length"] = "\(data.count)"
                }
                guard let response = HTTPURLResponse(
                    url: url,
                    statusCode: 501,
                    httpVersion: "HTTP/1.1",
                    headerFields: headers
                ) else {
                    client?.urlProtocol(
                        self,
                        didFailWithError: NSError(domain: "mockingbird", code: 1_002, userInfo: nil)
                    )
                    return
                }

                // send response
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

                // send response data if available
                if let data {
                    client?.urlProtocol(self, didLoad: data)
                }

                // finish up
                client?.urlProtocolDidFinishLoading(self)

            } else {
                client?.urlProtocol(
                    self,
                    didFailWithError: NSError(domain: "mockingbird", code: 1_000, userInfo: nil)
                )
            }
            return
        }

        // set mime type
        var mime: String?
        if let mimeType = entry.response.mimeType {
            mime = mimeType
        }

        // load data
        var data: Data?
        if let file = entry.response.file, let bundlePath = MockingBird.currentMockBundlePath {
            data = FileManager.default.contents(atPath: "\(bundlePath)/\(file)")
        }

        // construct response
        var headers = entry.response.headers ?? [:]
        headers["Content-Type"] = mime
        if let data {
            headers["Content-Length"] = "\(data.count)"
        }
        guard let response = HTTPURLResponse(
            url: url,
            statusCode: entry.response.code,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        ) else {
            client?.urlProtocol(
                self,
                didFailWithError: NSError(domain: "mockingbird", code: 1_003, userInfo: nil)
            )
            return
        }

        // send response
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

        // send response data if available
        if let data {
            client?.urlProtocol(self, didLoad: data)
        }

        // finish up
        client?.urlProtocolDidFinishLoading(self)
    }

    override public func stopLoading() {
        // do nothing
    }

    private final class func getBundleItem(inURL inUrl: URL, method: String) -> MockBundleEntry? {
        guard let url = URLComponents(url: inUrl, resolvingAgainstBaseURL: false),
              let host = url.host,
              let bundle = MockingBird.currentMockBundle else { return nil }

        // find entry that matches
        for entry in bundle {
            // url match and request method match
            var urlPart = "://\(host)\(url.path)"
            if let port = url.port {
                urlPart = "://\(host):\(port)\(url.path)"
            }

            if entry.request.url == urlPart, entry.request.method == method {
                // components
                var valid = true
                if let queryItems = url.queryItems {
                    for component in queryItems {
                        var found = false
                        let parameters = entry.request.parameters ?? [:]
                        for q in parameters {
                            if component.name == q.key, q.value == nil {
                                found = true
                                break
                            } else if component.name == q.key, component.value == q.value {
                                found = true
                                break
                            }
                        }
                        if !found {
                            valid = false
                            break
                        }
                    }
                } else {
                    // no components
                    if let parameters = entry.request.parameters, !parameters.isEmpty {
                        valid = false
                    }
                }

                if valid {
                    return entry
                }
            }
        }

        return nil
    }
}
