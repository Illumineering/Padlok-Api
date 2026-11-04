<?php

declare(strict_types=1);

namespace App\Tests\Api;

use ApiPlatform\Symfony\Bundle\Test\ApiTestCase;
use PHPUnit\Framework\Attributes\Depends;
use PHPUnit\Framework\Attributes\Test;
use Symfony\Component\HttpFoundation\Response;

/**
 * Same lifecycle as ShareTest, with the admin token sent as a Bearer token.
 */
final class ShareBearerTest extends ApiTestCase
{
    protected static ?bool $alwaysBootKernel = false;

    private const array INITIAL_DATA = ['iterations' => 1000, 'salt' => 'kLpHPb2zsjo=', 'sealed' => 'rphyE9rfNKrL'];
    private const array UPDATED_DATA = ['iterations' => 1510, 'salt' => 'Zm9vYmFyMTI=', 'sealed' => 'dXBkYXRlZA=='];

    private static ?string $identifier = null;
    private static ?string $adminToken = null;

    /**
     * @param array<string, mixed> $options
     */
    private function request(string $method, string $url, array $options = []): \Symfony\Contracts\HttpClient\ResponseInterface
    {
        $options['headers'] = ($options['headers'] ?? []) + ['Accept' => 'application/json'];

        return self::createClient()->request($method, $url, $options);
    }

    #[Test]
    public function createShareData(): void
    {
        $data = $this->request('POST', '/share', ['json' => self::INITIAL_DATA])->toArray();
        $this->assertResponseIsSuccessful();
        self::$identifier = $data['identifier'];
        self::$adminToken = $data['admin_token'];
    }

    #[Test]
    #[Depends('createShareData')]
    public function updateWithoutToken(): void
    {
        $this->request('PUT', '/shared/'.self::$identifier, ['json' => self::UPDATED_DATA]);
        $this->assertResponseStatusCodeSame(Response::HTTP_UNAUTHORIZED);
        $this->assertResponseHeaderSame('WWW-Authenticate', 'Bearer');
    }

    #[Test]
    #[Depends('createShareData')]
    public function updateWithMalformedAuthorization(): void
    {
        $this->request('PUT', '/shared/'.self::$identifier, [
            'json' => self::UPDATED_DATA,
            'headers' => ['Authorization' => 'Basic '.self::$adminToken],
        ]);
        $this->assertResponseStatusCodeSame(Response::HTTP_UNAUTHORIZED);
    }

    #[Test]
    #[Depends('createShareData')]
    public function updateWithWrongToken(): void
    {
        $this->request('PUT', '/shared/'.self::$identifier, [
            'json' => self::UPDATED_DATA,
            'auth_bearer' => '1234',
        ]);
        $this->assertResponseStatusCodeSame(Response::HTTP_FORBIDDEN);
    }

    #[Test]
    #[Depends('updateWithoutToken')]
    #[Depends('updateWithMalformedAuthorization')]
    #[Depends('updateWithWrongToken')]
    public function update(): void
    {
        $this->request('PUT', '/shared/'.self::$identifier, [
            'json' => self::UPDATED_DATA,
            'auth_bearer' => (string) self::$adminToken,
        ]);
        $this->assertResponseIsSuccessful();

        $response = $this->request('GET', '/shared/'.self::$identifier);
        $this->assertEquals(self::UPDATED_DATA, $response->toArray());
    }

    #[Test]
    #[Depends('update')]
    public function deleteWithoutToken(): void
    {
        $this->request('DELETE', '/shared/'.self::$identifier);
        $this->assertResponseStatusCodeSame(Response::HTTP_UNAUTHORIZED);
    }

    #[Test]
    #[Depends('deleteWithoutToken')]
    public function deleteWithWrongToken(): void
    {
        $this->request('DELETE', '/shared/'.self::$identifier, ['auth_bearer' => '1234']);
        $this->assertResponseStatusCodeSame(Response::HTTP_FORBIDDEN);
    }

    #[Test]
    #[Depends('deleteWithWrongToken')]
    public function delete(): void
    {
        $this->request('DELETE', '/shared/'.self::$identifier, ['auth_bearer' => (string) self::$adminToken]);
        $this->assertResponseStatusCodeSame(Response::HTTP_NO_CONTENT);

        $this->request('GET', '/shared/'.self::$identifier);
        $this->assertResponseStatusCodeSame(Response::HTTP_NOT_FOUND);
    }
}
