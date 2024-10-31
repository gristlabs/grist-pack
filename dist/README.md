# Grist Cloud Distribution

This a comprehensive distribution of Grist made with Docker Compose.
It combines the following tools as services in Compose:

* Traefik as a reverse proxy and for TLS termination (handling HTTPS)
* Authelia as an email + password manager, optionally with 2FA and
  password resets
* Dex as an OIDC provider, by default only using Authelia as a backend
  but optionally can also use Google or Microsoft as a identity
  provider

# Quickstart

You will need a domain name for this Grist instance, as well as a
username, password, and default email address for the initial admin
Grist user.

In order to set up authentication secrets and some basic, default
configuration, first run, for example,

```sh
USERNAME=grist \
PASSWORD=grist \
DEFAULT_EMAIL=gristadmin@example.com \
GRIST_DOMAIN=grist.example.com \
./bin/bootstrap-environment
```

This will use Authelia and OpenSSL to generate some cryptographic
information needed in `persist/secrets`, as well as an `.env` file in
the current directory with some defaults for running the Compose
image.

You may wish to inspect the `.env` file to change some defaults,

```sh
nano .env
```

but leave the cryptographic choices alone.

Then run as usual,

```sh
docker compose up
```

This creates the following default setup:

* Grist at https://$GRIST_DOMAIN
* Username for the admin user: $USERNAME
* Password for the admin user: $PASSWORD
* Email for the admin user: $DEFAULT_EMAIL

If you want to add, modify or delete users, you can do this in
`persist/users_database.yml`. All of the instructions needed
to do that are in the file.

Compose will start, in this order, Traefik, Authelia, Dex, and finally
Grist.

# Using systemd

If everything looks fine, you may interrupt Compose (hit Ctrl-C), run
`docker compose down` and use systemd to handle the Grist Docker process:

```sh
sudo systemd enable --now grist
```

This will ensure that Grist restarts cleanly if you need to stop or
restart the server it's running on.

Once you have enabled the systemd unit, you can also do
`systemctl stop grist` or `systemctl start grist` in
order to start or stop the Grist Docker services like any other
systemd unit.

The logs from all of the Grist Docker services will also be available
in systemd's journal service, for example,

```sh
sudo journalctl -xeu grist
```

