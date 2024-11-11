<?php

declare(strict_types=1);

namespace App\ApiPlatform\State;

use ApiPlatform\Metadata\DeleteOperationInterface;
use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProcessorInterface;
use App\ApiPlatform\Dto\Sharing\Info;
use App\ApiPlatform\Dto\Sharing\Output;
use App\Entity\SharedData;
use App\Repository\SharedDataRepository;
use Symfony\Component\Serializer\Normalizer\NormalizerInterface;
use Symfony\Component\Uid\Uuid;
use Tuupola\Base62;

/**
 * @implements ProcessorInterface<Info|SharedData, Output>
 */
final class SharedDataProcessor implements ProcessorInterface
{
    public function __construct(
        private readonly SharedDataRepository $repository,
        private readonly NormalizerInterface $normalizer,
        private readonly Base62 $base62,
    ) {
    }

    /* @phpstan-ignore class.notFound (Annotation error because of ApiPlatform…) */
    public function process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): ?Output
    {
        if ($operation instanceof DeleteOperationInterface) {
            \assert($data instanceof SharedData);
            $this->repository->remove($data, true);

            return null;
        }

        \assert($data instanceof Info);

        if ($previous = $context['previous_data'] ?? null) {
            \assert($previous instanceof SharedData);
            $shared = $this->repository->find($previous->getId());
            \assert(null !== $shared);
        } else {
            $shared = new SharedData();
            $shared->setIdentifier($this->base62->encode(Uuid::v4()->toBinary()));
            $shared->setAdminToken($this->base62->encode(Uuid::v4()->toBinary()));
        }

        $normalized = $this->normalizer->normalize($data);
        \assert(\is_array($normalized));
        $shared->setInfo($normalized);

        $this->repository->save($shared, true);

        return $shared->getOutput();
    }
}
