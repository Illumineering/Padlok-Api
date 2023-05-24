<?php

declare(strict_types=1);

namespace App\Tests\Api;

use App\Tests\Abstract\LocalizedApiTestCase;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Test;
use Symfony\Contracts\HttpClient\ResponseInterface;

final class GetOptionsTest extends LocalizedApiTestCase
{
    /**
     * @var array<string, mixed>
     */
    private readonly array $jsonSchema;

    public function __construct(string $name)
    {
        parent::__construct($name);
        $this->jsonSchema = [
            'type' => 'object',
            'properties' => [
                'api_version' => ['type' => 'string'],
                'traces_sample_rate' => [
                    'type' => 'number',
                    'minimum' => 0,
                    'maximum' => 1,
                ],
                'events_sample_rate' => [
                    'type' => 'number',
                    'minimum' => 0,
                    'maximum' => 1,
                ],
                'profiles_sample_rate' => [
                    'type' => 'number',
                    'minimum' => 0,
                    'maximum' => 1,
                ],
                'faq' => [
                    'type' => 'array',
                    'items' => [
                        'type' => 'object',
                        'properties' => [
                            'category' => [
                                'type' => 'object',
                                'properties' => [
                                    'name' => ['type' => 'string'],
                                    'icon' => ['type' => 'string'],
                                ],
                                'required' => ['name', 'icon'],
                                'additionalProperties' => false,
                            ],
                            'question' => ['type' => 'string'],
                            'answer' => ['type' => 'string'],
                        ],
                        'required' => ['category', 'question', 'answer'],
                        'additionalProperties' => false,
                    ],
                ],
                'urls' => [
                    'type' => 'object',
                    'properties' => [
                        'appstore' => ['type' => 'string'],
                        'instagram' => ['type' => 'string'],
                        'marketing' => ['type' => 'string'],
                        'mastodon' => ['type' => 'string'],
                        'privacy' => ['type' => 'string'],
                        'support' => ['type' => 'string'],
                        'terms' => ['type' => 'string'],
                    ],
                    'required' => ['appstore', 'instagram', 'marketing', 'mastodon', 'privacy', 'support', 'terms'],
                    'additionalProperties' => false,
                ],
            ],
            'required' => ['api_version', 'faq', 'urls', 'traces_sample_rate', 'events_sample_rate', 'profiles_sample_rate'],
            'additionalProperties' => false,
        ];
    }

    #[Test]
    #[DataProvider('getEnglishAcceptLanguage')]
    public function getOptionsInEnglish(string $language): void
    {
        $response = $this->getOptions($language);
        $this->assertResponseIsSuccessful();
        $this->assertMatchesJsonSchema($this->jsonSchema);
        $data = $response->toArray();
        $this->assertNonLocalizedData($data);
        $this->assertEquals('https://padlok.app/privacy', $data['urls']['privacy']);
        $this->assertEquals('https://padlok.app/support', $data['urls']['support']);
        $this->assertEquals('https://padlok.app/terms', $data['urls']['terms']);
        $this->assertEquals('Getting started', $data['faq'][0]['category']['name']);
    }

    #[Test]
    #[DataProvider('getFrenchAcceptLanguage')]
    public function getOptionsInFrench(string $language): void
    {
        $response = $this->getOptions($language);
        $this->assertResponseIsSuccessful();
        $this->assertMatchesJsonSchema($this->jsonSchema);
        $data = $response->toArray();
        $this->assertNonLocalizedData($data);
        $this->assertEquals('https://padlok.app/fr/confidentialite', $data['urls']['privacy']);
        $this->assertEquals('https://padlok.app/fr/assistance', $data['urls']['support']);
        $this->assertEquals('https://padlok.app/fr/conditions', $data['urls']['terms']);
        $this->assertEquals('Commencer', $data['faq'][0]['category']['name']);
    }

    /**
     * @param array<string, mixed> $data
     */
    private function assertNonLocalizedData(array $data): void
    {
        $this->assertEquals(1, $data['traces_sample_rate']);
        $this->assertEquals(1, $data['events_sample_rate']);
        $this->assertEquals(1, $data['profiles_sample_rate']);
    }

    private function getOptions(string $language): ResponseInterface
    {
        $client = self::createClient();

        return $client->request('GET', 'options', $this->getLocalizedHeader($language));
    }
}
