<?php

declare(strict_types=1);

namespace App\ApiPlatform\Dto\Sharing;

use Symfony\Component\Validator\Constraints as Assert;

final class Info
{
    public const int MAX_SALT_LENGTH = 255;
    public const int MAX_SEALED_LENGTH = 16_384;
    // The apps use 1000. The cap stops a share from making a recipient's app hang
    // on key derivation, with room to raise the count (OWASP suggests 600,000).
    public const int MAX_ITERATIONS = 1_000_000;

    #[Assert\NotNull]
    #[Assert\Positive]
    #[Assert\LessThanOrEqual(self::MAX_ITERATIONS)]
    public int $iterations;

    #[Assert\NotBlank]
    #[Assert\Length(max: self::MAX_SALT_LENGTH)]
    public string $salt;

    #[Assert\NotBlank]
    #[Assert\Length(max: self::MAX_SEALED_LENGTH)]
    public string $sealed;
}
