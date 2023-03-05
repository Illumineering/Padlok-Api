<?php

declare(strict_types=1);

namespace App\ApiPlatform\Dto;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\HttpOperation;
use App\ApiPlatform\Dto\Faq\Faq;
use App\ApiPlatform\State\OptionsProvider;
use Symfony\Component\Serializer\Annotation\SerializedName;

#[ApiResource(
    uriTemplate: 'options',
    operations: [
        new GetCollection(),
        new HttpOperation(
            method: HttpOperation::METHOD_OPTIONS,
            output: Options::class,
        ),
    ],
    openapiContext: [
        'tags' => ['Metadata'],
        'summary' => 'Get App Parameters',
        'description' => 'Get app parameters, including faq, external links and Sentry rates',
    ],
    paginationEnabled: false,
    provider: OptionsProvider::class,
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
