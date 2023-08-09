<?php

declare(strict_types=1);

namespace App\Handler\Feedback;

use App\ApiPlatform\Dto\Feedback\Feedback;
use App\ApiPlatform\Dto\Feedback\Reason;
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
        $from = new Address('no_reply@padlok.app', 'Padlok Bot');
        if (Reason::Illumineering === $feedback->reason) {
            $to = 'hello@illumineering.fr'; // FIXME: maybe not hard-coding this?
        } else {
            $to = $this->supportMail;
        }

        $email = (new Email())
            ->from($from)
            ->to($to)
            ->subject('Feedback received!')
            ->text($feedback->__toString());

        if ($sender = $feedback->email) {
            $email->replyTo($sender);
        }
        $this->mailer->send($email);
    }
}
