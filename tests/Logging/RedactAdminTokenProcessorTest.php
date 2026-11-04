<?php

declare(strict_types=1);

namespace App\Tests\Logging;

use App\Logging\RedactAdminTokenProcessor;
use Monolog\Handler\TestHandler;
use Monolog\Level;
use Monolog\LogRecord;
use PHPUnit\Framework\Attributes\Test;
use Psr\Log\LoggerInterface;
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;

final class RedactAdminTokenProcessorTest extends KernelTestCase
{
    private const string TOKEN = '2UmsT79u3mUVBpygw3h4cS';

    #[Test]
    public function redactsMessageContextAndExtra(): void
    {
        $record = new LogRecord(
            datetime: new \DateTimeImmutable(),
            channel: 'request',
            level: Level::Info,
            message: 'No route found for "PATCH http://localhost/shared/abc/'.self::TOKEN.'"',
            context: [
                'request_uri' => 'http://localhost/shared/abc/'.self::TOKEN.'?x=1',
                'route_parameters' => ['identifier' => 'abc', 'admin_token' => self::TOKEN],
                'headers' => ['Authorization' => 'Bearer '.self::TOKEN],
                'note' => 'auth was bearer '.self::TOKEN,
            ],
            extra: ['url' => '/shared/abc/'.self::TOKEN],
        );

        $redacted = (new RedactAdminTokenProcessor())($record);

        $this->assertStringNotContainsString(self::TOKEN, serialize($redacted->toArray()));
        $this->assertSame('No route found for "PATCH http://localhost/shared/abc/[redacted]"', $redacted->message);
        $this->assertSame('http://localhost/shared/abc/[redacted]?x=1', $redacted->context['request_uri']);
        $this->assertSame(['identifier' => 'abc', 'admin_token' => '[redacted]'], $redacted->context['route_parameters']);
        $this->assertSame('/shared/abc/[redacted]', $redacted->extra['url']);
    }

    #[Test]
    public function leavesOtherUrlsUntouched(): void
    {
        $record = new LogRecord(
            datetime: new \DateTimeImmutable(),
            channel: 'request',
            level: Level::Info,
            message: 'GET /shared/abc',
            extra: ['url' => '/shared/abc', 'other' => '/share'],
        );

        $redacted = (new RedactAdminTokenProcessor())($record);

        $this->assertSame('GET /shared/abc', $redacted->message);
        $this->assertSame(['url' => '/shared/abc', 'other' => '/share'], $redacted->extra);
    }

    #[Test]
    public function runsAfterWebProcessorInTheContainer(): void
    {
        $logger = self::getContainer()->get(LoggerInterface::class);

        $handler = new TestHandler();
        $logger->pushHandler($handler);

        $previous = $_SERVER['REQUEST_URI'] ?? null;
        $_SERVER['REQUEST_URI'] = '/shared/abc/'.self::TOKEN;
        try {
            $logger->error('boom');
        } finally {
            if (null === $previous) {
                unset($_SERVER['REQUEST_URI']);
            } else {
                $_SERVER['REQUEST_URI'] = $previous;
            }
        }

        $records = $handler->getRecords();
        $this->assertCount(1, $records);
        $this->assertSame('/shared/abc/[redacted]', $records[0]->extra['url']);
    }
}
