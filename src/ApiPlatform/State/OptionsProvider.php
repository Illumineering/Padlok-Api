<?php

declare(strict_types=1);

namespace App\ApiPlatform\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProviderInterface;
use App\ApiPlatform\Dto\Options;
use Symfony\Component\DependencyInjection\Attribute\Autowire;

/**
 * @implements ProviderInterface<Options>
 */
final class OptionsProvider implements ProviderInterface
{
    public function __construct(
        #[Autowire('%env(string:API_VERSION)%')]
        private readonly string $apiVersion,
        #[Autowire('%env(float:EVENT_SAMPLE_RATE)%')]
        private readonly float $eventsSampleRate,
        #[Autowire('%env(float:PROFILES_SAMPLE_RATE)%')]
        private readonly float $profilesSampleRate,
        #[Autowire('%env(float:TRACE_SAMPLE_RATE)%')]
        private readonly float $traceSampleRate,
    ) {
    }

    /**
     * @param array<string, mixed> $uriVariables
     * @param array<string, mixed> $context
     */
    public function provide(Operation $operation, array $uriVariables = [], array $context = []): Options
    {
        return new Options(
            apiVersion: $this->apiVersion,
            eventsSampleRate: $this->eventsSampleRate,
            profilesSampleRate: $this->profilesSampleRate,
            tracesSampleRate: $this->traceSampleRate,
        );
    }
}
