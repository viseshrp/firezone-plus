# Docker security backports

These sources are part of the Docker build. Preserve their upstream
licenses when updating them. The versions include a `+firezone.1` suffix to
distinguish these copies from the published packages.

The copies also contain syntax fixes for Elixir 1.20's bitstring pinning and
module-function-call checks. Cloak Ecto resolves Cloak through the adjacent
security source directory, including when built separately.

| Source | Imported release | Changes |
| --- | --- | --- |
| [Cloak](https://github.com/danielberkompas/cloak) | 1.1.4 | Remove both unauthenticated AES-CTR cipher modules. Return an error on GCM authentication failure while preserving its stored ciphertext format. |
| [Cloak Ecto](https://github.com/danielberkompas/cloak_ecto) | 1.3.0 | Use OTP's PBKDF2 implementation with explicit iteration count and key length; remove the obsolete external PBKDF2 dependency. |
| [Wireguardex](https://github.com/firezone/wireguardex) (Apache-2.0) | 0.4.0 | Compile the NIF from locked Rust sources with Rustler 0.39 and WireGuard control 2.0; remove the old binary downloader. Preserve its Elixir API. |
| [netlink-packet-utils](https://github.com/rust-netlink/netlink-packet-utils) (MIT) | 0.5.2 | Alias the archived `paste` dependency to maintained `pastey`; retain parsing code and API. |
| [Bypass](https://github.com/PSPDFKit-labs/bypass) (MIT, test only) | 2.1.0 | Adopt Ranch 2's socket ownership and ephemeral-port allocation; retain HTTP expectation behavior. Not included in the production release. |

The corresponding advisories are
[CVE-2026-95105](https://cna.erlef.org/cves/CVE-2026-95105.html) and
[CVE-2026-94206](https://cna.erlef.org/cves/CVE-2026-94206.html).
Firezone's vault has always used AES-GCM; this change does not rotate keys,
change encrypted field types, or migrate stored values. Configurations that use
either removed CTR module are deliberately unsupported. An installation that
used Cloak's faulty PBKDF2 field would need to recompute those hashes before
switching to the corrected implementation; Firezone does not use that field.

Hex audits do not inspect path dependencies. The application security regression
tests therefore verify the absence of CTR modules, authenticated AES-GCM behavior
and legacy ciphertext compatibility, and published PBKDF2 test vectors. These
copies must remain under review even when the registry audit reports no findings.

Cowlib is separately pinned in `apps/fz_http/mix.exs` to upstream fix
[`4401b858`](https://github.com/ninenines/cowlib/commit/4401b858f2229abb3ea115c60924f6c77e5f8aa3)
for [CVE-2026-43966](https://cna.erlef.org/cves/CVE-2026-43966.html).
Its regression test rejects non-printable bytes, including CR and LF, in
structured header strings. Git dependencies also require direct review beyond
the Hex registry audit.

The Wireguardex native lock upgrades Curve25519 to 4.1.3 and anyhow to 1.0.104,
addressing [RUSTSEC-2024-0344](https://rustsec.org/advisories/RUSTSEC-2024-0344.html)
and [RUSTSEC-2026-0190](https://rustsec.org/advisories/RUSTSEC-2026-0190.html).
Replacing the archived macro removes
[RUSTSEC-2024-0436](https://rustsec.org/advisories/RUSTSEC-2024-0436.html).
`scripts/audit-native-dependencies.py` checks registry crates, including
informational advisories. It cannot audit these path patches; review them directly.
Use the disposable kernel test plus application and deployed-client tests when
changing the NIF or its netlink dependencies. The upstream `Cargo.toml.orig`
inside netlink-packet-utils records the imported manifest; `Cargo.toml` contains
the active dependency alias.
