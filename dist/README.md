# Grist Cloud Distribution

This a comprehensive distribution of Grist made with Docker Compose. It combines the following tools as services in Compose:

* Traefik as a reverse proxy and optionally for TLS termination (handling HTTPS)
* Authelia as an email + password manager, optionally with 2FA, password resets

* Dex as an OIDC provider, by default only using Authelia as a backend but optionally can also use Google or Microsoft as a identity provider

# Quickstart

First, make sure that [docker is installed](https://docs.docker.com/engine/install/).

In order to set up authentication secrets and some basic, default configuration, first run

```sh
./bin/generate-secure-secrets
```

<!-- TODO: Logically separate out the crypto part of setup from the
other bits required, such as APP_HOME_URL or persist location-->
This will use Authelia to generate some cryptographic information needed in `config/secrets`, as well as an `.env` file in the current directory with some defaults for running the Compose image. You may wish to inspect the `.env` file to change some defaults, but leave the cryptographic choices alone. Then run as usual,

```sh
docker compose up
```

This creates the following default setup:

* Grist at http://grist.localhost
<!--TODO: let user configure the default username/password -->
* Default username: `test`
* Default password: `test`

If you want to add, modify or delete users, you can do this in `config/authelia/users_database.yml`. All of the instructions needed to do that are in the file.

Compose will start, in this order, Traefik, Authelia, Dex, and finally Grist, at the URL specified by `APP_HOME_URL` (by default, at `http://grist.localhost` as above).
