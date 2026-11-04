<?php

declare(strict_types=1);

namespace App\EventListener;

use Symfony\Component\EventDispatcher\Attribute\AsEventListener;
use Symfony\Component\HttpKernel\Event\RequestEvent;
use Symfony\Component\HttpKernel\Exception\TooManyRequestsHttpException;
use Symfony\Component\HttpKernel\KernelEvents;
use Symfony\Component\RateLimiter\RateLimiterFactoryInterface;

/**
 * Limits share creation per client IP, before the request body is even read.
 *
 * Symfony's #[RateLimit] attribute is read from the controller, and API Platform
 * operations all share its own controller, hence a request listener.
 */
#[AsEventListener(event: KernelEvents::REQUEST)]
final class ShareCreationRateLimiter
{
    public const string ROUTE = 'share_create';

    public function __construct(
        private readonly RateLimiterFactoryInterface $shareCreationLimiter,
    ) {
    }

    public function __invoke(RequestEvent $event): void
    {
        $request = $event->getRequest();
        if (!$event->isMainRequest() || self::ROUTE !== $request->attributes->get('_route')) {
            return;
        }

        $limit = $this->shareCreationLimiter->create($request->getClientIp() ?? 'unknown')->consume();
        if (!$limit->isAccepted()) {
            throw new TooManyRequestsHttpException(max(0, $limit->getRetryAfter()->getTimestamp() - time()), 'Too many shares created from this address, retry later.');
        }
    }
}
