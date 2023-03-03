<?php

declare(strict_types=1);

namespace App\Tests\Abstract;

use ApiPlatform\Symfony\Bundle\Test\ApiTestCase;
use Symfony\Component\HttpClient\HttpOptions;

abstract class LocalizedApiTestCase extends ApiTestCase
{
    /**
     * @return array<string, string>
     */
    protected function getLocalizedHeader(string $language): array
    {
        $options = new HttpOptions();
        $options->setHeaders([
            'Accept' => 'application/json',
            'Accept-Language' => $language,
        ]);

        return $options->toArray();
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
