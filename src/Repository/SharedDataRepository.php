<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\SharedData;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;
use Symfony\Component\Clock\ClockInterface;

/**
 * @extends ServiceEntityRepository<SharedData>
 *
 * @method SharedData|null find($id, $lockMode = null, $lockVersion = null)
 * @method SharedData|null findOneBy(array $criteria, array $orderBy = null)
 * @method SharedData[]    findAll()
 * @method SharedData[]    findBy(array $criteria, array $orderBy = null, $limit = null, $offset = null)
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
}
