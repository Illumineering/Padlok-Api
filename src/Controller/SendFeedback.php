<?php

declare(strict_types=1);

namespace App\Controller;

use ApiPlatform\Validator\ValidatorInterface;
use App\ApiPlatform\Dto\Feedback\Feedback;
use App\Handler\Feedback\FeedbackHandlerInterface;
use Symfony\Component\DependencyInjection\Attribute\TaggedIterator;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Attribute\AsController;

#[AsController]
final class SendFeedback
{
    /**
     * @param iterable<FeedbackHandlerInterface> $handlers
     */
    public function __construct(
        #[TaggedIterator(tag: FeedbackHandlerInterface::TAG)]
        private readonly iterable $handlers,
        private readonly ValidatorInterface $validator,
    ) {
    }

    public function __invoke(Feedback $feedback, Request $request): Response
    {
        $this->validator->validate($feedback);
        $feedback->enrich($request->headers);

        foreach ($this->handlers as $handler) {
            $handler->handle($feedback);
        }

        return new Response(null, 200);
    }
}
