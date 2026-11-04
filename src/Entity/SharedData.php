<?php

declare(strict_types=1);

namespace App\Entity;

use ApiPlatform\Metadata\ApiProperty;
use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Delete;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\Post;
use ApiPlatform\Metadata\Put;
use App\ApiPlatform\Dto\Sharing\Info;
use App\ApiPlatform\Dto\Sharing\Output;
use App\ApiPlatform\State\SharedDataProcessor;
use App\ApiPlatform\State\SharedDataProvider;
use App\ApiPlatform\State\SharedInfoProvider;
use App\EventListener\ShareCreationRateLimiter;
use App\Repository\SharedDataRepository;
use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: SharedDataRepository::class)]
#[ApiResource(
    // Info is a readonly DTO: a missing or mistyped field fails its constructor, and
    // this reports it as a 422 violation like the validation constraints do.
    collectDenormalizationErrors: true,
    operations: [
        new Get(
            uriTemplate: '/shared/{identifier}',
            output: Info::class,
            provider: SharedInfoProvider::class,
        ),
        new Post(
            uriTemplate: '/share',
            // Matched by App\EventListener\ShareCreationRateLimiter
            input: Info::class,
            output: Output::class,
            name: ShareCreationRateLimiter::ROUTE,
            processor: SharedDataProcessor::class,
        ),
        // Admin token sent as "Authorization: Bearer <admin_token>"
        new Put(
            uriTemplate: '/shared/{identifier}',
            input: Info::class,
            output: false,
            provider: SharedDataProvider::class,
            processor: SharedDataProcessor::class,
            extraProperties: [
                'standard_put' => true,
            ]
        ),
        new Delete(
            uriTemplate: '/shared/{identifier}',
            provider: SharedDataProvider::class,
            processor: SharedDataProcessor::class,
        ),
        // Legacy routes with the admin token in the path, kept for older app versions
        new Put(
            uriTemplate: '/shared/{identifier}/{admin_token}',
            uriVariables: [
                'identifier',
                'admin_token',
            ],
            deprecationReason: 'Send the admin token as a Bearer token to PUT /shared/{identifier}.',
            input: Info::class,
            output: false,
            provider: SharedDataProvider::class,
            processor: SharedDataProcessor::class,
            extraProperties: [
                'standard_put' => true,
            ]
        ),
        new Delete(
            uriTemplate: '/shared/{identifier}/{admin_token}',
            uriVariables: [
                'identifier',
                'admin_token',
            ],
            deprecationReason: 'Send the admin token as a Bearer token to DELETE /shared/{identifier}.',
            provider: SharedDataProvider::class,
            processor: SharedDataProcessor::class,
        ),
    ],
)]
class SharedData
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    #[ApiProperty(identifier: false)]
    private ?int $id = null;

    // Base62 is case-sensitive: a case-insensitive collation would match "aBc" for "ABC".
    #[ORM\Column(length: 36, unique: true, options: ['fixed' => true, 'charset' => 'ascii', 'collation' => 'ascii_bin'])]
    #[ApiProperty(identifier: true)]
    private string $identifier;

    /**
     * @var array<string, int|string>
     */
    #[ORM\Column(type: Types::JSON)]
    private array $info;

    /**
     * SHA-256 of the admin token, hex-encoded. Tokens are random 128-bit
     * values, so a fast hash is enough: there is nothing to brute-force.
     */
    #[ORM\Column(length: 64, options: ['fixed' => true])]
    private string $adminTokenHash;

    #[ORM\Column]
    private \DateTimeImmutable $createdAt;

    #[ORM\Column]
    private \DateTimeImmutable $updatedAt;

    public function __construct(\DateTimeImmutable $createdAt)
    {
        $this->createdAt = $createdAt;
        $this->updatedAt = $createdAt;
    }

    public function getId(): ?int
    {
        return $this->id;
    }

    public function getIdentifier(): string
    {
        return $this->identifier;
    }

    public function setIdentifier(string $identifier): self
    {
        $this->identifier = $identifier;

        return $this;
    }

    /**
     * @return array<string, int|string>
     */
    public function getInfo(): array
    {
        return $this->info;
    }

    /**
     * @param array<string, int|string> $info
     */
    public function setInfo(array $info): self
    {
        $this->info = $info;

        return $this;
    }

    public function setAdminToken(string $adminToken): self
    {
        $this->adminTokenHash = hash('sha256', $adminToken);

        return $this;
    }

    public function isAdminToken(string $adminToken): bool
    {
        return hash_equals($this->adminTokenHash, hash('sha256', $adminToken));
    }

    public function getCreatedAt(): \DateTimeImmutable
    {
        return $this->createdAt;
    }

    public function getUpdatedAt(): \DateTimeImmutable
    {
        return $this->updatedAt;
    }

    public function setUpdatedAt(\DateTimeImmutable $updatedAt): self
    {
        $this->updatedAt = $updatedAt;

        return $this;
    }
}
