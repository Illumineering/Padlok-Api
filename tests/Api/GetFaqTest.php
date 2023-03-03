<?php

declare(strict_types=1);

namespace App\Tests\Api;

use App\Tests\Abstract\LocalizedApiTestCase;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Test;
use Symfony\Contracts\HttpClient\ResponseInterface;

final class GetFaqTest extends LocalizedApiTestCase
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
        $client = self::createClient();

        return $client->request('GET', 'faq', $this->getLocalizedHeader($language));
    }
}
