import Foundation

// The API's JSON is loosely typed: numbers sometimes arrive as strings, fields go missing,
// and single list items can be malformed. The Android app reads it with optInt/optString
// defaults and skips bad items; these helpers do the same with Codable.

struct AnyCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init(_ string: String) {
        stringValue = string
        intValue = nil
    }

    init?(stringValue: String) {
        self.init(stringValue)
    }

    init?(intValue: Int) {
        stringValue = String(intValue)
        self.intValue = intValue
    }
}

extension KeyedDecodingContainer where Key == AnyCodingKey {
    /// An integer, also accepted as a whole Double or a numeric string.
    func lenientInt(_ key: String) -> Int? {
        let key = AnyCodingKey(key)
        if let value = try? decode(Int.self, forKey: key) { return value }
        if let value = try? decode(Double.self, forKey: key), value.isFinite { return Int(value) }
        if let value = try? decode(String.self, forKey: key) {
            let trimmed = value.trimmingCharacters(in: .whitespaces)
            return Int(trimmed) ?? Double(trimmed).flatMap { $0.isFinite ? Int($0) : nil }
        }
        return nil
    }

    /// A number, also accepted as a numeric string.
    func lenientDouble(_ key: String) -> Double? {
        let key = AnyCodingKey(key)
        if let value = try? decode(Double.self, forKey: key) { return value }
        if let value = try? decode(String.self, forKey: key) {
            return Double(value.trimmingCharacters(in: .whitespaces))
        }
        return nil
    }

    /// A string, also accepted as a number.
    func lenientString(_ key: String) -> String? {
        let key = AnyCodingKey(key)
        if let value = try? decode(String.self, forKey: key) { return value }
        if let value = try? decode(Int.self, forKey: key) { return String(value) }
        if let value = try? decode(Double.self, forKey: key) { return String(value) }
        return nil
    }

    /// The decodable elements of an array, skipping any that fail. Empty when the key is
    /// missing or isn't an array.
    func lossyArray<Element: Decodable>(_ key: String, of type: Element.Type = Element.self) -> [Element] {
        guard let wrapped = try? decode([Lossy<Element>].self, forKey: AnyCodingKey(key)) else { return [] }
        return wrapped.compactMap(\.value)
    }
}

/// Decodes as `nil` instead of throwing, so one bad element doesn't fail a whole array.
struct Lossy<Wrapped: Decodable>: Decodable {
    let value: Wrapped?

    init(from decoder: any Decoder) throws {
        value = try? Wrapped(from: decoder)
    }
}

/// A top-level JSON array whose malformed elements are skipped.
struct LossyList<Element: Decodable>: Decodable {
    let elements: [Element]

    init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var elements: [Element] = []
        while !container.isAtEnd {
            // Lossy never throws for a present element, so the cursor always advances;
            // bail out rather than loop if the container itself fails.
            guard let lossy = try? container.decode(Lossy<Element>.self) else { break }
            if let element = lossy.value {
                elements.append(element)
            }
        }
        self.elements = elements
    }
}
