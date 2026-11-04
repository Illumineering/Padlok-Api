# Padlok-API

## Goal

Open-sourcing the whole API of Padlok is a step further the transparency of the application regarding your personal data.
Padlok does not collect any personal data like your location, codes, addresses.

Even when sharing an address and codes, the api is designed to retrieve encrypted data ; and signed aes key to make the data unusable without the proper key that is contained within the url.

## Technologies

Padlok-API is built using [Symfony](https://symfony.com) and [API Platform](https://api-platform.com)
Requires:
- PHP >= 8.4
- Composer
- ext-ctype, ext-iconv
- MariaDB

## API

| Method   | Path                                 | Auth                                  | Description                                   |
|----------|--------------------------------------|---------------------------------------|-----------------------------------------------|
| `POST`   | `/share`                             | none                                  | Store a share, returns `identifier` and `admin_token` |
| `GET`    | `/shared/{identifier}`               | none                                  | Retrieve the encrypted share                  |
| `PUT`    | `/shared/{identifier}`               | `Authorization: Bearer <admin_token>` | Replace the encrypted share                   |
| `DELETE` | `/shared/{identifier}`               | `Authorization: Bearer <admin_token>` | Delete the share                              |
| `GET`    | `/healthz`                           | none                                  | Health check (`503` when a dependency fails)  |

A share body is `{"iterations": <int>, "salt": "<string>", "sealed": "<string>"}`: all fields are required, `iterations` must be positive, `salt` is at most 255 characters and `sealed` at most 16384 characters. Invalid bodies are rejected with `422`.

`PUT` and `DELETE` answer `204` with no body on success, `401` without a Bearer token and `403` with a wrong one.

The `admin_token` is only returned by `POST /share`: the API stores just its SHA-256 hash, so it cannot be retrieved later.

The legacy `PUT` and `DELETE /shared/{identifier}/{admin_token}` routes, with the admin token in the path, are still accepted for older app versions but are deprecated.

## Docker

You can run a local database for this api using Docker:

```
docker compose up -d
```

## Tests

Making sure the back-end is reliable and predictible is mandatory to keep Padlok activity.
To prevent introducing issues ; or unexpected behaviors, the API is unit tested.

With the database running, run the linters and the tests:
```
composer test
```

Plus, those tests are runned on push and pull requests automatically using Github Workflows

## Configuration

Requirements for .env.local file:
- `DATABASE_URL`: [Doctrine configuration](https://symfony.com/doc/current/doctrine.html#configuring-the-database); for storing shared info.
- `APP_SECRET`: Symfony's [secret](https://symfony.com/doc/current/reference/configuration/framework.html#secret), required in production.
- `CORS_ALLOW_ORIGIN`: regex of the origins allowed to call the API from a browser.

Optional:
- `API_VERSION`: version shown in the API documentation.
- `SWAGGER_ENABLED`: enable the Swagger documentation (disabled in production).

## Deploy

- [Configuring a Web Server](https://symfony.com/doc/current/setup/web_server_configuration.html)
- [How to Deploy a Symfony Application](https://symfony.com/doc/current/deployment.html)

Pushing to `dev` or `main` runs the tests and deploys; `scripts/post-deploy` then clears the cache and runs the migrations on the server.

Dev environment is at https://dev.padlok.app
Prod environment is at https://api.padlok.app
