<?php

declare(strict_types=1);

namespace App\ApiPlatform\Dto\Feedback;

use Symfony\Component\HttpFoundation\HeaderBag;

final class Context
{
    public ?string $appVersion;
    public ?string $customerId;
    public ?string $device;
    public ?string $downloadDate;
    public ?string $language;
    public ?string $osName;
    public ?string $osVersion;

    public function __construct(HeaderBag $headers)
    {
        $this->appVersion = $headers->get('App-Version');
        $this->customerId = $headers->get('Customer-Identifier');
        $this->device = $headers->get('Device');
        $this->downloadDate = $headers->get('Download-Date');
        $this->language = $headers->get('Accept-Language');
        $this->osName = $headers->get('OS-Name');
        $this->osVersion = $headers->get('OS-Version');
    }
}
