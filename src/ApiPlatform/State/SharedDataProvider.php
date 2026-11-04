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
use Symfony\Component\HttpKernel\Exception\TooManyRequestsHttpException;
use Symfony\Component\HttpKernel\Exception\UnauthorizedHttpException;
use Symfony\Component\RateLimiter\RateLimiterFactoryInterface;

/**
 * @implements ProviderInterface<SharedData>
 */
final class SharedDataProvider implements ProviderInterface
{
    public function __construct(
        private readonly SharedDataRepository $repository,
        private readonly AdminTokenExtractor $adminTokenExtractor,
        private readonly RateLimiterFactoryInterface $adminTokenFailuresLimiter,
    ) {
    }

    public function provide(Operation $operation, array $uriVariables = [], array $context = []): ?SharedData
    {
        $object = $this->repository->findOneBy(['identifier' => $uriVariables['identifier']]);
        if (null === $object) {
            return null;
        }

        if ($operation instanceof Put || $operation instanceof Delete) {
            $this->authorize($object, $uriVariables, $context);
        }

        return $object;
    }

    /**
     * Wrong admin tokens are counted per client IP. Once over the limit, every
     * PUT/DELETE from that IP is refused before the token is even compared, so a
     * guess that happens to be right answers the same as one that is wrong.
     * Only failures count: an app updating its own share is never limited, and
     * nobody can lock a share's owner out by sending wrong tokens for it.
     *
     * @param array<string, mixed> $uriVariables
     * @param array<string, mixed> $context
     */
    private function authorize(SharedData $object, array $uriVariables, array $context): void
    {
        $request = $context['request'] ?? null;
        $clientIp = $request instanceof Request ? $request->getClientIp() : null;
        $limiter = $this->adminTokenFailuresLimiter->create($clientIp ?? 'unknown');

        // consume(0) only reads the current count.
        $limit = $limiter->consume(0);
        if (0 === $limit->getRemainingTokens()) {
            throw new TooManyRequestsHttpException(max(0, $limit->getRetryAfter()->getTimestamp() - time()), 'Too many wrong admin tokens from this address, retry later.');
        }

        $adminToken = $this->adminTokenExtractor->extract($uriVariables, $context);
        if (null === $adminToken) {
            throw new UnauthorizedHttpException('Bearer');
        }
        if (!$object->isAdminToken($adminToken)) {
            $limiter->consume();

            throw new AccessDeniedHttpException();
        }
    }
}
