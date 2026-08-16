<?php

declare(strict_types=1);

namespace App\MessageHandler;

use App\Message\PurgeExpiredSharedData;
use App\Repository\SharedDataRepository;
use Psr\Log\LoggerInterface;
use Symfony\Component\Clock\ClockInterface;
use Symfony\Component\Messenger\Attribute\AsMessageHandler;

#[AsMessageHandler]
final class PurgeExpiredSharedDataHandler
{
    public function __construct(
        private readonly SharedDataRepository $repository,
        private readonly ClockInterface $clock,
        private readonly LoggerInterface $logger,
    ) {
    }

    public function __invoke(PurgeExpiredSharedData $message): void
    {
        $deleted = $this->repository->deleteExpired($this->clock->now());

        $this->logger->info('Purged {count} expired shared data entries.', ['count' => $deleted]);
    }
}
