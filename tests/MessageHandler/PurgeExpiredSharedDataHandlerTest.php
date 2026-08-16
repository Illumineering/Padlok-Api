<?php

declare(strict_types=1);

namespace App\Tests\MessageHandler;

use App\Entity\SharedData;
use App\Message\PurgeExpiredSharedData;
use App\MessageHandler\PurgeExpiredSharedDataHandler;
use App\Repository\SharedDataRepository;
use Doctrine\ORM\EntityManagerInterface;
use PHPUnit\Framework\Attributes\Test;
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;
use Symfony\Component\Uid\Uuid;
use Tuupola\Base62;

final class PurgeExpiredSharedDataHandlerTest extends KernelTestCase
{
    private EntityManagerInterface $manager;
    private SharedDataRepository $repository;
    private PurgeExpiredSharedDataHandler $handler;

    /**
     * @var list<string>
     */
    private array $identifiers = [];

    protected function setUp(): void
    {
        self::bootKernel();
        $container = self::getContainer();

        $this->manager = $container->get(EntityManagerInterface::class);
        $this->repository = $container->get(SharedDataRepository::class);
        $this->handler = $container->get(PurgeExpiredSharedDataHandler::class);
    }

    protected function tearDown(): void
    {
        // Bulk deletes bypass the identity map, so drop it before looking entries up again.
        $this->manager->clear();

        foreach ($this->identifiers as $identifier) {
            if ($entry = $this->repository->findOneBy(['identifier' => $identifier])) {
                $this->repository->remove($entry, true);
            }
        }

        parent::tearDown();
    }

    #[Test]
    public function itOnlyDeletesEntriesPastTheirExpiration(): void
    {
        $expired = $this->createEntry(new \DateTimeImmutable('-1 day'));
        $living = $this->createEntry(new \DateTimeImmutable('+1 day'));
        $eternal = $this->createEntry(null);

        ($this->handler)(new PurgeExpiredSharedData());
        $this->manager->clear();

        $this->assertNull(
            $this->repository->findOneBy(['identifier' => $expired]),
            'An entry past its expiration must be purged.',
        );
        $this->assertNotNull(
            $this->repository->findOneBy(['identifier' => $living]),
            'An entry that has not expired yet must be kept.',
        );
        $this->assertNotNull(
            $this->repository->findOneBy(['identifier' => $eternal]),
            'An entry without an expiration must never be purged.',
        );
    }

    #[Test]
    public function itReportsHowManyEntriesWereDeleted(): void
    {
        $this->createEntry(new \DateTimeImmutable('-1 day'));
        $this->createEntry(new \DateTimeImmutable('-1 hour'));
        $this->createEntry(null);

        $this->assertSame(2, $this->repository->deleteExpired(new \DateTimeImmutable()));
    }

    private function createEntry(?\DateTimeImmutable $expiration): string
    {
        $base62 = new Base62();

        $entry = new SharedData();
        $entry->setIdentifier($base62->encode(Uuid::v4()->toBinary()));
        $entry->setAdminToken($base62->encode(Uuid::v4()->toBinary()));
        $entry->setInfo(['iterations' => 1000, 'salt' => 'salt', 'sealed' => 'sealed']);
        $entry->setExpiration($expiration);

        $this->repository->save($entry, true);
        $this->identifiers[] = $entry->getIdentifier();

        return $entry->getIdentifier();
    }
}
