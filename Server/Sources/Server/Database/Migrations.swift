/// Every migration, in the order they apply. Append only: never edit or reorder one that
/// has been deployed.
enum Migrations {
    static let all: [Migration] = [
        // The table as the Symfony server left it (its last Doctrine migration,
        // Version20261104234058), so this is a no-op on the existing databases and the
        // switch moves no data. Doctrine's own doctrine_migration_versions table stays
        // until a later release.
        //
        // - identifier: base62, case-sensitive, hence ascii_bin. Older shares may hold
        //   other identifiers of up to 36 characters.
        // - info: the JSON body as sent, `{"iterations", "salt", "sealed"}`. MariaDB's
        //   JSON is LONGTEXT with a json_valid check.
        // - admin_token_hash: SHA-256 of the admin token, hex-encoded.
        // - created_at, updated_at: UTC, to the second.
        Migration(
            id: "0001-shared-data",
            statements: [
                """
                CREATE TABLE IF NOT EXISTS shared_data (
                    id INT AUTO_INCREMENT NOT NULL,
                    identifier CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
                    info JSON NOT NULL,
                    created_at DATETIME NOT NULL,
                    updated_at DATETIME NOT NULL,
                    admin_token_hash CHAR(64) NOT NULL,
                    PRIMARY KEY (id),
                    UNIQUE KEY UNIQ_170598FB772E836A (identifier)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
                """
            ]
        )
    ]
}
