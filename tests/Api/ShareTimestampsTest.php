<?php

declare(strict_types=1);

namespace App\Tests\Api;

use ApiPlatform\Symfony\Bundle\Test\ApiTestCase;
use App\Repository\SharedDataRepository;
use PHPUnit\Framework\Attributes\Test;
use Symfony\Component\Clock\ClockInterface;
use Symfony\Component\Clock\MockClock;

final class ShareTimestampsTest extends ApiTestCase
{
    protected static ?bool $alwaysBootKernel = false;

    private const array DATA = ['iterations' => 1000, 'salt' => 'kLpHPb2zsjo=', 'sealed' => 'rphyE9rfNKrL'];

    #[Test]
    public function timestampsComeFromTheInjectedClock(): void
    {
        $client = self::createClient();
        $clock = new MockClock('2026-01-01 10:00:00');
        self::getContainer()->set(ClockInterface::class, $clock);

        $identifier = $client->request('POST', '/share', [
            'json' => self::DATA,
            'headers' => ['Accept' => 'application/json'],
        ])->toArray()['identifier'];
        $this->assertResponseIsSuccessful();

        $repository = self::getContainer()->get(SharedDataRepository::class);
        $shared = $repository->findOneBy(['identifier' => $identifier]);
        $this->assertNotNull($shared);
        $this->assertEquals($clock->now(), $shared->getCreatedAt());
        $this->assertEquals($clock->now(), $shared->getUpdatedAt());
    }
}
