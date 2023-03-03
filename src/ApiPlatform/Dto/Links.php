<?php

declare(strict_types=1);

namespace App\ApiPlatform\Dto;

final class Links
{
    /**
     * @var array<Url>
     */
    public readonly array $urls;

    public function __construct()
    {
        $this->urls = Url::cases();
    }
}
