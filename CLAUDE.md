# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NetworkingMiddle is a Swift networking framework providing a modular, protocol-oriented approach to HTTP networking with support for request modification, interception, and comprehensive testing utilities. The package targets iOS 13+ and macOS 11+.

## Build & Test Commands

### Setup Environment
```bash
# Install mise tools (swiftlint, mint)
make mise_install

# Bootstrap mint packages (includes executor tool)
make mint_bootstrap
```

### Building
```bash
# Standard build
make build

# Linux build (using Docker)
make build_linux
```

### Testing
```bash
# Run all tests with coverage
make test

# Run specific test
swift test --filter NetworkingMiddleTests

# Run single test
swift test --filter NetworkingMiddleTests.InterceptorLoggerTests/testInterceptorLogger

# Linux testing
make test_linux
```

### Code Quality
```bash
# Format code
make format

# Check formatting (fails if code needs formatting)
make check_format

# Check documentation
make check_documentation
```

### Documentation
```bash
# Build DocC documentation
make build_documentation

# Start local documentation server
make start_documentation_server
```

## Architecture

### Core Components

The framework is built around several key protocols that work together:

1. **NetworkService & NetworkTask** (Sources/NetworkingMiddle/NetworkService.swift)
   - Low-level abstraction over URLSession for network operations
   - `URLSession` conforms to `NetworkService` by default
   - Enables mocking and testing without actual network calls

2. **NetworkProvider** (Sources/NetworkingMiddle/NetworkProvider.swift)
   - Central orchestrator for network requests
   - Applies request modifiers in sequence before sending
   - Chains interceptors in reverse order around the actual network call
   - Created via `NetworkProviderFactory.create()`
   - Flow: Request → Modifiers → Interceptors → NetworkService → Response

3. **Request** (Sources/NetworkingMiddle/Request.swift)
   - Protocol defining HTTP requests (path, method, parameters, body, headers)
   - Create via `RequestFactory.create()` or `NetworkProvider.newBuilder()`
   - Convenience methods: `.authorised(bearer:)`, `.token()`, `.set(_:forHttpHeaderKey:)`
   - Converts to URLRequest via `.asURLRequest(baseURL:)`

4. **Response** (Sources/NetworkingMiddle/Response.swift)
   - Protocol representing HTTP responses
   - Rich API: `.validate()`, `.decode()`, `.map()`, `.flatMap()`, `.result()`, `.mapError()`
   - Supports both throwing and Result-based error handling
   - Can decode both success responses and error bodies

5. **RequestModifier** (Sources/NetworkingMiddle/RequestModifier.swift)
   - Modifies requests before execution (auth tokens, headers)
   - Built-in: `RequestModifierFactory.bearerToken()`, `.token()`, `.header()`
   - Applied sequentially to all requests through the provider

6. **Interceptor** (Sources/NetworkingMiddle/Interceptor.swift)
   - Intercepts request/response cycle using chain-of-responsibility pattern
   - Built-in: `InterceptorFactory.interceptorLogger()`, `.interceptorTimeLogger()`
   - Applied in reverse order (last added wraps first)
   - Use for logging, metrics, retry logic, etc.

### Request Flow

```
NetworkProvider.request(baseURL, request)
  ↓
Apply all RequestModifiers sequentially
  ↓
Build interceptor chain (reversed)
  ↓
Execute through interceptor chain
  ↓
NetworkService performs actual HTTP call
  ↓
Response bubbles back through interceptors
  ↓
Return Response to caller
```

### Module Structure

- **NetworkingMiddle**: Core networking abstractions and implementations
  - Depends on **AnyCodable** (internal module for flexible JSON handling)

- **NetworkingMiddleTesting**: Test utilities (robots, spies) for unit testing
  - Robot pattern: `NetworkServiceTestRobot`, `NetworkTaskRobot`, `NetworkingMiddleRobot`
  - Uses XCTest for assertions
  - Enables `InternalImportsByDefault` for access to internal types

- **NetworkingMiddleMocking**: MockingBird URLProtocol-based HTTP mocking
  - Register via `MockingBird.register(inSession:)` or `.register(inConfig:)`
  - Configure mocks: `MockingBird.setMockBundle(withPath:)`
  - Mock bundles use `bundle.json` format with URL matching and query parameters

### Key Design Patterns

- **Protocol-Oriented**: Everything is protocol-based for testability and flexibility
- **Type Erasure**: `AnyRequest`, `AnyResponse` for heterogeneous collections
- **Factory Pattern**: `NetworkProviderFactory`, `RequestFactory`, `InterceptorFactory`, `RequestModifierFactory`
- **Chain of Responsibility**: Interceptors wrap each other forming execution chain
- **Robot Pattern**: Testing utilities use robot pattern for fluent test APIs

## Testing Conventions

- Use robot pattern from `NetworkingMiddleTesting` for fluent assertions
- Mock network layer using `NetworkingMiddleMocking` for integration-style tests
- Test files mirror source structure in `Tests/NetworkingMiddleTests/`
- Tests include unit tests, interceptor tests, modifier tests, and parameter encoding tests

## Important Implementation Notes

- All protocols use `Sendable` for Swift 6 concurrency safety
- Linux support requires `#if canImport(FoundationNetworking)` imports
- Request parameters implement `RequestParameters` protocol with `.apply(urlRequest:)`
- Empty responses handled via `EmptyCodable` type
- Response headers stored as `[AnyHashable: AnyCodable]` for flexibility
- URLRequest extension `.empty` provides default empty request for error cases

## Common Patterns

### Creating a Network Client
```swift
let provider = NetworkProviderFactory.create(
    networkService: URLSession.shared,
    modifiers: [
        RequestModifierFactory.bearerToken(token: "...")
    ],
    interceptors: [
        InterceptorFactory.interceptorLogger { print($0) }
    ]
)
```

### Making Requests
```swift
let request = RequestFactory.create(
    path: "/users",
    method: .get,
    parameters: QueryParametersEncodable(["page": 1])
)

let response = try await provider.request(baseURL: "https://api.example.com", request: request)
let users = try response.validate().decode([User].self, using: JSONDecoder())
```

### Adding Dynamic Modifications
```swift
let provider = provider
    .modifyRequests { baseURL, request in
        // Modify request
    }
    .intercept { baseURL, request, next in
        // Wrap the call
        let response = try await next(baseURL, request)
        // Process response
        return response
    }
```
