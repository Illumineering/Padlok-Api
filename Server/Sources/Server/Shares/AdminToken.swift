import Crypto
import Foundation

/// Share identifiers and admin tokens: 16 random bytes each, written in base62.
enum ShareCredentials {
    /// Digits, then uppercase, then lowercase letters, as the Symfony server's base62.
    private static let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".utf8)

    /// 128 random bits, from the system's cryptographically secure generator.
    static func random() -> String {
        var generator = SystemRandomNumberGenerator()
        return base62((0..<16).map { _ in UInt8.random(in: .min ... .max, using: &generator) })
    }

    /// `bytes` read as one big-endian number, written in base 62: at most 22 characters
    /// for 16 bytes.
    static func base62(_ bytes: [UInt8]) -> String {
        var number = bytes.drop { $0 == 0 }.map(Int.init)
        var digits: [UInt8] = []
        while !number.isEmpty {
            var quotient: [Int] = []
            var remainder = 0
            for byte in number {
                let accumulator = remainder * 256 + byte
                let digit = accumulator / 62
                remainder = accumulator % 62
                if !quotient.isEmpty || digit > 0 {
                    quotient.append(digit)
                }
            }
            digits.append(alphabet[remainder])
            number = quotient
        }
        return digits.isEmpty ? "0" : String(decoding: digits.reversed(), as: UTF8.self)
    }
}

/// Admin tokens are only stored as their SHA-256. They are random 128-bit values, so a
/// fast hash is enough: there is nothing to brute-force.
enum AdminToken {
    /// Hex-encoded, as in `shared_data.admin_token_hash`.
    static func hash(_ token: String) -> String {
        SHA256.hash(data: Data(token.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    /// Whether `token` hashes to `storedHash`, in time independent of where they differ.
    static func matches(_ token: String, storedHash: String) -> Bool {
        let candidate = Array(hash(token).utf8)
        let stored = Array(storedHash.lowercased().utf8)
        guard candidate.count == stored.count else {
            return false
        }
        return zip(candidate, stored).reduce(0) { $0 | ($1.0 ^ $1.1) } == 0
    }
}
