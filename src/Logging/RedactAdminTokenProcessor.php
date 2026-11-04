<?php

declare(strict_types=1);

namespace App\Logging;

use Monolog\Attribute\AsMonologProcessor;
use Monolog\LogRecord;
use Monolog\Processor\ProcessorInterface;

/**
 * Strips admin tokens from log records: the legacy /shared/{identifier}/{admin_token}
 * path segment, Bearer credentials, and any "admin_token" / "authorization" key.
 *
 * Runs last (lowest priority) so it also covers data added by other processors,
 * such as the request URL added by WebProcessor.
 */
#[AsMonologProcessor(priority: -1024)]
final class RedactAdminTokenProcessor implements ProcessorInterface
{
    public const string REDACTED = '[redacted]';

    private const array SENSITIVE_KEYS = ['admin_token', 'authorization'];

    public function __invoke(LogRecord $record): LogRecord
    {
        return $record->with(
            message: $this->redactString($record->message),
            context: $this->redactArray($record->context),
            extra: $this->redactArray($record->extra),
        );
    }

    /**
     * @param array<mixed> $data
     *
     * @return array<mixed>
     */
    private function redactArray(array $data): array
    {
        foreach ($data as $key => $value) {
            if (\is_string($key) && \in_array(strtolower($key), self::SENSITIVE_KEYS, true)) {
                $data[$key] = self::REDACTED;
            } elseif (\is_string($value)) {
                $data[$key] = $this->redactString($value);
            } elseif (\is_array($value)) {
                $data[$key] = $this->redactArray($value);
            }
        }

        return $data;
    }

    private function redactString(string $value): string
    {
        return preg_replace(
            ['#(/shared/[^/?\s"\']+/)[^/?\s"\']+#', '#(Bearer\s+)\S+#i'],
            ['$1'.self::REDACTED, '$1'.self::REDACTED],
            $value,
        ) ?? $value;
    }
}
