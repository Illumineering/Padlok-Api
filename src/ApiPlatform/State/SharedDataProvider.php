<?php

declare(strict_types=1);

namespace App\ApiPlatform\State;

use ApiPlatform\Metadata\Delete;
use ApiPlatform\Metadata\Operation;
use ApiPlatform\Metadata\Put;
use ApiPlatform\State\ProviderInterface;
use App\Entity\SharedData;
use App\Repository\SharedDataRepository;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Symfony\Component\HttpKernel\Exception\UnauthorizedHttpException;

/**
 * @implements ProviderInterface<SharedData>
 */
final class SharedDataProvider implements ProviderInterface
{
    public function __construct(
        private readonly SharedDataRepository $repository,
    ) {
    }

    public function provide(Operation $operation, array $uriVariables = [], array $context = []): ?SharedData
    {
        $object = $this->repository->findOneBy(['identifier' => $uriVariables['identifier']]);
        if (null === $object) {
            return null;
        }

        if ($operation instanceof Put || $operation instanceof Delete) {
            $adminToken = $this->getAdminToken($uriVariables, $context);
            if (null === $adminToken) {
                throw new UnauthorizedHttpException('Bearer');
            }
            if (!hash_equals($object->getAdminToken(), $adminToken)) {
                throw new AccessDeniedHttpException();
            }
        }

        return $object;
    }

    /**
     * The admin token is read from the legacy path segment when present,
     * otherwise from an "Authorization: Bearer <token>" header.
     *
     * @param array<string, mixed> $uriVariables
     * @param array<string, mixed> $context
     */
    private function getAdminToken(array $uriVariables, array $context): ?string
    {
        if (isset($uriVariables['admin_token']) && \is_string($uriVariables['admin_token'])) {
            return $uriVariables['admin_token'];
        }

        $request = $context['request'] ?? null;
        if (!$request instanceof Request) {
            return null;
        }

        $header = $request->headers->get('Authorization', '');
        if (1 !== preg_match('/^Bearer\s+(\S+)$/i', trim((string) $header), $matches)) {
            return null;
        }

        return $matches[1];
    }
}
