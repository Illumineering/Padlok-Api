<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

final class Version20261104231835 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Store a SHA-256 of each admin token instead of the token itself';
    }

    public function isTransactional(): bool
    {
        // DDL implicitly commits on MySQL/MariaDB, so this migration cannot run
        // in a transaction.
        return false;
    }

    public function up(Schema $schema): void
    {
        // Add the column as nullable, fill it, then tighten it, so that existing
        // tokens are hashed rather than lost. SHA2() returns lowercase hex, the
        // same as PHP's hash('sha256').
        $this->addSql('ALTER TABLE shared_data ADD admin_token_hash CHAR(64) DEFAULT NULL');
        $this->addSql('UPDATE shared_data SET admin_token_hash = SHA2(admin_token, 256)');
        $this->addSql('ALTER TABLE shared_data CHANGE admin_token_hash admin_token_hash CHAR(64) NOT NULL, DROP admin_token');
    }

    public function down(Schema $schema): void
    {
        $this->throwIrreversibleMigrationException('Admin tokens cannot be recovered from their hashes; restore them from a backup.');
    }
}
