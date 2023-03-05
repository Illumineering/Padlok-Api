<?php

declare(strict_types=1);

namespace App\ApiPlatform\Dto\Faq;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\GetCollection;
use App\ApiPlatform\State\FaqProvider;

#[ApiResource(
    uriTemplate: 'faq',
    operations: [
        new GetCollection(
            openapiContext: [
                'tags' => ['Metadata'],
                'summary' => 'Get Frequently Asked Questions',
                'description' => 'Get frequently asked questions; and associated answers',
            ],
            paginationEnabled: false,
            provider: FaqProvider::class,
        ),
    ],
    formats: ['json'],
)]
final class Faq
{
    /**
     * @var array<Question>
     */
    public readonly array $questions;

    public function __construct()
    {
        $this->questions = Question::cases();
    }
}
