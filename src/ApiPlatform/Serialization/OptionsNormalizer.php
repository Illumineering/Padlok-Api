<?php

declare(strict_types=1);

namespace App\ApiPlatform\Serialization;

use App\ApiPlatform\Dto\Options;
use Symfony\Component\Serializer\Normalizer\NormalizerInterface;
use Symfony\Component\Serializer\Normalizer\ObjectNormalizer;

final class OptionsNormalizer implements NormalizerInterface
{
    public function __construct(
        private readonly ObjectNormalizer $normalizer,
        private readonly FaqNormalizer $faqNormalizer,
    ) {
    }

    public function normalize(mixed $object, string $format = null, array $context = [])
    {
        assert($object instanceof Options);
        $normalized = $this->normalizer->normalize($object, $format, $context);
        assert(is_array($normalized));
        $normalized['faq'] = $this->faqNormalizer->normalize($object->faq, $format, $context);

        return $normalized;
    }

    /**
     * @return array<string, ?bool>
     */
    public function getSupportedTypes(?string $format): array
    {
        return [Options::class => true];
    }

    public function supportsNormalization(mixed $data, string $format = null): bool
    {
        return $data instanceof Options;
    }
}
