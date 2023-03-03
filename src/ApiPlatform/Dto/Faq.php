<?php

declare(strict_types=1);

namespace App\ApiPlatform\Dto;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\GetCollection;
use App\ApiPlatform\State\FaqProvider;

#[ApiResource(
    uriTemplate: 'faq',
    operations: [
        new GetCollection(
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
