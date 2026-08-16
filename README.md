# Padlok-API

## Goal

Open-sourcing the whole API of Padlok is a step further the transparency of the application regarding your personal data.
Padlok does not collect any personal data like your location, codes, addresses.

Even when sharing an address and codes, the api is designed to retrieve encrypted data ; and signed aes key to make the data unusable without the proper key that is contained within the url.

## Technologies

Padlok-API is built using [Symfony](https://symfony.com)
Requires:
- PHP >= 8.3
- Composer
- ext-ctype, ext-iconv

## Docker

You can run a local version of this api using Docker.

```
composer boot
```

## Tests

Making sure the back-end is reliable and predictible is mandatory to keep Padlok activity.
To prevent introducing issues ; or unexpected behaviors, the API is unit tested.

After running the composer environment, run the tests:
```
composer test
```

Plus, those tests are runned on push automatically using Github Workflows

## Configuration

Requirements for .env.local file:
- `DATABASE_URL`: [Doctrine configuration](https://symfony.com/doc/current/doctrine.html#configuring-the-database); for storing shared info.
- `MAILER_DSN`: The DSN used for sending feedback mails
- `SUPPORT_MAIL`: The mail address to send feedback mails to

Optional:
- `SHARED_DATA_LIFETIME_DAYS`: How long a shared entry lives, in days, counted from its
  creation or its last update. Defaults to `45`.

## Expiration

Every entry created or updated since expirations were introduced is given an expiration
date. Entries that predate it have none, and are kept forever.

Expired entries are deleted by a recurring task declared in [`src/Schedule.php`](src/Schedule.php),
which runs daily around 03:00. It is driven by the Symfony Scheduler, so it needs a
**long running worker** on the host:

```
bin/console -e prod messenger:consume scheduler_default
```

Run it under a process supervisor (systemd, supervisord, …) so it is restarted on failure
and on boot. Without that worker, nothing is ever purged: expirations are still recorded
and exposed, but no data is removed.

The schedule is stateful, so a run whose due time passes while no worker is up still
happens once one comes back, and only the most recent missed run is caught up on. That
state lives in the `app.persistent.cache` pool, backed by the database, so it survives
both cache clears and deploys.

The deploy calls `messenger:stop-workers`, which asks running workers to finish their
current message and quit; the supervisor then restarts them on the freshly deployed code.

## Deploy

- [Configuring a Web Server](https://symfony.com/doc/current/setup/web_server_configuration.html)
- [How to Deploy a Symfony Application](https://symfony.com/doc/current/deployment.html)

Dev environment is at https://dev.padlok.app
Prod environment is at https://api.padlok.app
