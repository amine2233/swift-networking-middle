# How RequestParameters Works

``RequestParameters`` is a protocol in the `NetworkingMiddle` package that allows you to customize or modify a `URLRequest` by applying additional parameters. It’s designed to be flexible and reusable, supporting various types of parameters (query, JSON, form, etc.).

## Key Components

### Protocol Definition:

```swift
public protocol RequestParameters: Sendable {
    func apply(urlRequest: URLRequest) throws -> URLRequest
}
```

* The apply method takes a URLRequest and returns a modified version with the parameters applied.
* It can throw an error if applying the parameters fails.

## Factory Methods:

The ``RequestParametersFactory`` enum provides static methods to create different types of ``RequestParameters``:

* ``RequestParametersFactory.encodableParameter(model:)``: For Encodable models (e.g., Swift structs or classes).
* ``RequestParametersFactory.jsonParameters(model:)``: For generic JSON objects.
* ``RequestParametersFactory.queryParameters(query:)``: For URL query parameters.
* ``RequestParametersFactory.formParameters(data:)``: For form-encoded data.
* ``RequestParametersFactory.encodableBodyParameters(body:)``: For JSON body parameters.

> check ``RequestParametersFactory`` to find all the possible methods.

## How to Use RequestParameters

### Query Parameters

```swift
let queryParams = RequestParametersFactory.queryParameters(query: ["page": "1", "limit": "10"])
let request = provider.newBuilder(
    path: "/api/v1/resource",
    method: .get,
    parameters: queryParams,
    body: nil,
    headers: [:]
)
```

> This will append ?page=1&limit=10 to the URL.

### JSON Body

```swift
let jsonBody = RequestParametersFactory.jsonParameters(model: ["name": "John", "age": 30])
let request = provider.newBuilder(
    path: "/api/v1/resource",
    method: .post,
    parameters: nil,
    body: jsonBody,
    headers: [:]
)
```

This will set the request body to `{"name":"John","age":30}` with the `Content-Type: application/json` header.

### Form Parameters

```swift
let formParams = RequestParametersFactory.formParameters(data: ["username": "john", "password": "secret"])
let request = provider.newBuilder(
    path: "/api/v1/login",
    method: .post,
    parameters: nil,
    body: formParams,
    headers: [:]
)
```
This will set the request body to ``username=john&password=secret` with the `Content-Type: application/x-www-form-urlencoded` header.

### Encodable Model

```swift
struct User: Encodable {
    let name: String
    let age: Int
}

let user = User(name: "John", age: 30)
let encodableParams = RequestParametersFactory.encodableParameter(model: user)
let request = provider.newBuilder(
    path: "/api/v1/users",
    method: .post,
    parameters: nil,
    body: encodableParams,
    headers: [:]
)
```

This will encode the `User` model to JSON and set it as the request body.
