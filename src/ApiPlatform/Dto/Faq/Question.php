<?php

declare(strict_types=1);

namespace App\ApiPlatform\Dto\Faq;

use Symfony\Contracts\Translation\TranslatorInterface;

enum Question: string
{
    case AddAddress = 'add_address';
    case NoCodes = 'no_codes';
    case EnableNotifications = 'enable_notifications';
    case NotificationTiming = 'notification_timing';
    case NotificationFailure = 'notification_failure';
    case ShareNoPadlok = 'share_no_padlok';
    case UpdateShareInfo = 'update_share_info';
    case CollectedData = 'collected_data';
    case StoredData = 'stored_data';
    case StoredSharedData = 'stored_shared_data';
    case EndOfSubscription = 'end_of_subscription';
    case UpgradeToLifetime = 'upgrade_to_lifetime';

    public function getCategory(): Category
    {
        return match ($this) {
            Question::AddAddress, Question::NoCodes => Category::GettingStarted,
            Question::EnableNotifications, Question::NotificationFailure, Question::NotificationTiming => Category::Notifications,
            Question::ShareNoPadlok, Question::UpdateShareInfo => Category::Sharing,
            Question::CollectedData, Question::StoredData, Question::StoredSharedData => Category::Privacy,
            Question::EndOfSubscription, Question::UpgradeToLifetime => Category::Premium,
        };
    }

    public function getQuestion(TranslatorInterface $translator): string
    {
        return $translator->trans("faq.{$this->value}.question", domain: 'faq');
    }

    public function getAnswer(TranslatorInterface $translator): string
    {
        return $translator->trans("faq.{$this->value}.answer", domain: 'faq');
    }
}
