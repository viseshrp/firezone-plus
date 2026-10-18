<div align="center" width="100%">
    <h1>Firezone Plus</h1>
    <p>Enterprise-ready zero-trust access platform built on WireGuard®</p><p> 
    <p>Docker maintenance fork of <a href="https://github.com/l4rm4nd/firezone">l4rm4nd/firezone</a>, based on <a href="https://github.com/firezone/firezone/tree/legacy">Firezone 0.7</a><br>
</div>

## 💡 Description

Firezone is a self-hosted VPN server and Linux firewall:

- Manage remote access through an intuitive web interface and CLI utility.
- [Deploy on your own infrastructure](https://docs.firezone.dev/deploy?utm_source=readme)
  to keep control of your network traffic.
- Built on [WireGuard®](https://www.wireguard.com/) to be stable, performant,
  and lightweight.

> [!TIP]
> Firezone `legacy` branch (v0.7) hit EoL on January 31st 2024.
>
> Firezone Plus starts from the maintained fork's v7.2.24 and updates its dependencies.
> Docker is the supported installation method. The retained native installer sources are archived and are not maintained.
> Read [MAINTENANCE.md](MAINTENANCE.md) for upgrade requirements, validation commands, and dependency exceptions.

![Firezone Architecture](https://user-images.githubusercontent.com/52545545/183804397-ae81ca4e-6972-41f9-80d4-b431a077119d.png) 

## 💎 Features

- **Fast:** Uses WireGuard® to be
  [3-4 times](https://wireguard.com/performance/) faster than OpenVPN.
- **SSO Integration:** Authenticate using any identity provider with an OpenID
  Connect (OIDC) connector.
- **Containerized:** All dependencies are bundled via Docker.
- **Simple:** Takes minutes to set up. Manage via a simple CLI.
- **Secure:** Runs unprivileged. HTTPS enforced. Encrypted cookies.
- **Firewall included:** Uses Linux [nftables](https://netfilter.org) to block
  unwanted egress traffic.

### 🚫 Anti-features

Firezone is **not:**

- An inbound firewall
- A tool for creating mesh networks
- A full-featured router
- An IPSec or OpenVPN server

## 🐳 Installation

Firezone can be installed via Docker and Docker Compose.

Public container images are available on [GHCR](https://github.com/users/viseshrp/packages/container/package/firezone-plus):

```sh
# The verified Raspberry Pi release (linux/arm64)
docker pull ghcr.io/viseshrp/firezone-plus:7.2.25-plus.1

# Nightly builds from main (linux/amd64 and linux/arm64)
docker pull ghcr.io/viseshrp/firezone-plus:nightly
```

Nightly images are built at 07:17 UTC each day. Each successful build also gets a
unique `nightly-YYYYMMDD-RUN-ATTEMPT` tag. Review [the maintenance guide](MAINTENANCE.md#nightly-container-builds)
before upgrading an existing installation; image publication does not update a running server.

The example Compose project below builds locally. To use a published image in an
existing deployment, change only its Firezone image reference and preserve its
database, private environment, keys, mounts, network, and ports.

````bash
# clone the source and build the image
git clone --branch main https://github.com/viseshrp/firezone-plus.git
cd firezone-plus
docker build -f Dockerfile.prod --build-arg VERSION=7.2.25-plus.1 -t firezone-plus:local .

# generate an .env file
docker run --rm firezone-plus:local bin/gen-env > .env

# adjust .env file to your needs
# define EXTERNAL_URL + DEFAULT_ADMIN_EMAIL + DEFAULT_ADMIN_PASSWORD

# disable telemetry (default: true)
echo -e "\nTELEMETRY_ENABLED=false" >> .env
# enable wan connectivity checks (default: true)
echo -e "\nCONNECTIVITY_CHECKS_ENABLED=true" >> .env
# enable local auth (default: true)
echo -e "\nLOCAL_AUTH_ENABLED=true" >> .env

# migrate database and create admin user
docker compose run --rm firezone bin/migrate
docker compose run --rm firezone bin/create-or-reset-admin

# spawn the container stack
docker compose up -d
````

Afterwards, the admin MGMT UI is accessible at http://127.0.0.1:13000.

> [!WARNING]
> It is recommended to combine Firezone with a TLS reverse proxy (e.g. Traefik) and with an Identity Provider (IdP) such as Keycloak or Authentik for Single-Sign-On (SSO) via OAuth/OIDC.
>
> Once SSO is enabled, you should disable local authentication via the `.env` file.

## 🔒 Security

This fork focuses on dependency maintenance. Major dependency updates can require configuration or database migrations; review the maintenance guide before upgrading an existing installation.

The ultimate goal is to mitigate security vulnerabilities, so called CVEs. Typically introduced by the use of outdated libraries and packages. Basically to keep the selfhosted Firezone project alive.

Dependency checks use Hex, npm, RubyGems, and upstream release notes. The inherited Dependabot configuration remains in the repository. Security alerts can remain in current releases; the maintenance guide records the known exceptions.

Note that not all CVEs can be fixed or do receive a patch by the vendor. Moreover, there may be packages that cannot be upraded due to dependencies to other packages.

## ✏️ Documentation

Additional documentation on general usage, troubleshooting, and configuration
can be found at [https://docs.firezone.dev](https://docs.firezone.dev).

## License

See [LICENSE](LICENSE).

WireGuard® is a registered trademark of Jason A. Donenfeld. 
