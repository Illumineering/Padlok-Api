# Padlok-API

## Goal

Open-sourcing the whole API of Padlok is a step further the transparency of the application regarding your personal data.
Padlok does not collect any personal data like your location, codes, addresses.

Even when sharing an address and codes, the api is designed to retrieve encrypted data ; and signed aes key to make the data unusable without the proper key that is contained within the url.

## Technologies

Padlok-API is built using [Symfony](https://symfony.com)
Requires:
- PHP >= 8.1
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

## Deploy

- [Configuring a Web Server](https://symfony.com/doc/current/setup/web_server_configuration.html)
- [How to Deploy a Symfony Application](https://symfony.com/doc/current/deployment.html)

Dev environment is at https://dev.padlok.app
Prod environment is at https://api.padlok.app
