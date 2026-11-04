<?php

declare(strict_types=1);

namespace App\ApiPlatform\Dto\Sharing;

use Symfony\Component\Validator\Constraints as Assert;

final class Info
{
    public const int MAX_SALT_LENGTH = 255;
    public const int MAX_SEALED_LENGTH = 16_384;

    #[Assert\NotNull]
    #[Assert\Positive]
    public int $iterations;

    #[Assert\NotBlank]
    #[Assert\Length(max: self::MAX_SALT_LENGTH)]
    public string $salt;

    #[Assert\NotBlank]
    #[Assert\Length(max: self::MAX_SEALED_LENGTH)]
    public string $sealed;
}
