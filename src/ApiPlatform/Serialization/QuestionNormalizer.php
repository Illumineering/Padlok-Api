<?php

declare(strict_types=1);

namespace App\ApiPlatform\Serialization;

use App\ApiPlatform\Dto\Faq\Question;
use Symfony\Component\Serializer\Normalizer\NormalizerInterface;
use Symfony\Contracts\Translation\TranslatorInterface;

class QuestionNormalizer implements NormalizerInterface
{
    public function __construct(
        private readonly TranslatorInterface $translator,
        private readonly CategoryNormalizer $normalizer,
    ) {
    }

    /**
     * {@inheritDoc}
     */
    public function normalize(mixed $object, string $format = null, array $context = [])
    {
        assert($object instanceof Question);

        return [
            'question' => $object->getQuestion($this->translator),
            'answer' => $object->getAnswer($this->translator),
            'category' => $this->normalizer->normalize($object->getCategory(), $format, $context),
        ];
    }

    /**
     * {@inheritDoc}
     */
    public function supportsNormalization(mixed $data, string $format = null): bool
    {
        return $data instanceof Question;
    }
}
