import PadlokAPIServer

/// Why a sealed address was refused with a 422.
struct InvalidSharedInfo: Error, Equatable {
    var message: String
}

extension SharedInfo {
    static let iterationsRange = 1...1_000_000
    static let maxSaltLength = 255
    static let maxSealedLength = 16_384

    /// The bounds the Symfony server enforced. Lengths count Unicode scalars, as PHP's
    /// mb_strlen did; the apps only ever send base64.
    ///
    /// The iterations cap stops a share from making a recipient's app hang on key
    /// derivation, with room to raise the count: the apps use 1000.
    init(validating body: Components.Schemas.SharedInfo) throws(InvalidSharedInfo) {
        guard Self.iterationsRange.contains(body.iterations) else {
            throw InvalidSharedInfo(message: "iterations must be between 1 and 1000000.")
        }
        guard !body.salt.isEmpty, body.salt.unicodeScalars.count <= Self.maxSaltLength else {
            throw InvalidSharedInfo(message: "salt must be 1 to \(Self.maxSaltLength) characters.")
        }
        guard !body.sealed.isEmpty, body.sealed.unicodeScalars.count <= Self.maxSealedLength else {
            throw InvalidSharedInfo(message: "sealed must be 1 to \(Self.maxSealedLength) characters.")
        }
        self.init(iterations: body.iterations, salt: body.salt, sealed: body.sealed)
    }
}
