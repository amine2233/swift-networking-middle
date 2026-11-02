# Using Certificate Pinning

Protect your app against man-in-the-middle attacks by pinning the server's public key.

## Overview

`NetworkingMiddlePinning` provides ``PinnedURLSession``, a drop-in replacement for `URLSession.shared` that validates every TLS handshake against a set of expected public-key hashes before allowing a connection.

It integrates with `NetworkingMiddle` without changing any existing API — just swap the `networkService` argument when creating your provider.

> Important: `NetworkingMiddlePinning` is only available on Apple platforms (iOS, macOS, etc.).
> It is not compiled on Linux.

## Computing the pin

The pin is the **SHA-256 hash of the SubjectPublicKeyInfo (SPKI) DER bytes** of the server certificate's public key.

Run this once against your server's certificate to get the value:

```bash
# From a live host:
openssl s_client -connect api.example.com:443 -servername api.example.com 2>/dev/null \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform DER \
  | openssl dgst -sha256 -binary \
  | base64

# From a local certificate file:
openssl x509 -in cert.pem -pubkey -noout \
  | openssl pkey -pubin -outform DER \
  | openssl dgst -sha256 -binary \
  | base64
```

The output is your pin, for example:

```
UWwiE8TqQkddVS2ZT3DLIOImjmqzUHIiPN6bDLmfYdg=
```

Convert it to `Data` in Swift using `Data(base64Encoded:)`.

## Basic setup

Create a ``CertificatePinningPolicy`` with one hash per host, then pass a ``PinnedURLSession`` to `NetworkProviderFactory.create`:

```swift
import NetworkingMiddle
import NetworkingMiddlePinning

let pinHash = Data(base64Encoded: "UWwiE8TqQkddVS2ZT3DLIOImjmqzUHIiPN6bDLmfYdg=")!

let provider = NetworkProviderFactory.create(
    networkService: PinnedURLSession(policy: CertificatePinningPolicy([
        "api.example.com": [pinHash]
    ]))
)

// Use the provider exactly as before
let request = RequestFactory.create(path: "/users", method: .get)
let response = try await provider.request(baseURL: "https://api.example.com", request: request)
let users = try response.validate().decode([User].self, using: JSONDecoder())
```

## Multiple hosts

Pin each host independently. Hosts not listed in the policy are rejected:

```swift
let policy = CertificatePinningPolicy([
    "api.example.com":  [Data(base64Encoded: "<primary hash>")!],
    "cdn.example.com":  [Data(base64Encoded: "<cdn hash>")!]
])

let provider = NetworkProviderFactory.create(
    networkService: PinnedURLSession(policy: policy)
)
```

## Backup pins

Store a second hash per host so a certificate rotation does not break the app in the field:

```swift
let policy = CertificatePinningPolicy([
    "api.example.com": [
        Data(base64Encoded: "<current key hash>")!,
        Data(base64Encoded: "<backup key hash>")!
    ]
])
```

A connection is allowed as soon as **any** of the listed hashes matches the server's public key.

## Custom URLSessionConfiguration

Pass a custom `URLSessionConfiguration` when you need background sessions, custom timeouts, or additional protocol handlers:

```swift
let configuration = URLSessionConfiguration.default
configuration.timeoutIntervalForRequest = 30

let pinnedSession = PinnedURLSession(
    policy: policy,
    configuration: configuration
)
```

## Handling pinning failures

When a connection is rejected because the server's public key does not match any pin, the underlying `URLSessionDataTask` is cancelled. The error surfaces as ``NetworkingMiddle/APIError/certificatePinningFailed(_:)`` containing the host name:

```swift
do {
    let response = try await provider.request(baseURL: "https://api.example.com", request: request)
} catch APIError.certificatePinningFailed(let host) {
    // The connection to `host` was rejected — the certificate may have changed
    // or the device is under a MITM attack.
    print("Pinning failure for host: \(host)")
} catch {
    // Other network errors
}
```

> Note: The raw network error thrown by `URLSession` when a challenge is cancelled is an
> `NSURLError`. The connection attempt will fail with that error; `APIError.certificatePinningFailed`
> is available to catch at a higher level in your own error-mapping interceptor.

## Combining with interceptors and modifiers

``PinnedURLSession`` is a plain ``NetworkingMiddle/NetworkService``, so all other provider features still work:

```swift
let provider = NetworkProviderFactory.create(
    networkService: PinnedURLSession(policy: policy),
    modifiers: [
        RequestModifierFactory.bearerToken(token: authToken)
    ],
    interceptors: [
        InterceptorFactory.interceptorLogger { print($0) }
    ]
)
```
