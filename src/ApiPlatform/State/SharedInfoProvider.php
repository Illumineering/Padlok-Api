<?php

declare(strict_types=1);

namespace App\ApiPlatform\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProviderInterface;
use App\ApiPlatform\Dto\Sharing\Info;
use Symfony\Component\Serializer\Normalizer\DenormalizerInterface;

/**
 * @implements ProviderInterface<Info>
 */
final class SharedInfoProvider implements ProviderInterface
{
    public function __construct(
        private readonly SharedDataProvider $provider,
        private readonly DenormalizerInterface $denormalizer,
    ) {
    }

    public function provide(Operation $operation, array $uriVariables = [], array $context = []): ?Info
    {
        $object = $this->provider->provide($operation, $uriVariables, $context);
        if (null === $object) {
            return null;
        }

        return $this->denormalizer->denormalize($object->getInfo(), Info::class);
    }
}
