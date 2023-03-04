<?php

declare(strict_types=1);

namespace App\ApiPlatform\Dto;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\GetCollection;
use App\ApiPlatform\Dto\Faq\Faq;
use App\ApiPlatform\State\OptionsProvider;
use Symfony\Component\Serializer\Annotation\SerializedName;

#[ApiResource(
    operations: [
        new GetCollection(
            openapiContext: [
                'tags' => ['Metadata'],
                'summary' => 'Get app parameters, including Faq, Links and Sentry rates',
                'description' => '',
            ],
            paginationEnabled: false,
            provider: OptionsProvider::class,
        ),
    ],
)]
final class Options
{
    public function __construct(
        // API version
        public readonly string $apiVersion,
        // Sentry
        public readonly float $eventsSampleRate,
        public readonly float $profilesSampleRate,
        public readonly float $tracesSampleRate,
        // Data
        #[SerializedName('urls')]
        public readonly Links $links = new Links(),
        public readonly Faq $faq = new Faq(),
    ) {
    }
}
