# How Response Works

``Response`` is a protocol in the NetworkingMiddle package that represents the result of a network request. It encapsulates the response data, headers, status code, and potential errors, providing a unified interface for handling network responses.

## Key Components

### Protocol Definition:

```swift
   public protocol Response: Sendable {
       var body: Data? { get }
       var headers: [String: String]? { get }
       var statusCode: Int? { get }
       var error: Error? { get }
   }
```

`body`: The raw response data (e.g., JSON, binary).
`headers`: HTTP headers returned by the server.
`statusCode`: HTTP status code (e.g., 200, 404, 500).
`error`: Any error that occurred during the request.

## Default Implementation:

```swift
struct ResponseDefault: Response {
    var body: Data?
    var headers: [String: String]?
    var statusCode: Int?
    var error: Error?
}
```

A concrete implementation of Response for easy instantiation.

## Utility Methods:

The Response protocol is extended with several utility methods:

* ``Response.validate()``: Checks if the response has an error and throws it if present.
* ``Response.decode<Model>(_ type:using:)``: Decodes the response body into a Decodable model.
* ``Response.decodeResult<Model>(_ type:using:)``: Decodes the response body into a Result (success or failure).
* ``Response.map<Model>(_ transform:)``: Transforms the response into another type.
* ``Response.flatMap<Model>(_ transform:)``: Transforms the response into another Response type.
* ``Response.result()``: Returns a Result representing success or failure.
* ``Response.mapError<MapError>(_ transform:)``: Maps the response error into a different error type.
* ``Response.statusCode()``: Returns the status code or throws an error if not found.

## Error Handling:

* ``Response.error(_ error:)``: A static method to create an error response.
* ``ResponseError``: A concrete implementation of Response for error cases.

## How to Use Response:

### Basic Response Handling:

```swift
let response = try await provider.request(baseURL: "https://example.com", request: request)

// Check for errors
try response.validate()

// Access raw data
if let data = response.body {
    // Process raw data
}

// Access headers
if let headers = response.headers {
    // Process headers
}

// Access status code
if let statusCode = response.statusCode {
    // Process status code
}
```

### Decoding Responses:

```swift
struct User: Decodable {
    let name: String
    let age: Int
}

let response = try await provider.request(baseURL: "https://example.com", request: request)
let user = try response.decode(User.self, using: JSONDecoder())
print(user.name) // "John"
```

### Handling Errors with Result:

```swift
let response = try await provider.request(baseURL: "https://example.com", request: request)
let result = try response.decodeResult(User.self, using: JSONDecoder())

switch result {
case .success(let user):
    print(user.name) // "John"
case .failure(let error):
    print("Error: \(error.localizedDescription)")
}
```

### Transforming Responses:

```swift
let response = try await provider.request(baseURL: "https://example.com", request: request)
let transformed = response.map { response in
    // Transform response into another type
    return "Transformed: \(response.statusCode ?? 0)"
}
print(transformed) // "Transformed: 200"
```

### Error Mapping:

```swift
let response = try await provider.request(baseURL: "https://example.com", request: request)
let result = response.mapError { error in
    // Map error into a custom error type
    return MyCustomError(error)
}
```

## Key Benefits

* Unified Interface: Encapsulates all response data (body, headers, status code, error).
* Type Safety: Strong typing for decoding into Decodable models.
* Error Handling: Comprehensive error handling with Result and error mapping.
* Flexibility: Supports various transformations and mappings.
