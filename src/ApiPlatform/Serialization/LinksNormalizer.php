<?php

declare(strict_types=1);

namespace App\ApiPlatform\Serialization;

use App\ApiPlatform\Dto\Links;
use Symfony\Component\Serializer\Normalizer\NormalizerInterface;
use Symfony\Contracts\Translation\TranslatorInterface;

final class LinksNormalizer implements NormalizerInterface
{
    public function __construct(
        private readonly TranslatorInterface $translator,
    ) {
    }

    public function normalize(mixed $object, string $format = null, array $context = [])
    {
        assert($object instanceof Links);
        $urls = [];
        foreach ($object->urls as $url) {
            $urls[$url->value] = $url->getUrl($this->translator);
        }

        return $urls;
    }

    /**
     * @return array<string, ?bool>
     */
    public function getSupportedTypes(?string $format): array
    {
        return [Links::class => true];
    }

    public function supportsNormalization(mixed $data, string $format = null): bool
    {
        return $data instanceof Links;
    }
}
