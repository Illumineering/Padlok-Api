<?php

declare(strict_types=1);

namespace App\ApiPlatform\Serialization;

use App\ApiPlatform\Dto\Faq\Faq;
use App\ApiPlatform\Dto\Faq\Question;
use Symfony\Component\Serializer\Normalizer\NormalizerInterface;

final class FaqNormalizer implements NormalizerInterface
{
    public function __construct(
        private readonly QuestionNormalizer $normalizer,
    ) {
    }

    public function normalize(mixed $object, ?string $format = null, array $context = [])
    {
        assert($object instanceof Faq);

        return array_map(function (Question $item) use ($format, $context) {
            return $this->normalizer->normalize($item, $format, $context);
        }, $object->questions);
    }

    /**
     * @return array<string, ?bool>
     */
    public function getSupportedTypes(?string $format): array
    {
        return [Faq::class => true];
    }

    public function supportsNormalization(mixed $data, ?string $format = null): bool
    {
        return $data instanceof Faq;
    }
}
