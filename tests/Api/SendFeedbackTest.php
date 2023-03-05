<?php

declare(strict_types=1);

namespace App\Tests\Api;

use ApiPlatform\Symfony\Bundle\Test\ApiTestCase;
use App\ApiPlatform\Dto\Feedback\Reason;
use Faker\Factory;
use Faker\Generator;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Test;
use Symfony\Component\HttpClient\HttpOptions;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Contracts\HttpClient\ResponseInterface;
use Zenstruck\Foundry\Test\Factories;

final class SendFeedbackTest extends ApiTestCase
{
    use Factories;

    /**
     * @param array<string, string> $feedback
     * @param array<string, string> $headers
     */
    #[Test]
    #[DataProvider('provideValidFeedback')]
    public function sendValidFeedback(array $feedback, array $headers): void
    {
        $this->sendFeedback($feedback, $headers);
        $this->assertResponseIsSuccessful();
        // TODO: assert mail have been sent
    }

    /**
     * @param array<string, string> $feedback
     */
    #[Test]
    #[DataProvider('provideInvalidFeedback')]
    public function sendInvalidFeedback(int $expectedResponseCode, array $feedback): void
    {
        $this->sendFeedback($feedback);
        $this->assertResponseStatusCodeSame($expectedResponseCode);
    }

    #[Test]
    public function testRedirectionToWebsite(): void
    {
        $response = $this->sendFeedback($this->generateFeedback(withEmail: true), redirect: 'https://padlok.app/feedback-sent/');
        $this->assertResponseStatusCodeSame(Response::HTTP_FOUND);
        $headers = $response->getHeaders(false);
        $this->assertArrayHasKey('location', $headers);
        $this->assertEquals('https://padlok.app/feedback-sent/', $headers['location'][0]);
    }

    #[Test]
    public function testInvalidRedirection(): void
    {
        $this->sendFeedback($this->generateFeedback(withEmail: true), redirect: 'https://www.apple.com');
        $this->assertResponseIsSuccessful();
    }

    public static function provideValidFeedback(): \Generator
    {
        yield [self::generateFeedback(withEmail: false), []];
        yield [self::generateFeedback(withEmail: false), self::generateHeaders()];
        yield [self::generateFeedback(withEmail: true), []];
        yield [self::generateFeedback(withEmail: true), self::generateHeaders()];
    }

    public static function provideInvalidFeedback(): \Generator
    {
        yield [Response::HTTP_UNPROCESSABLE_ENTITY, ['email' => 'invalid'] + self::generateFeedback(false)];
        yield [Response::HTTP_UNPROCESSABLE_ENTITY, ['message' => ''] + self::generateFeedback(false)];
    }

    private static function faker(): Generator
    {
        static $faker = null;
        if (!$faker) {
            $faker = Factory::create();
        }

        return $faker;
    }

    /**
     * @return array<string, string>
     */
    private static function generateFeedback(bool $withEmail): array
    {
        $faker = self::faker();
        $feedback = [
            'reason' => $faker->randomElement(Reason::cases())->value,
            'message' => $faker->paragraphs(asText: true),
        ];
        if ($withEmail) {
            $email = ['email' => $faker->email()];

            return $feedback + $email;
        }

        return $feedback;
    }

    /**
     * @return array<string, string>
     */
    private static function generateHeaders(): array
    {
        $faker = self::faker();

        return [
            'App-Version' => $faker->semver(),
            'Customer-Identifier' => $faker->uuid(),
            'Device' => $faker->word(),
            'Download-Date' => $faker->date(\DateTimeInterface::ATOM),
            'Accept-Language' => $faker->locale(),
            'OS-Name' => $faker->word(),
            'OS-Version' => $faker->semver(),
        ];
    }

    /**
     * @param array<string, string> $feedback
     * @param array<string, string> $headers
     */
    private function sendFeedback(array $feedback, array $headers = [], ?string $redirect = null, bool $json = true): ResponseInterface
    {
        $options = new HttpOptions();
        $options->setHeaders([
            'Accept' => 'application/json',
        ] + $headers);
        $options->setJson($feedback);

        if ($redirect) {
            $options->setQuery([
                'redirect' => $redirect,
            ]);
        }

        $client = self::createClient();

        return $client->request('POST', 'feedback', $options->toArray());
    }
}
