<?php

declare(strict_types=1);

namespace App\ApiPlatform\Dto\Feedback;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Post;
use App\Controller\SendFeedback;
use Symfony\Component\HttpFoundation\HeaderBag;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Serializer\Annotation\Groups;
use Symfony\Component\Validator\Constraints as Assert;

use function Safe\date;

#[ApiResource(
    operations: [
        new Post(
            status: Response::HTTP_OK,
            controller: SendFeedback::class,
            openapiContext: [
                'tags' => ['Support'],
                'summary' => 'Send a feedback',
                'description' => '',
                'parameters' => [
                    [
                        'name' => 'App-Version',
                        'in' => 'header',
                        'type' => 'string',
                    ],
                    [
                        'name' => 'Customer-Identifier',
                        'in' => 'header',
                        'type' => 'string',
                    ],
                    [
                        'name' => 'Device',
                        'in' => 'header',
                        'type' => 'string',
                    ],
                    [
                        'name' => 'Download-Date',
                        'in' => 'header',
                        'type' => 'string',
                    ],
                    [
                        'name' => 'OS-Name',
                        'in' => 'header',
                        'type' => 'string',
                    ],
                    [
                        'name' => 'OS-Version',
                        'in' => 'header',
                        'type' => 'string',
                    ],
                ],
                'responses' => [
                    Response::HTTP_OK => ['description' => 'Feedback sent'],
                    Response::HTTP_BAD_REQUEST => ['description' => 'Invalid input'],
                    Response::HTTP_UNPROCESSABLE_ENTITY => ['description' => 'Unprocessable entity'],
                ],
            ],
        ),
    ],
    inputFormats: ['json', 'form'],
    outputFormats: ['json'],
    normalizationContext: ['groups' => ['read']],
    denormalizationContext: ['groups' => ['write']],
)]
final class Feedback
{
    #[Groups(['read'])]
    public Context $context;

    #[Assert\NotBlank]
    #[Groups(['read', 'write'])]
    public Reason $reason;

    #[Assert\Email]
    #[Groups(['read', 'write'])]
    public ?string $email = null;

    #[Assert\NotBlank]
    #[Groups(['read', 'write'])]
    public string $message;

    public function enrich(HeaderBag $headers): void
    {
        $this->context = new Context($headers);
    }

    public function __toString(): string
    {
        // Used to build the support email
        $data = [
            'App Version' => $this->context->appVersion,
            'Customer ID' => $this->context->customerId,
            'Date' => date(\DateTimeInterface::ATOM),
            'Device' => $this->context->device,
            'Download date' => $this->context->downloadDate,
            'Language' => $this->context->language,
            'Mail' => $this->email,
            'OS Name' => $this->context->osName,
            'OS Version' => $this->context->osVersion,
            'Reason' => $this->reason->value,
            'Message' => $this->message,
        ];
        $data = array_filter($data);

        return implode("\n", array_map(function ($value, $key) {
            return "$key: $value";
        }, $data, array_keys($data)));
    }
}
