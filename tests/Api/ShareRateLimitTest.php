<?php

declare(strict_types=1);

namespace App\Tests\Api;

use ApiPlatform\Symfony\Bundle\Test\ApiTestCase;
use ApiPlatform\Symfony\Bundle\Test\Client;
use PHPUnit\Framework\Attributes\Test;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Contracts\HttpClient\ResponseInterface;

final class ShareRateLimitTest extends ApiTestCase
{
    protected static ?bool $alwaysBootKernel = false;

    private const int LIMIT = 20;
    private const int ADMIN_TOKEN_FAILURES = 10;
    private const array DATA = ['iterations' => 1000, 'salt' => 'kLpHPb2zsjo=', 'sealed' => 'rphyE9rfNKrL'];

    /**
     * @param array<string, mixed> $json
     */
    private function create(Client $client, string $ip, array $json): ResponseInterface
    {
        return $client->request('POST', '/share', [
            'json' => $json,
            'headers' => ['Accept' => 'application/json', 'REMOTE_ADDR' => $ip],
        ]);
    }

    #[Test]
    public function shareCreationIsLimitedPerClientIp(): void
    {
        $client = self::createClient();
        // The test limiter lives in memory: keep the same kernel for every request.
        $client->disableReboot();

        // Attempts count before the body is read, so even invalid ones use the budget.
        for ($i = 0; $i < self::LIMIT; ++$i) {
            $this->assertNotSame(Response::HTTP_TOO_MANY_REQUESTS, $this->create($client, '203.0.113.7', [])->getStatusCode());
        }

        $limited = $this->create($client, '203.0.113.7', self::DATA);
        $this->assertSame(Response::HTTP_TOO_MANY_REQUESTS, $limited->getStatusCode());
        $this->assertGreaterThan(0, (int) ($limited->getHeaders(false)['retry-after'][0] ?? 0));

        // Another client is unaffected.
        $this->assertSame(Response::HTTP_CREATED, $this->create($client, '203.0.113.8', self::DATA)->getStatusCode());

        // Reads aren't limited, even for the limited client.
        $client->request('GET', '/healthz', ['headers' => ['REMOTE_ADDR' => '203.0.113.7']]);
        $this->assertResponseIsSuccessful();
    }

    #[Test]
    public function wrongAdminTokensAreLimitedPerClientIp(): void
    {
        $client = self::createClient();
        $client->disableReboot();
        $created = $this->create($client, '203.0.113.20', self::DATA)->toArray();
        $url = '/shared/'.$created['identifier'];
        $as = static fn (string $ip, string $token): array => [
            'json' => self::DATA,
            'headers' => ['Accept' => 'application/json', 'REMOTE_ADDR' => $ip],
            'auth_bearer' => $token,
        ];

        // Successful updates don't count.
        for ($i = 0; $i < self::ADMIN_TOKEN_FAILURES + 5; ++$i) {
            $client->request('PUT', $url, $as('203.0.113.20', $created['admin_token']));
            $this->assertResponseStatusCodeSame(Response::HTTP_NO_CONTENT);
        }

        // Wrong tokens do, on PUT as on DELETE, until the limit is reached...
        for ($i = 0; $i < self::ADMIN_TOKEN_FAILURES; ++$i) {
            $client->request(0 === $i % 2 ? 'PUT' : 'DELETE', $url, $as('203.0.113.21', 'guess'.$i));
            $this->assertResponseStatusCodeSame(Response::HTTP_FORBIDDEN);
        }

        // ...then that IP is refused even with the right token, so a lucky guess can't be told apart.
        $client->request('PUT', $url, $as('203.0.113.21', $created['admin_token']));
        $this->assertResponseStatusCodeSame(Response::HTTP_TOO_MANY_REQUESTS);
        $this->assertResponseHasHeader('Retry-After');
        $client->request('DELETE', $url, $as('203.0.113.21', 'guess'));
        $this->assertResponseStatusCodeSame(Response::HTTP_TOO_MANY_REQUESTS);

        // The owner, from another IP, is not locked out.
        $client->request('PUT', $url, $as('203.0.113.20', $created['admin_token']));
        $this->assertResponseStatusCodeSame(Response::HTTP_NO_CONTENT);
    }
}
