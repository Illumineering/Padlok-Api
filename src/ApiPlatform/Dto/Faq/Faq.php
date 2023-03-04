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
                'summary' => 'Get frequently asked question; and associated answers',
                'description' => '',
            ],
            paginationEnabled: false,
            provider: FaqProvider::class,
        ),
    ],
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
