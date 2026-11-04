<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

final class Version20261104224030 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Align shared_data with the entity mapping: drop DBAL 3 type comments, use a JSON column for info, rename the identifier unique index';
    }

    public function isTransactional(): bool
    {
        // DDL implicitly commits on MySQL/MariaDB, so this migration cannot run
        // in a transaction.
        return false;
    }

    public function preUp(Schema $schema): void
    {
        // On MariaDB, JSON adds a json_valid() check constraint: make sure every
        // existing row passes it before altering anything.
        $invalid = (int) $this->connection->fetchOne('SELECT COUNT(*) FROM shared_data WHERE NOT JSON_VALID(info)');
        $this->abortIf($invalid > 0, \sprintf('%d shared_data rows have an info value that is not valid JSON.', $invalid));
    }

    public function up(Schema $schema): void
    {
        $this->addSql('ALTER TABLE shared_data CHANGE identifier identifier CHAR(36) NOT NULL, CHANGE info info JSON NOT NULL, CHANGE created_at created_at DATETIME NOT NULL, CHANGE updated_at updated_at DATETIME NOT NULL');
        $this->addSql('ALTER TABLE shared_data RENAME INDEX uniq_170598fbd17f50a6 TO UNIQ_170598FB772E836A');
    }

    public function down(Schema $schema): void
    {
        $this->addSql('ALTER TABLE shared_data CHANGE identifier identifier CHAR(36) NOT NULL COMMENT \'(DC2Type:guid)\', CHANGE info info LONGTEXT NOT NULL COMMENT \'(DC2Type:json)\', CHANGE created_at created_at DATETIME NOT NULL COMMENT \'(DC2Type:datetime_immutable)\', CHANGE updated_at updated_at DATETIME NOT NULL COMMENT \'(DC2Type:datetime_immutable)\'');
        $this->addSql('ALTER TABLE shared_data RENAME INDEX uniq_170598fb772e836a TO UNIQ_170598FBD17F50A6');
    }
}
