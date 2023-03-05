<?php

declare(strict_types=1);

namespace App\ApiPlatform\State;

use ApiPlatform\Metadata\Delete;
use ApiPlatform\Metadata\Operation;
use ApiPlatform\Metadata\Put;
use ApiPlatform\State\ProviderInterface;
use App\Entity\SharedData;
use App\Repository\SharedDataRepository;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

/**
 * @implements ProviderInterface<SharedData>
 */
final class SharedDataProvider implements ProviderInterface
{
    public function __construct(
        private readonly SharedDataRepository $repository,
    ) {
    }

    /**
     * {@inheritDoc}
     *
     * @param array<string, mixed> $uriVariables
     * @param array<string, mixed> $context
     */
    public function provide(Operation $operation, array $uriVariables = [], array $context = []): object|array|null
    {
        $object = $this->repository->findOneBy(['identifier' => $uriVariables['identifier']]);
        if (is_null($object)) {
            return null;
        }

        if ($operation instanceof Put || $operation instanceof Delete) {
            $adminToken = $uriVariables['admin_token'];
            if ($object->getAdminToken() !== $adminToken) {
                throw new AccessDeniedHttpException();
            }
        }

        return $object;
    }
}
