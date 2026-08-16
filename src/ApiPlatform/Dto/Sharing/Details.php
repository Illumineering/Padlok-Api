<?php

declare(strict_types=1);

namespace App\ApiPlatform\Dto\Sharing;

/**
 * Read model for a shared entry: the very same payload clients send in {@see Info},
 * augmented with the entry lifecycle. Fields are kept flat, and existing ones keep
 * their name and type, so clients decoding only the {@see Info} fields are unaffected.
 */
final class Details
{
    public int $iterations;
    public string $salt;
    public string $sealed;
    public \DateTimeImmutable $createdAt;

    /**
     * Null for entries created before expirations existed: those never expire.
     */
    public ?\DateTimeImmutable $expiration = null;
}
