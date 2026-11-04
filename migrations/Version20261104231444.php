<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

final class Version20261104231444 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Drop the legacy sealed_shares table, whose rows were copied into shared_data';
    }

    public function isTransactional(): bool
    {
        // DDL implicitly commits on MySQL/MariaDB, so this migration cannot run
        // in a transaction.
        return false;
    }

    public function up(Schema $schema): void
    {
        // Version20230305232000 copied these rows into shared_data but kept the
        // table, so shares deleted through the API survived here, along with
        // their plain-text admin tokens. Instances created after that migration
        // never had the table, hence IF EXISTS.
        $this->addSql('DROP TABLE IF EXISTS sealed_shares');
    }

    public function down(Schema $schema): void
    {
        // The dropped rows cannot be recreated. Rolling back Version20230305232000
        // after this one deletes nothing from shared_data, since its preDown() finds
        // no sealed_shares table.
        $this->throwIrreversibleMigrationException('The legacy sealed_shares data was dropped; restore it from a backup.');
    }
}
