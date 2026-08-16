<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

final class Version20260816014500 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Add a nullable expiration to shared_data, left null for existing entries';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('ALTER TABLE shared_data ADD expiration DATETIME DEFAULT NULL');
    }

    public function down(Schema $schema): void
    {
        $this->addSql('ALTER TABLE shared_data DROP expiration');
    }
}
