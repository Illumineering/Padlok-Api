<?php

declare(strict_types=1);

namespace App\Tests\Api;

use ApiPlatform\Symfony\Bundle\Test\ApiTestCase;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Test;
use Symfony\Component\HttpClient\HttpOptions;
use Symfony\Contracts\HttpClient\ResponseInterface;

class GetFaqTest extends ApiTestCase
{
    /**
     * @var array<string, mixed>
     */
    private readonly array $jsonSchema;

    public function __construct(string $name)
    {
        parent::__construct($name);
        $this->jsonSchema = [
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
        ];
    }

    #[Test]
    #[DataProvider('getEnglishAcceptLanguage')]
    public function getFaqInEnglish(string $language): void
    {
        $response = $this->getFaq($language);
        $this->assertResponseIsSuccessful();
        $this->assertMatchesJsonSchema($this->jsonSchema);
        $this->assertEquals('Getting started', $response->toArray()[0]['category']['name']);
    }

    #[Test]
    #[DataProvider('getFrenchAcceptLanguage')]
    public function getFaqInFrench(string $language): void
    {
        $response = $this->getFaq($language);
        $this->assertResponseIsSuccessful();
        $this->assertMatchesJsonSchema($this->jsonSchema);
        $this->assertEquals('Commencer', $response->toArray()[0]['category']['name']);
    }

    private function getFaq(string $language): ResponseInterface
    {
        $options = new HttpOptions();
        $options->setHeaders(['Accept-Language' => $language]);

        $client = self::createClient();

        return $client->request('GET', 'faq', $options->toArray());
    }

    public static function getEnglishAcceptLanguage(): \Generator
    {
        yield ['en'];
        yield ['en-US'];
        yield ['en-GB'];
        yield ['de']; // Fallback to english
    }

    public static function getFrenchAcceptLanguage(): \Generator
    {
        yield ['fr'];
        yield ['fr-FR'];
        yield ['fr-CA'];
    }
}
