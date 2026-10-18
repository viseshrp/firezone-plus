# Firezone Plus maintenance

Docker is the supported deployment method. The inherited `omnibus/` native
installer sources are retained for history and are not maintained or tested.

## Dependency refresh: October 17, 2026

This fork starts from l4rm4nd/firezone v7.2.24. The refresh uses Elixir 1.20.4,
OTP 29, Phoenix 1.8.15, LiveView 1.2.12, Phoenix HTML 4.3.0, Ecto 3.14,
Guardian DB 3.0, Argon2 4.1, OpenID Connect 1.0.1, and PostHog 2.16.
The Docker build supplies Node 24 LTS and current Alpine packages.
The website uses Next 16, React 19, Tailwind 4, and TypeScript 7.

Compatibility changes cover Gettext backends, HTML helpers, LiveView components
and navigation, enum validation, embedded changesets, telemetry, browser fixtures,
and the website's MDX, Flowbite, fonts, and CSS pipeline. The old OpenID Connect
build-time JSON patch is removed: Elixir now provides the required JSON module.
Existing telemetry settings remain authoritative; automatic error tracking is off.

Fresh PostgreSQL 18 installations require explicit non-null UUID primary keys
in the historical migration. Already-recorded migrations are not rerun. The
application schema still has the same 57 migrations. This application retains
its existing API-token storage and does not configure Guardian DB's optional
token adapter; the library upgrade adds no application database migration.

### Retained versions and audit findings

- The initial refresh retained Bulma 0.9.4. The October 18 theme port below
  upgrades it to 1.0.4 and removes the obsolete control extensions.
- The Firezone CIDR, esaml, and Samly forks are pinned to their latest existing
  commits. They contain Firezone-specific behavior, including SAML provider
  refresh support. Replacing them with unrelated Hex versions loses that behavior.
- Decimal 3 and Hackney 4 override stale optional upper bounds in older wrappers.
  Byte formatting, HTTP tests, and browser authentication cover the used APIs.
- Node 24 LTS and matching Node type definitions are intentional; Node 26 is
  outside this maintenance baseline. Wireguardex 0.4.0 is its latest release.
- The SAML identity-provider test image has no newer publisher release and is
  pinned by digest. Its old bundled software is confined to the test fixture.

The October 17 audits recorded the Cloak AES-CTR, Cloak PBKDF2, Cowlib structured
header, and website `braces` advisories. The following maintenance update fixes
the affected dependency paths rather than relying on unused APIs or a server
mitigation.

## Security maintenance: October 18, 2026

The `7.2.26-plus.1` nightly series includes Bulma 1.0.4 and the dashboard port.
Bulma is compiled through its supported Sass module interface with the Firezone
palette. Native radio, checkbox, file, and table styles replace the old extension
packages. A local switch keeps the real checkbox focusable for keyboard users.
The rules page uses the responsive grid in place of deprecated tiles. The light
theme remains explicit because the retained dashboard has no dark theme.

Security changes:

- Remove both unauthenticated AES-CTR implementations from the Docker dependency
  sources. Retain AES-GCM's stored data format and report authentication failure
  as an error. Existing AES-GCM ciphertext remains readable with the same keys.
- Backport Cloak Ecto's PBKDF2 correction using OTP's native implementation,
  passing the configured iteration count and derived-key length separately.
- Pin Cowlib to upstream fix `4401b858f2229abb3ea115c60924f6c77e5f8aa3`, which
  rejects non-printable bytes in structured header strings.
- Replace `next-sitemap` with Next's native sitemap and robots metadata routes,
  removing the [vulnerable `braces`/`micromatch`/`fast-glob` chain](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm). `SITE_URL` remains
  supported, and all static public App Router pages are enumerated at build time.

The [vendored security sources](vendor/security/README.md) include upstream
licenses and patch rationale. They are explicit path dependencies, and Cowlib is
a pinned Git dependency: Hex's registry audit does not inspect these sources.
Application regression tests verify known PBKDF2 vectors, rejection of forged GCM
data, legacy ciphertext compatibility, absent CTR modules, and structured-header
input rejection. Do not interpret a clean registry audit as a source-code audit.

Validation on October 18 passed 697 unit/doctests, 48 browser acceptance tests,
two sitemap tests, the production website build and type check, and application
compile/format/Credo checks. The application and website npm audits reported zero
findings, and `mix hex.audit` reported no retired or advisory packages. The old
unused Hex lock entries for Cloak were removed when switching to the explicit
security sources; no advisory ignore list is used.

An isolated production Docker release also completed the 57 existing migrations
on a fresh test database, served its management page, and created and re-read an
encrypted device record. The record remained readable after an explicit container
restart, and its raw database value was ciphertext. This was a disposable local
test, not a deployment to the VPN host or a live client handshake check.

Run both npm audits, `mix hex.audit`, the application tests and browser acceptance
suite, and the website build and sitemap tests when refreshing these dependencies.
Nightly image smoke checks also verify that the GCM implementation is packaged
and the two CTR modules are absent. This change adds no database migration and
does not alter the native installer archive. The retained `7.2.25-plus.1` release
and existing installations are not updated by publishing a nightly image.

## Build

```sh
docker build -f Dockerfile.prod \
  --build-arg VERSION=7.2.26-plus.1 \
  --build-arg VCS_REF="$(git rev-parse HEAD)" \
  -t firezone-plus:7.2.26-plus.1 .

# Build for the Raspberry Pi deployment from an ARM64 Mac:
docker buildx build --platform linux/arm64 --load \
  -f Dockerfile.prod --build-arg VERSION=7.2.26-plus.1 \
  --build-arg VCS_REF="$(git rev-parse HEAD)" \
  -t firezone-plus:7.2.26-plus.1 .
```

The production image contains the compiled OTP release and runtime packages.
It does not include the website, development dependencies, or native installer
toolchain. Use a new version tag for every distinct build and record its image ID.

## Nightly container builds

`main` is the default maintenance branch. The retained `legacy` branch records
the earlier dependency-refresh baseline.

[Nightly container](https://github.com/viseshrp/firezone-plus/actions/workflows/docker_build.yml)
runs daily at **07:17 UTC** (03:17 US Eastern during daylight saving time,
02:17 during standard time), with an additional manual `workflow_dispatch`
trigger for one-off verification. GitHub can delay scheduled runs; a missed run
does not cause a backlog of builds. GitHub also disables scheduled workflows in
public repositories after 60 days without repository activity; re-enable the
workflow if that occurs.

The workflow builds the exact triggering `main` commit on native AMD64 and ARM64
GitHub-hosted runners. It pulls fresh base images and builds without the Docker
layer cache, including the current runtime OS packages. Committed application
lockfiles remain authoritative. Each platform must pass release-version,
source-revision, runtime-tool, and architecture smoke checks before the combined
manifest receives its public tags:

- `ghcr.io/viseshrp/firezone-plus:nightly` moves to the latest successful build.
- `ghcr.io/viseshrp/firezone-plus:nightly-YYYYMMDD-RUN-ATTEMPT` identifies one run.

The existing `7.2.25-plus.1` ARM64 release tag is retained. Nightly versions include
the UTC date, workflow run and attempt, and source revision; OCI labels record the
full source commit and build time. These smoke checks do not replace the
application, database-upgrade, and client VPN checks required before deployment.

Publishing uses the workflow's short-lived `GITHUB_TOKEN` with package-write
access for this repository. No personal access token or Docker Hub credentials
are required. The workflow replaces the inherited Docker Hub release publisher;
it does not deploy images, edit dependency lockfiles, or create source releases.

To run a build immediately:

```sh
gh workflow run docker_build.yml --repo viseshrp/firezone-plus --ref main
```

See [GitHub's schedule behavior](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#schedule)
and [workflow activation rules](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/disable-and-enable-workflows).

## Existing-installation upgrade

Preserve the installed Compose project name, private environment, salts, database
encryption key, WireGuard keys, application bind mount, database volume, network,
ports, and reverse-proxy configuration. Do not use the example environment as an
upgrade or reset the administrator password.

1. Record the old image ID, project name, mounts, schema versions, user/device
   counts, and working VPN state. Keep the old image locally for rollback.
2. Create and verify a native custom-format PostgreSQL dump. Restore it into an
   isolated database and rehearse the new image's migrations and record reads.
3. Stop only Firezone for the final recovery point. Create another database dump
   and copy its matching private inputs and application files into a restricted
   backup directory. Keep PostgreSQL running.
4. Update only the Firezone image reference. Render Compose quietly, then run
   `docker compose up -d --no-deps --pull never --force-recreate firezone`.
   The server entrypoint runs pending application migrations before starting.
5. Verify management login, existing users/devices/settings, the WireGuard
   interface and peers, nftables, client handshake, forwarding, DNS, and intended
   private-resource access. Restart the updated Firezone service and recheck.

An HTTP login page alone does not verify VPN forwarding or client DNS. Retain the
backup and prior image until application and VPN checks pass.

For rollback with an unchanged schema and unchanged application state, restore
the recorded Compose/image reference and recreate Firezone. If a migration or
write changed compatibility, stop Firezone and restore the matched database dump,
application files, and private inputs before starting the previous image. Never
start an older image against a migrated volume as a rollback experiment.

### PostgreSQL major versions

The standalone example Compose files now target PostgreSQL 18.6 for a fresh
installation and mount `/var/lib/postgresql`, which is the official image's
parent data directory for PostgreSQL 18 and later.

An existing PostgreSQL 15/16 installation must keep its current database image,
volume, and mount during the application-only update. A database major upgrade
is separate: verify a logical dump, restore into a new empty PostgreSQL 18
directory/volume, test it with Firezone, and retain the old database recovery set.
Never point PostgreSQL 18 at an existing 15/16 data directory. See the
[official image storage notes](https://github.com/docker-library/docs/blob/master/postgres/README.md#pgdata).

## Development validation

```sh
mix deps.get
MIX_ENV=test mix compile --force --warnings-as-errors
mix format --check-formatted
mix credo --strict
mix test

cd apps/fz_http/assets
npm ci
npm run deploy
npm audit

cd ../../../website
npm ci
npm run lint
npm run build
npm audit
```

Tests need PostgreSQL; `POSTGRES_HOST` and `POSTGRES_PASSWORD` override the
localhost/postgres test defaults. Browser acceptance tests additionally need
Chromium/ChromeDriver, the pinned SAML fixture on localhost:8400, and Vault
2.2.0 on localhost:8200 with the synthetic dev root token `firezone`.
Run `mix test apps/fz_http/test/fz_http_web/acceptance --only acceptance`.
Never expose the identity-provider fixtures or their synthetic credentials.

Update manifests and lockfiles together. Review upstream change logs before
raising major versions:
[Phoenix](https://github.com/phoenixframework/phoenix/blob/v1.8.15/CHANGELOG.md),
[LiveView](https://phoenix-live-view.hexdocs.pm/changelog.html),
[Phoenix HTML](https://hexdocs.pm/phoenix_html/changelog.html),
[Gettext](https://hexdocs.pm/gettext/changelog.html), and
[Next](https://nextjs.org/docs/app/guides/upgrading/version-16).
