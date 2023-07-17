<?php

declare(strict_types=1);

namespace App\ApiPlatform\Dto\Feedback;

enum Reason: string
{
    case Bug = 'bug';
    case Feedback = 'feedback';
    case Feature = 'feature';
    case Help = 'help';
    case Pro = 'pro';
    case Other = 'other';
}
