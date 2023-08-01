<?php

declare(strict_types=1);

namespace App\Controller;

use ApiPlatform\Validator\ValidatorInterface;
use App\ApiPlatform\Dto\Feedback\Feedback;
use App\ApiPlatform\Dto\Feedback\Reason;
use App\Handler\Feedback\FeedbackHandlerInterface;
use Symfony\Component\DependencyInjection\Attribute\TaggedIterator;
use Symfony\Component\HttpFoundation\RedirectResponse;
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

        if ($redirect = $request->query->get('redirect')) {
            $website = Reason::Illumineering === $feedback->reason ? 'https://illumineering.fr/' : 'https://padlok.app/';

            if (str_starts_with($redirect, $website)) {
                return new RedirectResponse($redirect);
            }
        }

        return new Response(null, 200);
    }
}
