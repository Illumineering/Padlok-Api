<?php

declare(strict_types=1);

namespace App\Tests\Api;

use ApiPlatform\Symfony\Bundle\Test\ApiTestCase;
use PHPUnit\Framework\Attributes\Test;

final class HealthzTest extends ApiTestCase
{
    protected static ?bool $alwaysBootKernel = false;

    #[Test]
    public function reportsHealthy(): void
    {
        self::createClient()->request('GET', '/healthz');
        $this->assertResponseIsSuccessful();
        $this->assertResponseHeaderSame('Cache-Control', 'no-store, private');
        $this->assertJsonEquals([
            'status' => 'ok',
            'checks' => ['database' => 'ok'],
        ]);
    }
}
