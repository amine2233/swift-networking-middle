import Foundation

/// A `Decodable` type that represents an empty JSON object.
///
/// This struct is useful for decoding JSON data where the expected structure
/// is an empty object (i.e., `{}`), but you want to enforce that no keys are present.
public struct EmptyDecodable: Decodable {
    /// Private helper struct that can represent any coding key as either a `String` or `Int`.
    private struct AnyCodingKey: CodingKey {
        let intValue: Int?
        let stringValue: String

        init?(intValue: Int) {
            self.intValue = intValue
            self.stringValue = "\(intValue)"
        }

        init?(stringValue: String) {
            self.intValue = Int(stringValue)
            self.stringValue = stringValue
        }
    }

    /// Initializes the instance by decoding it from a `Decoder`.
    ///
    /// - Parameter decoder: The decoder to use for decoding.
    /// - Throws: An error if decoding fails.
    public init(from decoder: Decoder) throws {
        // Since `AnyCodingKey` can take any `String` or `Int` value,
        // if there's a keyed container, you're guaranteed to read from
        // it successfully.
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        guard container.allKeys.isEmpty else {
            // Or whatever you want:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected empty object, but received object with keys: \(container.allKeys)"
                )
            )
        }
    }
}
