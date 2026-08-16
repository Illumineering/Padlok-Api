<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\SharedData;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;
use Symfony\Component\Clock\ClockInterface;

/**
 * @extends ServiceEntityRepository<SharedData>
 */
class SharedDataRepository extends ServiceEntityRepository
{
    public function __construct(
        ManagerRegistry $registry,
        private readonly ClockInterface $clock,
    ) {
        parent::__construct($registry, SharedData::class);
    }

    public function save(SharedData $entity, bool $flush = false): void
    {
        $entity->setUpdatedAt($this->clock->now());
        $this->getEntityManager()->persist($entity);

        if ($flush) {
            $this->getEntityManager()->flush();
        }
    }

    public function remove(SharedData $entity, bool $flush = false): void
    {
        $this->getEntityManager()->remove($entity);

        if ($flush) {
            $this->getEntityManager()->flush();
        }
    }

    /**
     * Deletes every entry whose expiration is due, and returns how many were removed.
     * Entries without an expiration are never removed.
     */
    public function deleteExpired(\DateTimeImmutable $now): int
    {
        $deleted = $this->getEntityManager()->createQueryBuilder()
            ->delete(SharedData::class, 'shared')
            ->where('shared.expiration IS NOT NULL')
            ->andWhere('shared.expiration <= :now')
            ->setParameter('now', $now)
            ->getQuery()
            ->execute();

        \assert(\is_int($deleted));

        return $deleted;
    }
}
