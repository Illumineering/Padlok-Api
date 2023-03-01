<?php

declare(strict_types=1);

namespace App\ApiPlatform\Serialization;

use App\ApiPlatform\Dto\Faq;
use Symfony\Component\Serializer\Normalizer\NormalizerInterface;

class FaqNormalizer implements NormalizerInterface
{
    public function __construct(
        private readonly QuestionNormalizer $normalizer,
    ) {
    }

    /**
     * {@inheritDoc}
     */
    public function normalize(mixed $object, string $format = null, array $context = [])
    {
        assert($object instanceof Faq);

        return array_map(function (Faq\Question $item) use ($format, $context) {
            return $this->normalizer->normalize($item, $format, $context);
        }, $object->questions);
    }

    /**
     * {@inheritDoc}
     */
    public function supportsNormalization(mixed $data, string $format = null): bool
    {
        return $data instanceof Faq;
    }
}
