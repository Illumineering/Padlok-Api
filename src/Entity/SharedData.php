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
use App\Repository\SharedDataRepository;
use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Clock\Clock;
use Symfony\Component\Serializer\Annotation\Groups;

#[ORM\Entity(repositoryClass: SharedDataRepository::class)]
#[ApiResource(
    operations: [
        new Get(
            uriTemplate: '/shared/{identifier}',
            output: Info::class,
            provider: SharedInfoProvider::class,
        ),
        new Post(
            uriTemplate: '/share',
            input: Info::class,
            output: Output::class,
            processor: SharedDataProcessor::class,
        ),
        new Put(
            uriTemplate: '/shared/{identifier}/{admin_token}',
            uriVariables: [
                'identifier',
                'admin_token',
            ],
            input: Info::class,
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

    #[ORM\Column(type: Types::GUID, unique: true)]
    #[ApiProperty(identifier: true)]
    #[Groups(['read'])]
    private string $identifier;

    /**
     * @var array<string, int|string>
     */
    #[ORM\Column(type: Types::JSON)]
    #[Groups(['read', 'write'])]
    private array $info;

    #[ORM\Column(length: 255)]
    #[Groups(['read'])]
    private string $adminToken;

    #[ORM\Column]
    #[Groups(['read'])]
    private ?\DateTimeImmutable $createdAt = null;

    #[ORM\Column]
    #[Groups(['read'])]
    private ?\DateTimeImmutable $updatedAt = null;

    public function __construct()
    {
        $this->createdAt = Clock::get()->now();
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

    public function getAdminToken(): string
    {
        return $this->adminToken;
    }

    public function setAdminToken(string $adminToken): self
    {
        $this->adminToken = $adminToken;

        return $this;
    }

    public function getCreatedAt(): ?\DateTimeImmutable
    {
        return $this->createdAt;
    }

    public function getUpdatedAt(): ?\DateTimeImmutable
    {
        return $this->updatedAt;
    }

    public function setUpdatedAt(\DateTimeImmutable $updatedAt): self
    {
        $this->updatedAt = $updatedAt;

        return $this;
    }

    public function getOutput(): Output
    {
        $output = new Output();
        $output->identifier = $this->identifier;
        $output->adminToken = $this->adminToken;

        return $output;
    }
}
