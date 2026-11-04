<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

final class Version20261104234058 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Make shared_data.identifier case-sensitive (ascii_bin), as base62 is';
    }

    public function isTransactional(): bool
    {
        // DDL implicitly commits on MySQL/MariaDB, so this migration cannot run
        // in a transaction.
        return false;
    }

    public function up(Schema $schema): void
    {
        // Identifiers are base62, so ASCII only. A binary collation is stricter than
        // the case-insensitive one, so the unique index cannot gain duplicates.
        $this->addSql('ALTER TABLE shared_data CHANGE identifier identifier CHAR(36) CHARACTER SET ascii NOT NULL COLLATE `ascii_bin`');
    }

    public function down(Schema $schema): void
    {
        // Back to the table default, utf8mb4_unicode_ci.
        $this->addSql('ALTER TABLE shared_data CHANGE identifier identifier CHAR(36) NOT NULL');
    }
}
