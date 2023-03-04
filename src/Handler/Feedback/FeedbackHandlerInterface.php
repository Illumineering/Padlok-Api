<?php

declare(strict_types=1);

namespace App\Handler\Feedback;

use App\ApiPlatform\Dto\Feedback\Feedback;

interface FeedbackHandlerInterface
{
    public const TAG = 'app.feedback.handler';

    public function handle(Feedback $feedback): void;
}
