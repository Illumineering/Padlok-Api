<?php

declare(strict_types=1);

namespace App\ApiPlatform\Dto;

use Symfony\Contracts\Translation\TranslatorInterface;

enum Url: string
{
    case Appstore = 'appstore';
    case Instagram = 'instagram';
    case Marketing = 'marketing';
    case Mastodon = 'mastodon';
    case Privacy = 'privacy';
    case Support = 'support';
    case Terms = 'terms';
    case Twitter = 'twitter';

    public function getUrl(TranslatorInterface $translator): string
    {
        return $translator->trans("url.{$this->value}", domain: 'urls');
    }
}
