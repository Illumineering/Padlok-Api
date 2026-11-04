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
use Symfony\Component\HttpKernel\Exception\UnauthorizedHttpException;

/**
 * @implements ProviderInterface<SharedData>
 */
final class SharedDataProvider implements ProviderInterface
{
    public function __construct(
        private readonly SharedDataRepository $repository,
        private readonly AdminTokenExtractor $adminTokenExtractor,
    ) {
    }

    public function provide(Operation $operation, array $uriVariables = [], array $context = []): ?SharedData
    {
        $object = $this->repository->findOneBy(['identifier' => $uriVariables['identifier']]);
        if (null === $object) {
            return null;
        }

        if ($operation instanceof Put || $operation instanceof Delete) {
            $adminToken = $this->adminTokenExtractor->extract($uriVariables, $context);
            if (null === $adminToken) {
                throw new UnauthorizedHttpException('Bearer');
            }
            if (!$object->isAdminToken($adminToken)) {
                throw new AccessDeniedHttpException();
            }
        }

        return $object;
    }
}
