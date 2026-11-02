#if !canImport(FoundationNetworking)
import CryptoKit
import NetworkingMiddle
import XCTest
@testable import NetworkingMiddlePinning

final class CertificatePinningTests: XCTestCase {
    // MARK: - Helpers

    private func loadTestCertificate() throws -> SecCertificate {
        let url = Bundle.module.url(forResource: "test_cert", withExtension: "der")!
        let data = try Data(contentsOf: url)
        guard let cert = SecCertificateCreateWithData(nil, data as CFData) else {
            XCTFail("Could not create SecCertificate from test_cert.der")
            throw URLError(.unknown)
        }

        return cert
    }

    private func spkiHash(for cert: SecCertificate) throws -> Data {
        guard let key = SecCertificateCopyKey(cert),
              let keyData = SecKeyCopyExternalRepresentation(key, nil) as Data? else {
            throw URLError(.unknown)
        }

        return Data(SHA256.hash(data: keyData))
    }

    private func makeTrust(certificates: [SecCertificate]) throws -> SecTrust {
        var trust: SecTrust?
        let status = SecTrustCreateWithCertificates(
            certificates as CFArray, SecPolicyCreateBasicX509(), &trust
        )
        guard status == errSecSuccess, let t = trust else { throw URLError(.unknown) }

        return t
    }

    private func makeServerTrustChallenge(host: String, trust: SecTrust) -> URLAuthenticationChallenge {
        URLAuthenticationChallenge(
            protectionSpace: ServerTrustProtectionSpace(host: host, trust: trust),
            proposedCredential: nil,
            previousFailureCount: 0,
            failureResponse: nil,
            error: nil,
            sender: ChallengeSenderStub()
        )
    }

    private func makeBasicAuthChallenge(host: String) -> URLAuthenticationChallenge {
        let space = URLProtectionSpace(
            host: host, port: 443, protocol: "https",
            realm: "test", authenticationMethod: NSURLAuthenticationMethodHTTPBasic
        )
        return URLAuthenticationChallenge(
            protectionSpace: space,
            proposedCredential: nil,
            previousFailureCount: 0,
            failureResponse: nil,
            error: nil,
            sender: ChallengeSenderStub()
        )
    }

    // MARK: - Policy tests (synchronous)

    func testPolicyStoresHashesCorrectly() {
        let hash = Data(repeating: 0x42, count: 32)
        let policy = CertificatePinningPolicy(["api.example.com": [hash]])

        XCTAssertEqual(policy.pinnedHashes["api.example.com"], [hash])
        XCTAssertNil(policy.pinnedHashes["other.example.com"])
    }

    func testPolicySupportsMultipleHashesPerHost() {
        let primary = Data(repeating: 0x01, count: 32)
        let backup = Data(repeating: 0x02, count: 32)
        let policy = CertificatePinningPolicy(["api.example.com": [primary, backup]])

        XCTAssertEqual(policy.pinnedHashes["api.example.com"]?.count, 2)
        XCTAssertEqual(policy.pinnedHashes["api.example.com"]?.first, primary)
        XCTAssertEqual(policy.pinnedHashes["api.example.com"]?.last, backup)
    }

    // MARK: - Delegate tests (synchronous — the handler is called inline)

    func testMatchingHashAllowsConnection() throws {
        let cert = try loadTestCertificate()
        let hash = try spkiHash(for: cert)
        let trust = try makeTrust(certificates: [cert])
        let policy = CertificatePinningPolicy(["test.example.com": [hash]])
        let delegate = PinningDelegate(policy: policy)
        let challenge = makeServerTrustChallenge(host: "test.example.com", trust: trust)

        var receivedDisposition: URLSession.AuthChallengeDisposition = .cancelAuthenticationChallenge
        var receivedCredential: URLCredential?

        delegate.urlSession(.shared, didReceive: challenge) { disposition, credential in
            receivedDisposition = disposition
            receivedCredential = credential
        }

        XCTAssertEqual(receivedDisposition, .useCredential)
        XCTAssertNotNil(receivedCredential)
    }

    func testMismatchedHashCancelsConnection() throws {
        let cert = try loadTestCertificate()
        let trust = try makeTrust(certificates: [cert])
        let wrongHash = Data(repeating: 0x00, count: 32)
        let policy = CertificatePinningPolicy(["test.example.com": [wrongHash]])
        let delegate = PinningDelegate(policy: policy)
        let challenge = makeServerTrustChallenge(host: "test.example.com", trust: trust)

        var receivedDisposition: URLSession.AuthChallengeDisposition = .useCredential

        delegate.urlSession(.shared, didReceive: challenge) { disposition, _ in
            receivedDisposition = disposition
        }

        XCTAssertEqual(receivedDisposition, .cancelAuthenticationChallenge)
    }

    func testUnknownHostCancelsConnection() throws {
        let cert = try loadTestCertificate()
        let trust = try makeTrust(certificates: [cert])
        let policy = CertificatePinningPolicy([:])
        let delegate = PinningDelegate(policy: policy)
        let challenge = makeServerTrustChallenge(host: "test.example.com", trust: trust)

        var receivedDisposition: URLSession.AuthChallengeDisposition = .useCredential

        delegate.urlSession(.shared, didReceive: challenge) { disposition, _ in
            receivedDisposition = disposition
        }

        XCTAssertEqual(receivedDisposition, .cancelAuthenticationChallenge)
    }

    func testNonServerTrustChallengeUsesDefaultHandling() {
        let policy = CertificatePinningPolicy(["test.example.com": []])
        let delegate = PinningDelegate(policy: policy)
        let challenge = makeBasicAuthChallenge(host: "test.example.com")

        var receivedDisposition: URLSession.AuthChallengeDisposition = .cancelAuthenticationChallenge

        delegate.urlSession(.shared, didReceive: challenge) { disposition, _ in
            receivedDisposition = disposition
        }

        XCTAssertEqual(receivedDisposition, .performDefaultHandling)
    }

    // MARK: - PinnedURLSession conformance (synchronous)

    func testPinnedURLSessionConformsToNetworkService() {
        let service: NetworkService = PinnedURLSession(
            policy: CertificatePinningPolicy(["api.example.com": []])
        )
        XCTAssertNotNil(service)
    }

    func testPinnedURLSessionUsableWithNetworkProviderFactory() {
        let session = PinnedURLSession(policy: CertificatePinningPolicy(["api.example.com": []]))
        let provider = NetworkProviderFactory.create(networkService: session)
        XCTAssertNotNil(provider)
    }
}

// MARK: - Test Infrastructure

/// URLProtectionSpace subclass that injects a SecTrust — URLProtectionSpace exposes
/// serverTrust as a read-only computed property so we override it here.
private final class ServerTrustProtectionSpace: URLProtectionSpace, @unchecked Sendable {
    private let _serverTrust: SecTrust

    init(host: String, trust: SecTrust) {
        self._serverTrust = trust
        super.init(
            host: host, port: 443, protocol: "https",
            realm: nil, authenticationMethod: NSURLAuthenticationMethodServerTrust
        )
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var serverTrust: SecTrust? {
        _serverTrust
    }
}

/// Minimal URLAuthenticationChallengeSender stub required by URLAuthenticationChallenge init.
private final class ChallengeSenderStub: NSObject, URLAuthenticationChallengeSender {
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}
    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}
    func cancel(_ challenge: URLAuthenticationChallenge) {}
}
#endif
