<?php

declare(strict_types=1);

namespace App\ApiPlatform\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProviderInterface;
use App\ApiPlatform\Dto\Faq;

/**
 * @implements ProviderInterface<Faq>
 */
final class FaqProvider implements ProviderInterface
{
    /**
     * {@inheritDoc}
     *
     * @param array<string, mixed> $uriVariables
     * @param array<string, mixed> $context
     */
    public function provide(Operation $operation, array $uriVariables = [], array $context = []): Faq
    {
        return new Faq(Faq\Question::cases());
    }
}
