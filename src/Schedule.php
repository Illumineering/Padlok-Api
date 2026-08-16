<?php

declare(strict_types=1);

namespace App;

use App\Message\PurgeExpiredSharedData;
use Symfony\Component\DependencyInjection\Attribute\Target;
use Symfony\Component\Scheduler\Attribute\AsSchedule;
use Symfony\Component\Scheduler\RecurringMessage;
use Symfony\Component\Scheduler\Schedule as SymfonySchedule;
use Symfony\Component\Scheduler\ScheduleProviderInterface;
use Symfony\Contracts\Cache\CacheInterface;

#[AsSchedule]
class Schedule implements ScheduleProviderInterface
{
    public function __construct(
        #[Target('app.persistent.cache')]
        private CacheInterface $cache,
    ) {
    }

    public function getSchedule(): SymfonySchedule
    {
        return (new SymfonySchedule())
            // Remember when the task last ran, so one whose due time passed while no worker
            // was up still fires when a worker comes back. The pool is backed by the
            // database, so the state outlives both deploys and cache clears.
            ->stateful($this->cache)
            ->processOnlyLastMissedRun(true) // ensure only last missed task is run

            ->add(RecurringMessage::every('1 day', new PurgeExpiredSharedData(), from: '03:00'))
        ;
    }
}
