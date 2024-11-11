<?php

declare(strict_types=1);

namespace App\Tests\Api;

use ApiPlatform\Symfony\Bundle\Test\ApiTestCase;
use PHPUnit\Framework\Attributes\Depends;
use PHPUnit\Framework\Attributes\Test;
use Symfony\Component\HttpClient\HttpOptions;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Uid\Uuid;
use Tuupola\Base62;

final class ShareTest extends ApiTestCase
{
    /**
     * @var array<string, mixed>
     */
    private array $createSchema;

    /**
     * @var array<string, int|string>
     */
    private array $initialData;

    /**
     * @var array<string, int|string>
     */
    private array $updatedData;

    private static ?string $identifier = null;
    private static ?string $adminToken = null;

    protected function setUp(): void
    {
        if (!isset($this->createSchema)) {
            $this->createSchema = [
                'type' => 'object',
                'properties' => [
                    'identifier' => ['type' => 'string'],
                    'admin_token' => ['type' => 'string'],
                ],
                'required' => ['identifier', 'admin_token'],
                'additionalProperties' => false,
            ];
        }
        if (!isset($this->initialData)) {
            $this->initialData = [
                'iterations' => 1000,
                'salt' => 'kLpHPb2zsjo=',
                'sealed' => 'rphyE9rfNKrLwupKCR7bSTTOxlm++joQFqiR8UOYfXKFw2D9oQ/bo1gtFFYwre7El4AUWyA64MatY6KVAhJu9EBErzMyIRM4ezZU76rovsbM27W20FEBRqIlE1msM92MirPTb6/koZhSp2vr1jH62fayfVwt2uckC5iRMLolxrFCylKxToi+qyXzr6KPETJR1Rzf9W5P1JmAC209nkoA6LduKKPYhiYguecmWawYdfJEmtmlnfMPZMTTGWrAgJ4yW/hxqeMqgSaFi5495FficfqlBx6eieH20NtW58BFt0uX4tGKLyHtJU/XVMeayOcV4cBHK87MToZNevRTtjf2zq8Pdk3YxerNOzPBDzeX17NJvq0s6mAGg5brQouwT/1GxYbWkDhUjb/ztJVm706ruGsUtqtk5ohtYW88J2lk/95qW0/GLhlzwaBEXEYXoUBmEp6nDuvDa86KG9JWmYwCaXnGezsEc64Qh1ZfsCtfDL+Xp2W4jqdKMPtgFwnC3jO+10uqr+iOuUktkU0dTC7UHKs1OPala4vY8Y0ZS54z062rrRbgp+gj5EBQh0yejZPfVoxU8ySfQoj6fmB7CFpuVP/dSutCTbIi0F8z8SjAwJgBSFreYyoHQPS7+7628TPcGUa57OGrXAWTa5Xz8+TiYyYek+jxkriaadHIeMj94QiqpbSMFHQ+dCuS1+zLsR3r',
            ];
        }
        if (!isset($this->updatedData)) {
            $this->updatedData = [
                'iterations' => 1510,
                'salt' => '__kLpHPb2zsjo=',
                'sealed' => '__rphyE9rfNKrLwupKCR7bSTTOxlm++joQFqiR8UOYfXKFw2D9oQ/bo1gtFFYwre7El4AUWyA64MatY6KVAhJu9EBErzMyIRM4ezZU76rovsbM27W20FEBRqIlE1msM92MirPTb6/koZhSp2vr1jH62fayfVwt2uckC5iRMLolxrFCylKxToi+qyXzr6KPETJR1Rzf9W5P1JmAC209nkoA6LduKKPYhiYguecmWawYdfJEmtmlnfMPZMTTGWrAgJ4yW/hxqeMqgSaFi5495FficfqlBx6eieH20NtW58BFt0uX4tGKLyHtJU/XVMeayOcV4cBHK87MToZNevRTtjf2zq8Pdk3YxerNOzPBDzeX17NJvq0s6mAGg5brQouwT/1GxYbWkDhUjb/ztJVm706ruGsUtqtk5ohtYW88J2lk/95qW0/GLhlzwaBEXEYXoUBmEp6nDuvDa86KG9JWmYwCaXnGezsEc64Qh1ZfsCtfDL+Xp2W4jqdKMPtgFwnC3jO+10uqr+iOuUktkU0dTC7UHKs1OPala4vY8Y0ZS54z062rrRbgp+gj5EBQh0yejZPfVoxU8ySfQoj6fmB7CFpuVP/dSutCTbIi0F8z8SjAwJgBSFreYyoHQPS7+7628TPcGUa57OGrXAWTa5Xz8+TiYyYek+jxkriaadHIeMj94QiqpbSMFHQ+dCuS1+zLsR3r',
            ];
        }
    }

    #[Test]
    public function createShareData(): void
    {
        $options = new HttpOptions();
        $options->setHeaders(['Accept' => 'application/json']);
        $options->setJson($this->initialData);

        $client = self::createClient();
        $response = $client->request('POST', 'share', $options->toArray());
        $this->assertResponseIsSuccessful();
        $this->assertMatchesJsonSchema($this->createSchema);
        $data = $response->toArray();
        self::$identifier = $data['identifier'];
        self::$adminToken = $data['admin_token'];

        $base62 = new Base62();
        try {
            Uuid::fromBinary($base62->decode(self::$identifier));
        } catch (\InvalidArgumentException $e) {
            $this->fail($e->getMessage());
        }
    }

    #[Test]
    #[Depends('createShareData')]
    public function getSharedData(): void
    {
        $options = new HttpOptions();
        $options->setHeaders(['Accept' => 'application/json']);

        $client = self::createClient();
        $response = $client->request('GET', 'shared/'.self::$identifier, $options->toArray());
        $this->assertResponseIsSuccessful();
        $this->assertEquals($this->initialData, $response->toArray());
    }

    #[Test]
    #[Depends('getSharedData')]
    public function updateSharedDataWrongToken(): void
    {
        $options = new HttpOptions();
        $options->setHeaders(['Accept' => 'application/json']);
        $options->setJson($this->updatedData);

        $client = self::createClient();
        $client->request('PUT', 'shared/'.self::$identifier.'/1234', $options->toArray());
        $this->assertResponseStatusCodeSame(Response::HTTP_FORBIDDEN);
    }

    #[Test]
    #[Depends('updateSharedDataWrongToken')]
    public function updateSharedData(): void
    {
        $options = new HttpOptions();
        $options->setHeaders(['Accept' => 'application/json']);
        $options->setJson($this->updatedData);

        $client = self::createClient();
        $client->request('PUT', 'shared/'.self::$identifier.'/'.self::$adminToken, $options->toArray());
        $this->assertResponseIsSuccessful();
    }

    #[Test]
    #[Depends('updateSharedData')]
    public function getUpdatedData(): void
    {
        $options = new HttpOptions();
        $options->setHeaders(['Accept' => 'application/json']);

        $client = self::createClient();
        $response = $client->request('GET', 'shared/'.self::$identifier, $options->toArray());
        $this->assertResponseIsSuccessful();
        $this->assertEquals($this->updatedData, $response->toArray());
    }

    #[Test]
    #[Depends('getUpdatedData')]
    public function deleteSharedDataWrongToken(): void
    {
        $options = new HttpOptions();
        $options->setHeaders(['Accept' => 'application/json']);

        $client = self::createClient();
        $client->request('DELETE', 'shared/'.self::$identifier.'/1234', $options->toArray());
        $this->assertResponseStatusCodeSame(Response::HTTP_FORBIDDEN);
    }

    #[Test]
    #[Depends('deleteSharedDataWrongToken')]
    public function deleteSharedData(): void
    {
        $options = new HttpOptions();
        $options->setHeaders(['Accept' => 'application/json']);

        $client = self::createClient();
        $client->request('DELETE', 'shared/'.self::$identifier.'/'.self::$adminToken, $options->toArray());
        $this->assertResponseIsSuccessful();
    }

    #[Test]
    #[Depends('deleteSharedData')]
    public function getDeletedData(): void
    {
        $options = new HttpOptions();
        $options->setHeaders(['Accept' => 'application/json']);

        $client = self::createClient();
        $client->request('GET', 'shared/'.self::$identifier, $options->toArray());
        $this->assertResponseStatusCodeSame(Response::HTTP_NOT_FOUND);
    }

    #[Test]
    #[Depends('deleteSharedData')]
    public function updateDeletedData(): void
    {
        $options = new HttpOptions();
        $options->setHeaders(['Accept' => 'application/json']);
        $options->setJson($this->updatedData);

        $client = self::createClient();
        $client->request('PUT', 'shared/'.self::$identifier.'/'.self::$adminToken, $options->toArray());
        $this->assertResponseStatusCodeSame(Response::HTTP_NOT_FOUND);
    }
}
