<?php

declare(strict_types=1);

namespace App\Tests\Api;

use ApiPlatform\Symfony\Bundle\Test\ApiTestCase;
use App\Health\DatabaseHealthCheck;
use Doctrine\DBAL\DriverManager;
use PHPUnit\Framework\Attributes\Test;
use Symfony\Component\HttpFoundation\Response;

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

    #[Test]
    public function reportsUnhealthyWhenDatabaseIsUnreachable(): void
    {
        $client = self::createClient();
        $unreachable = DriverManager::getConnection([
            'driver' => 'pdo_sqlite',
            'path' => '/nonexistent/directory/padlok.sqlite',
        ]);
        self::getContainer()->set(DatabaseHealthCheck::class, new DatabaseHealthCheck($unreachable));

        $client->request('GET', '/healthz');
        $this->assertResponseStatusCodeSame(Response::HTTP_SERVICE_UNAVAILABLE);
        $this->assertResponseHeaderSame('Cache-Control', 'no-store, private');
        $this->assertJsonEquals([
            'status' => 'fail',
            'checks' => ['database' => 'fail'],
        ]);
    }
}
