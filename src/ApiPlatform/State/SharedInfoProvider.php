<?php

declare(strict_types=1);

namespace App\ApiPlatform\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProviderInterface;
use App\ApiPlatform\Dto\Sharing\Details;
use Symfony\Component\Serializer\Normalizer\DenormalizerInterface;

/**
 * @implements ProviderInterface<Details>
 */
final class SharedInfoProvider implements ProviderInterface
{
    public function __construct(
        private readonly SharedDataProvider $provider,
        private readonly DenormalizerInterface $denormalizer,
    ) {
    }

    public function provide(Operation $operation, array $uriVariables = [], array $context = []): ?Details
    {
        $object = $this->provider->provide($operation, $uriVariables, $context);
        if (null === $object) {
            return null;
        }

        $details = $this->denormalizer->denormalize($object->getInfo(), Details::class);
        $details->createdAt = $object->getCreatedAt();
        $details->expiration = $object->getExpiration();

        return $details;
    }
}
