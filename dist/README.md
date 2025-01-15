( You may also read this document online at
  https://github.com/gristlabs/grist-pack/tree/main/dist )

# Grist Cloud Distribution

This a comprehensive distribution of Grist made with Docker Compose.
Along with Grist, it combines the following tools as services in
Compose:

* [Traefik](https://github.com/traefik/traefik) as a reverse proxy and for TLS termination (handling HTTPS)
* [Authelia](https://github.com/authelia/authelia) as an email + password manager, optionally with 2FA and
  password resets
* [Dex](https://github.com/dexidp/dex) as an OIDC provider, by default only using Authelia as a backend
  but optionally can also use Google or Microsoft as a identity
  provider

# Quickstart

You will need a domain name for this Grist instance, as well as a
username, password, and default email address for the initial admin
Grist user.

In order to set up authentication secrets and default
configuration, first run, for example:

```sh
USERNAME=grist \
PASSWORD=grist \
DEFAULT_EMAIL=gristadmin@example.com \
GRIST_DOMAIN=grist.example.com \
./bin/bootstrap-environment
```

This will use Authelia and OpenSSL to generate cryptographic
information needed in `persist/secrets`, as well as an `.env` file in
the current directory with some defaults for running the Compose
image.

You may wish to inspect the `.env` file to change some defaults:

```sh
nano .env
```

But leave the cryptographic choices alone.

Then run, as usual:

```sh
docker compose up
```

This creates the following default setup:

* Grist at `https://$GRIST_DOMAIN`
* Username for the admin user: `$USERNAME`
* Password for the admin user: `$PASSWORD`
* Email for the admin user: `$DEFAULT_EMAIL`

If you want to add, modify or delete users, you can do this in
`persist/users_database.yml`. All of the instructions needed
to do that are in the file.

Compose will start, in the following order: Traefik, Authelia, Dex, and finally
Grist.

# Using systemd

If everything looks fine, you may interrupt Compose (hit Ctrl-C), run
`docker compose down` and use systemd to handle the Grist Docker process:

```sh
sudo systemctl enable --now grist
```

This will ensure that Grist restarts cleanly if you need to stop or
restart the server it's running on.

Once you have enabled the systemd unit, you can also run
`sudo systemctl stop grist` or `sudo systemctl start grist` in
order to start or stop the Grist Docker services like any other
systemd unit.

The logs from all of the Grist Docker services will also be available
in systemd's journal service, for example:

```sh
sudo journalctl -xeu grist --all
```

# Configuration

The following environment variables can be configured:

* `USERNAME`
* `PASSWORD`
* `DEFAULT_EMAIL`
* `GRIST_DOMAIN`
* `TEAM`
* `TRAEFIK_ENABLE_DASHBOARD`
* `HTTPS_METHOD`
* `GOOGLE_CLIENT_ID`
* `GOOGLE_CLIENT_SECRET`
* `MICROSOFT_CLIENT_ID`
* `MICROSOFT_CLIENT_SECRET`
* `PERSIST_DIR`
* `SECRETS_DIR`

They are documented in the generated `.env` file. 

## Changing configuration variables

Variables may be changed, but some require regenerating files in the
directory defined by `PERSIST_DIR`. Here are some cases:

* `USERNAME`, `PASSWORD`: If you change either of these, you will need
  to delete Authelia's `users_database.yaml` file and re-run the
  bootstrap script to regenerate it.
* `DEFAULT_EMAIL`: This variable is used for generating the first user
  in Authelia, for defining the first admin user in Grist, and  – if you
  use automatic HTTPS – for associating a user to a certificate with
  Let's Encrypt. If you change this variable, you will have to change
  regenerate `users_database.yaml` as above, and possibly reassign
  ownership of documents in Grist to the new email.
* `GRIST_DOMAIN`: If `GRIST_DOMAIN` is changed and you are using the
  automatically created self-signed certificates, you will need to
  delete your existing certificates under `traefik-certs`, namely
  `grist.cert` and `grist.key`, and re-run the bootstrap script to
  create a new certificate.

Additionally, it's possible to reset the environment to a mostly
pristine state:

```sh
./bin/reset-environment
```

This will stop Grist, back up your generated files, and save your
current configuration variables, if any, into the `~/.env` file. You
may then inspect or modify your variables and re-run the bootstrap
script again.

## Additional configuration

If you would like to pass any other environment variables to your
Grist instance, you may use a supplemental file called
`persist/grist-env` to define any other extra variables. The syntax is
the same as the standard `.env` file syntax.

The configuration defined in `.env` takes precedence over the
variables defined in `persist/grist-env`.

The extra variables defined in `persist/grist-env` will only be
applied to the Grist Docker Compose service. In particular, they will
not affect Traefik's, Dex's, or Authelia's environment.

# Updating Grist

To update to the latest Grist version at any time, first stop Grist.

If using systemd:

```sh
sudo systemctl disable --now grist
```

Otherwise:

```sh
docker compose down
```

Then pull the latest changes:

```sh
docker compose pull
```

Once that completes successfully, restart Grist.

If using systemd:

```sh
sudo systemctl enable --now grist
```

Otherwise:

```sh
docker compose up
```

You may then confirm as usual from the Grist web interface that the
latest version is now available.
