<?php

declare(strict_types=1);

namespace App\Handler\Feedback;

use App\ApiPlatform\Dto\Feedback\Feedback;
use Symfony\Component\DependencyInjection\Attribute\AutoconfigureTag;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\Mailer\MailerInterface;
use Symfony\Component\Mime\Address;
use Symfony\Component\Mime\Email;

#[AutoconfigureTag(name: FeedbackHandlerInterface::TAG)]
final class MailFeedbackHandler implements FeedbackHandlerInterface
{
    public function __construct(
        #[Autowire('%env(string:SUPPORT_MAIL)%')]
        private readonly string $supportMail,
        private readonly MailerInterface $mailer,
    ) {
    }

    public function handle(Feedback $feedback): void
    {
        $email = (new Email())
            ->from(new Address('no_reply@padlok.app', 'Padlok Bot'))
            ->to($this->supportMail)
            ->subject('Feedback received!')
            ->text($feedback->__toString());

        if ($sender = $feedback->email) {
            $email->replyTo($sender);
        }
        $this->mailer->send($email);
    }
}
