<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Exception\TableNotFoundException;
use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;
use Tuupola\Base62;

final class Version20230305232000 extends AbstractMigration
{
    /**
     * @var array<array<string, mixed>>
     */
    private array $legacyData;

    /**
     * @var list<string>
     */
    private array $migratedIdentifiers;

    public function getDescription(): string
    {
        return 'Migrate legacy sealed_shares table content in shared_data table';
    }

    public function preUp(Schema $schema): void
    {
        try {
            $this->legacyData = $this->connection
                ->executeQuery('SELECT * FROM sealed_shares')
                ->fetchAllAssociative();
        } catch (TableNotFoundException $e) {
            // Legacy sealed_shares table might not exist when booting a new instance
            $this->legacyData = [];
        }
    }

    public function up(Schema $schema): void
    {
        $base62 = new Base62();
        foreach ($this->legacyData as $legacyRow) {
            $this->addSql('INSERT INTO shared_data(identifier, info, admin_token, created_at, updated_at) VALUES (:identifier, :info, :token, :created, :updated)', [
                'identifier' => $base62->encode($legacyRow['id']),
                'info' => $legacyRow['infos'],
                'token' => $legacyRow['admin_token'],
                'created' => substr($legacyRow['created_at'], 0, 19),
                'updated' => substr($legacyRow['updated_at'], 0, 19),
            ]);
        }
    }

    public function preDown(Schema $schema): void
    {
        // Only remove the rows this migration copied from sealed_shares, so that
        // shares created since then are kept.
        try {
            $legacyIds = $this->connection->fetchFirstColumn('SELECT id FROM sealed_shares');
        } catch (TableNotFoundException $e) {
            // Without the legacy table, up() had nothing to migrate
            $legacyIds = [];
        }

        $base62 = new Base62();
        $this->migratedIdentifiers = array_map(
            static fn (mixed $id): string => $base62->encode((string) $id),
            $legacyIds,
        );
    }

    public function down(Schema $schema): void
    {
        foreach ($this->migratedIdentifiers as $identifier) {
            $this->addSql('DELETE FROM shared_data WHERE identifier = :identifier', [
                'identifier' => $identifier,
            ]);
        }
    }
}
