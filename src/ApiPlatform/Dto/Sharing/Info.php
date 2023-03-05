<?php

declare(strict_types=1);

namespace App\ApiPlatform\Dto\Sharing;

final class Info
{
    public int $iterations;
    public string $salt;
    public string $sealed;
}
