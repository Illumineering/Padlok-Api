<?php

declare(strict_types=1);

namespace App\ApiPlatform\Serialization;

use App\ApiPlatform\Dto\Faq\Category;
use Symfony\Component\Serializer\Normalizer\NormalizerInterface;
use Symfony\Contracts\Translation\TranslatorInterface;

final class CategoryNormalizer implements NormalizerInterface
{
    public function __construct(
        private readonly TranslatorInterface $translator,
    ) {
    }

    public function normalize(mixed $object, string $format = null, array $context = [])
    {
        assert($object instanceof Category);

        return [
            'name' => $object->getName($this->translator),
            'icon' => $object->getIcon(),
        ];
    }

    /**
     * @return array<string, ?bool>
     */
    public function getSupportedTypes(?string $format): array
    {
        return [Category::class => true];
    }

    public function supportsNormalization(mixed $data, string $format = null): bool
    {
        return $data instanceof Category;
    }
}
