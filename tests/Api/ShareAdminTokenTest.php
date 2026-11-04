<?php

declare(strict_types=1);

namespace App\Tests\Api;

use ApiPlatform\Symfony\Bundle\Test\ApiTestCase;
use Doctrine\DBAL\Connection;
use PHPUnit\Framework\Attributes\Test;
use Symfony\Component\HttpFoundation\Response;

final class ShareAdminTokenTest extends ApiTestCase
{
    protected static ?bool $alwaysBootKernel = false;

    private const array DATA = ['iterations' => 1000, 'salt' => 'kLpHPb2zsjo=', 'sealed' => 'rphyE9rfNKrL'];

    #[Test]
    public function onlyAHashOfTheAdminTokenIsStored(): void
    {
        $client = self::createClient();
        $created = $client->request('POST', '/share', [
            'json' => self::DATA,
            'headers' => ['Accept' => 'application/json'],
        ])->toArray();
        $this->assertResponseIsSuccessful();

        $row = self::getContainer()->get(Connection::class)->fetchAssociative(
            'SELECT * FROM shared_data WHERE identifier = ?',
            [$created['identifier']],
        );
        $this->assertIsArray($row);
        $this->assertArrayNotHasKey('admin_token', $row);
        $this->assertSame(hash('sha256', $created['admin_token']), $row['admin_token_hash']);
        $this->assertStringNotContainsString($created['admin_token'], serialize($row));
    }

    /**
     * PUT answers 204 without a body: the client already holds the identifier and
     * the admin token, and the server only keeps the token's hash.
     */
    #[Test]
    public function updateAnswersNoContent(): void
    {
        $client = self::createClient();
        $created = $client->request('POST', '/share', [
            'json' => self::DATA,
            'headers' => ['Accept' => 'application/json'],
        ])->toArray();

        $updates = [
            'bearer' => ['/shared/'.$created['identifier'], ['auth_bearer' => $created['admin_token']]],
            'legacy path' => ['/shared/'.$created['identifier'].'/'.$created['admin_token'], []],
        ];
        foreach ($updates as $name => [$url, $options]) {
            $updated = ['sealed' => 'updated via '.$name] + self::DATA;
            $response = $client->request('PUT', $url, $options + [
                'json' => $updated,
                'headers' => ['Accept' => 'application/json'],
            ]);
            $this->assertResponseStatusCodeSame(Response::HTTP_NO_CONTENT, $name);
            $this->assertSame('', $response->getContent(), $name);

            $stored = $client->request('GET', '/shared/'.$created['identifier'], [
                'headers' => ['Accept' => 'application/json'],
            ])->toArray();
            $this->assertEquals($updated, $stored, $name);
        }
    }
}
