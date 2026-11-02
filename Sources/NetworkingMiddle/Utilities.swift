import Foundation

extension String {
    /// Add a path component \ after the `String`
    ///
    /// Exemple:
    ///    ```
    ///    let urlString = "http://intech-consulting.fr"
    ///    let appendingPathComponent = urlString.appendingPathComponent("v1/users/login")
    ///    /// return "http://intech-consulting.fr/v1/users/login"
    ///    ```
    ///
    /// - Parameter pathComponent: The path component
    /// - Returns: A `String`
    func appendingPathComponent(_ pathComponent: String) -> String {
        guard !pathComponent.isEmpty else { return self }

        let base = hasSuffix("/") ? String(dropLast()) : self
        let component = pathComponent.hasPrefix("/") ? String(pathComponent.dropFirst()) : pathComponent
        return base + "/" + component
    }
}

/// A type that represents a dictionary.
extension Dictionary {
    /// Convert the dictionary to a JSON string.
    ///
    /// - Returns: A JSON string.
    var jsonString: String {
        guard let json = try? JSONSerialization.data(
            withJSONObject: self,
            options: []
        ) else { return "" }

        return String(data: json, encoding: .utf8) ?? ""
    }
}

/// A type that represents an array.
extension Array {
    /// Convert the array to a string of key-value pairs.
    ///
    /// - Returns: A string of key-value pairs.
    var jsonString: String {
        guard let json = try? JSONSerialization.data(
            withJSONObject: self,
            options: []
        ) else { return "" }

        return String(data: json, encoding: .utf8) ?? ""
    }
}

/// A type that represents an array.
extension Dictionary {
    /// Convert the dictionary to a string of key-value pairs.
    ///
    /// - Returns: A string of key-value pairs.
    var keyValuePairs: String {
        map { keyValue in
            let key = keyValue.key
            guard
                let value = "\(keyValue.value)".addingPercentEncoding(
                    withAllowedCharacters: CharacterSet.urlQueryAllowed
                )
            else { return "\(key)=\(keyValue.value)" }

            return "\(key)=\(value)"
        }
        .joined(separator: "&")
    }
}

/// A type that represents a dictionary.
extension Dictionary {
    /// Merge the contents of a dictionary into the current dictionary.
    ///
    /// - Parameter dictionary: The dictionary to merge.
    mutating func merge(contentsOf dictionary: [Key: Value]) {
        dictionary.forEach { key, value in
            self[key] = value
        }
    }

    /// Merge the contents of a dictionary into the current dictionary.
    ///
    /// - Parameter dictionary: The dictionary to merge.
    /// - Returns: A new dictionary with the merged contents.
    func merging(contentsOf dictionary: [Key: Value]) -> [Key: Value] {
        var me = self
        me.merge(contentsOf: dictionary)
        return me
    }
}

/// A protocol that represents an optional type.
protocol OptionalProtocol {
    associatedtype Wrapped
    /// Return the unboxed value of the optional.
    var unbox: Wrapped? { get }
    /// Initialize an optional with a value.
    init(nilLiteral: ())
    /// Initialize an optional with a value.
    init(_ some: Wrapped)
}

extension Optional: OptionalProtocol {
    /// Return the unboxed value of the optional.
    public var unbox: Wrapped? {
        self
    }
}

extension Dictionary where Value: OptionalProtocol {
    /// Return a new dictionary with the non-nil values.
    var nonNils: [Key: Value.Wrapped] {
        var result: [Key: Value.Wrapped] = [:]

        forEach { pair in
            if let value = pair.value.unbox {
                result[pair.key] = value
            }
        }

        return result
    }
}

extension Dictionary where Key: OptionalProtocol, Value: OptionalProtocol, Key.Wrapped: Hashable {
    /// Map over the dictionary and return a new dictionary with the transformed keys and values.
    ///
    /// - Parameter transform: A closure that takes a key and value and returns a new key and value.
    /// - Returns: A new dictionary with the transformed keys and values.
    func compactMap(
        _ transform: (Key, Value) throws -> (Key.Wrapped, Value.Wrapped)
    ) rethrows -> [Key.Wrapped: Value.Wrapped] {
        var result: [Key.Wrapped: Value.Wrapped] = [:]
        for (key, value) in self {
            let (transformedKey, transformedValue) = try transform(key, value)
            result[transformedKey] = transformedValue
        }
        return result
    }

    /// Map over the dictionary and return a new dictionary with the transformed keys and values.
    ///
    /// - Parameter transform: A closure that takes a key and value and returns a new key and value.
    /// - Returns: A new dictionary with the transformed keys and values.
    func compactMap() -> [Key.Wrapped: Value.Wrapped] {
        var result: [Key.Wrapped: Value.Wrapped] = [:]
        for (key, value) in self {
            if let key = key.unbox, let value = value.unbox {
                result[key] = value
            }
        }
        return result
    }
}

/// A type that can be used to map over a dictionary.
extension Dictionary {
    /// Map over the dictionary and return a new dictionary with the transformed keys and values.
    ///
    /// - Parameter transform: A closure that takes a key and value and returns a new key and value.
    /// - Returns: A new dictionary with the transformed keys and values.
    func map<T: Hashable, U>(_ transform: (Key, Value) throws -> (T, U)) rethrows -> [T: U] {
        var result: [T: U] = [:]
        for (key, value) in self {
            let (transformedKey, transformedValue) = try transform(key, value)
            result[transformedKey] = transformedValue
        }
        return result
    }
}

/// A type that can be used to convert `Data` to a `String`.
extension Data {
    /// Convert the `Data` to a `String` using the specified encoding.
    ///
    /// - Parameter encoding: The encoding to use to convert the `Data` to a `String`.
    /// - Returns: A `String` or `nil` if the conversion fails.
    public func string(encoding: String.Encoding) -> String? {
        String(data: self, encoding: encoding)
    }

    func decodedObject<D: Decodable>(using decoder: JSONDecoder = .init()) throws -> D {
        try decoder.decode(D.self, from: self)
    }
}

extension Encodable {
    func data(using encoder: JSONEncoder = .init()) throws -> Data {
        try encoder.encode(self)
    }

    func string(using encoder: JSONEncoder = .init()) throws -> String {
        guard let string = try data(
            using: encoder
        ).string else { throw APIError.client("Encodable+string failed to convert to string") }

        return string
    }

    func dictionary(
        using encoder: JSONEncoder = .init(),
        options: JSONSerialization.ReadingOptions = []
    ) throws -> [String: Any] {
        try JSONSerialization
            .jsonObject(with: data(using: encoder), options: options) as? [String: Any] ?? [:]
    }
}

extension Sequence<UInt8> {
    var string: String? {
        String(bytes: self, encoding: .utf8)
    }
}
