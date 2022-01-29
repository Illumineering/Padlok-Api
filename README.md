# Padlok-API

## Goal

Open-sourcing the whole API of Padlok is a step further the transparency of the application regarding your personnal data.
Padlok does not collect any personal data like your location, codes, addresses.

Even when sharing an address and codes, the api is designed to retreive encrypted data ; and signed aes key to make the data unusable without the proper key that is contained within the url.

## Technologies

Padlok-API is built using [Vapor][https://vapor.codes], and Swift. It is compatible with latest Ubuntu as well with MacOS builds.

## Build

For debugging:
```
swift build
.build/debug/Run serve --env development
```
Debug (staging) environment is at https://dev.padlok.app

For release:
```
swift build -c release
.build/release/Run serve --env production
```
Production environment is at https://api.padlok.app
