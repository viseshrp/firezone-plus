# Docker security backports

These MIT-licensed sources are part of the Docker build. Preserve their upstream
licenses when updating them. The versions include a `+firezone.1` suffix to
distinguish these copies from the published packages.

The copies also contain syntax fixes for Elixir 1.20's bitstring pinning and
module-function-call checks. Cloak Ecto resolves Cloak through the adjacent
security source directory, including when built separately.

| Source | Imported release | Changes |
| --- | --- | --- |
| [Cloak](https://github.com/danielberkompas/cloak) | 1.1.4 | Remove both unauthenticated AES-CTR cipher modules. Return an error on GCM authentication failure while preserving its stored ciphertext format. |
| [Cloak Ecto](https://github.com/danielberkompas/cloak_ecto) | 1.3.0 | Use OTP's PBKDF2 implementation with explicit iteration count and key length; remove the obsolete external PBKDF2 dependency. |

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
