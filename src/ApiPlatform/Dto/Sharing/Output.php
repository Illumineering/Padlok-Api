<?php

declare(strict_types=1);

namespace App\ApiPlatform\Dto\Sharing;

final readonly class Output
{
    public function __construct(
        public string $identifier,
        public string $adminToken,
    ) {
    }
}
