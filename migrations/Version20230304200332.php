<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

final class Version20230304200332 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Create shared_data table';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('CREATE TABLE shared_data (id INT AUTO_INCREMENT NOT NULL, identifier CHAR(36) NOT NULL COMMENT \'(DC2Type:guid)\', info LONGTEXT NOT NULL COMMENT \'(DC2Type:json)\', admin_token VARCHAR(255) NOT NULL, created_at DATETIME NOT NULL COMMENT \'(DC2Type:datetime_immutable)\', updated_at DATETIME NOT NULL COMMENT \'(DC2Type:datetime_immutable)\', PRIMARY KEY(id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci` ENGINE = InnoDB');
        $this->addSql('CREATE UNIQUE INDEX UNIQ_170598FBD17F50A6 ON shared_data (identifier)');
    }

    public function down(Schema $schema): void
    {
        $this->addSql('DROP INDEX UNIQ_170598FBD17F50A6 ON shared_data');
        $this->addSql('DROP TABLE shared_data');
    }
}
