# How it works

## NetworkService:

This ``NetworkService`` protocol abstracts the underlying network engine (like URLSession). It defines methods for creating and managing network tasks. The default implementation uses URLSession, but you can provide your own for testing or customization.

> This protocol is used to mock the network service for testing purposes.

## NetworkProvider:

This ``NetworkProvider`` is the main interface for sending requests. It allows you to:

* Build requests (newBuilder)
* Modify requests before sending (using ``RequestModifier``)
* Intercept requests/responses (using ``Interceptor``)
* Send requests asynchronously and receive typed responses

## Request & RequestParameters:

* ``Request`` is a protocol representing an HTTP request (path, method, parameters, body, headers).
* ``RequestParameters`` is a protocol for anything that can be applied to a URLRequest (e.g., query params, JSON body, form data).

## Response:

* ``Response`` Represents the result of a network call, including body, headers, status code, and error.
* ``Response`` Provides utilities for decoding, mapping, and error handling.

## Errors :

A comprehensive ``APIError`` error type for network, parsing, client, and authentication errors.

## How a Request Flows

### Build a Request:

Use NetworkProvider.newBuilder or RequestFactory.create to construct a request with path, method, parameters, body, and headers.

### Modify/Intercept (Optional):

* Add RequestModifiers to tweak requests (e.g., add auth headers).
* Add Interceptors to log, retry, or handle requests/responses in a chain.

### Send the Request:

Call NetworkProvider.request(baseURL:request:) to send the request.

* The provider applies modifiers and interceptors.
* The request is converted to a URLRequest and executed via the NetworkService.

### Handle the Response:

* The response is wrapped in a Response object.
* You can validate, decode, or map the response as needed.
* Errors are handled using the APIError type.

## Extensibility

### Custom Network Engines:

Implement your own NetworkService for mocking or alternative networking backends.

### Custom Modifiers/Interceptors:

Easily add cross-cutting concerns (auth, logging, retry, etc.) by conforming to RequestModifier or Interceptor.

## Usage Example

### To create a simple request use this snippet

```swift
import NetworkingMiddle

let provider = NetworkProviderFactory.create(networkService: URLSession.shared)
let request = provider.newBuilder(
    path: "/api/v1/resource",
    method: .get,
    parameters: nil,
    body: nil,
    headers: [:]
)

Task {
    do {
        let response = try await provider.request(baseURL: "https://example.com", request: request)
        let model = try response.decode(MyModel.self, using: JSONDecoder())
        // or
        // let model = try response.validate().decode(MyModel.self, using: JSONDecoder())
        // Use your model
    } catch {
        // Handle error
    }
}
```
