#if !canImport(FoundationNetworking)
import CryptoKit
import Foundation
import NetworkingMiddle

// MARK: - Policy

/// Maps host names to their expected SHA-256 hashes of the SubjectPublicKeyInfo
/// (SPKI) DER bytes. Multiple hashes per host support backup certificates.
///
/// Public-key pinning is used rather than raw certificate pinning so that the
/// pin survives a certificate renewal as long as the same key-pair is kept.
public struct CertificatePinningPolicy: Sendable {
    public let pinnedHashes: [String: [Data]]

    public init(_ pinnedHashes: [String: [Data]]) {
        self.pinnedHashes = pinnedHashes
    }
}

// MARK: - Delegate (private)

final class PinningDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    let policy: CertificatePinningPolicy

    init(policy: CertificatePinningPolicy) {
        self.policy = policy
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host
        guard let expectedHashes = policy.pinnedHashes[host], !expectedHashes.isEmpty else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Extract the public key hash from each certificate in the chain.
        // A match on any certificate (leaf or intermediate) is accepted.
        var matched = false
        let count = SecTrustGetCertificateCount(serverTrust)
        for index in 0 ..< count {
            guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, index),
                  let publicKey = SecCertificateCopyKey(certificate),
                  let keyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
                continue
            }

            let hash = Data(SHA256.hash(data: keyData))
            if expectedHashes.contains(hash) {
                matched = true
                break
            }
        }

        if matched {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// MARK: - PinnedURLSession

/// A `NetworkService` that wraps `URLSession` with certificate pinning.
///
/// Pass this instead of `URLSession.shared` to `NetworkProviderFactory.create(networkService:)`:
/// ```swift
/// let provider = NetworkProviderFactory.create(
///     networkService: PinnedURLSession(policy: CertificatePinningPolicy([
///         "api.example.com": [/* sha256 SPKI bytes */]
///     ]))
/// )
/// ```
public final class PinnedURLSession: NetworkService, @unchecked Sendable {
    private let session: URLSession
    /// Retain delegate explicitly; URLSession holds it weakly.
    private let delegate: PinningDelegate

    public init(
        policy: CertificatePinningPolicy,
        configuration: URLSessionConfiguration = .default
    ) {
        let d = PinningDelegate(policy: policy)
        self.delegate = d
        self.session = URLSession(configuration: configuration, delegate: d, delegateQueue: nil)
    }

    public func dataTask(
        request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) -> NetworkTask {
        session.dataTask(with: request, completionHandler: completionHandler) as NetworkTask
    }

    public func dataTask(
        url: URL,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) -> NetworkTask {
        session.dataTask(with: url, completionHandler: completionHandler) as NetworkTask
    }
}
#endif
