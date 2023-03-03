<?php

declare(strict_types=1);

namespace App\ApiPlatform\Dto;

use Symfony\Contracts\Translation\TranslatorInterface;

enum Category: string
{
    case GettingStarted = 'getting_started';
    case Notifications = 'notifications';
    case Sharing = 'sharing';
    case Privacy = 'privacy';
    case Premium = 'premium';

    public function getName(TranslatorInterface $translator): string
    {
        return $translator->trans("faq.category.{$this->value}", domain: 'faq');
    }

    public function getIcon(): string
    {
        return match ($this) {
            Category::GettingStarted => 'lightbulb',
            Category::Notifications => 'bell',
            Category::Sharing => 'person.2',
            Category::Privacy => 'hand.raised',
            Category::Premium => 'star',
        };
    }
}
