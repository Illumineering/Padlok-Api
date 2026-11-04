<?php

declare(strict_types=1);

namespace App\ApiPlatform\State;

use Symfony\Component\HttpFoundation\Request;

/**
 * Reads the admin token a client presents: from the legacy path segment when
 * present, otherwise from an "Authorization: Bearer <token>" header.
 */
final class AdminTokenExtractor
{
    /**
     * @param array<string, mixed> $uriVariables
     * @param array<string, mixed> $context
     */
    public function extract(array $uriVariables, array $context): ?string
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
