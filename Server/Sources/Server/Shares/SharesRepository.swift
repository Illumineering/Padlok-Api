import Foundation
import SQLKit

/// A sealed address and what derives its key, as stored in `shared_data.info`.
///
/// `salt` and `sealed` are opaque to the server: stored and returned exactly as sent.
struct SharedInfo: Codable, Equatable, Sendable {
    var iterations: Int
    var salt: String
    var sealed: String
}

/// A share as read for an update or a deletion.
struct StoredShare: Equatable, Sendable {
    var id: Int
    var info: SharedInfo
    /// SHA-256 of the admin token, hex-encoded.
    var adminTokenHash: String
}

/// The `shared_data` table.
struct SharesRepository: Sendable {
    let sql: any SQLDatabase

    func insert(identifier: String, info: SharedInfo, adminTokenHash: String, at now: Date) async throws {
        try await sql.raw(
            """
            INSERT INTO shared_data (identifier, info, admin_token_hash, created_at, updated_at)
            VALUES (\(bind: identifier), \(bind: try Self.json(info)), \(bind: adminTokenHash), \(bind: now), \(bind: now))
            """
        ).run()
    }

    /// The share with exactly this identifier: identifiers are case-sensitive.
    func find(identifier: String) async throws -> StoredShare? {
        // The column is ASCII: MariaDB refuses to compare it with a string it cannot
        // convert, and no identifier is anything but letters, digits and dashes anyway.
        guard Self.isPlausible(identifier) else {
            return nil
        }
        guard
            let row = try await sql.raw(
                "SELECT id, info, admin_token_hash FROM shared_data WHERE identifier = \(bind: identifier)"
            ).first()
        else {
            return nil
        }
        return StoredShare(
            id: try row.decode(column: "id", as: Int.self),
            info: try JSONDecoder().decode(SharedInfo.self, from: Data(try row.decode(column: "info", as: String.self).utf8)),
            adminTokenHash: try row.decode(column: "admin_token_hash", as: String.self)
        )
    }

    func update(id: Int, info: SharedInfo, at now: Date) async throws {
        try await sql.raw(
            "UPDATE shared_data SET info = \(bind: try Self.json(info)), updated_at = \(bind: now) WHERE id = \(bind: id)"
        ).run()
    }

    func delete(id: Int) async throws {
        try await sql.raw("DELETE FROM shared_data WHERE id = \(bind: id)").run()
    }

    /// Base62 today; UUIDs, with dashes, for the oldest shares.
    static func isPlausible(_ identifier: String) -> Bool {
        (1...36).contains(identifier.utf8.count)
            && identifier.utf8.allSatisfy { byte in
                (0x30...0x39).contains(byte) || (0x41...0x5A).contains(byte) || (0x61...0x7A).contains(byte) || byte == 0x2D
            }
    }

    private static func json(_ info: SharedInfo) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return String(decoding: try encoder.encode(info), as: UTF8.self)
    }
}
