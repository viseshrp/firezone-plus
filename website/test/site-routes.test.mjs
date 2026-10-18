import assert from "node:assert/strict";
import { mkdtemp, mkdir, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import test from "node:test";
import { publicPageRoutes, siteUrl } from "../src/lib/site-routes.ts";

test("sitemap includes public pages and route groups, with no internal routes", async () => {
  const root = await mkdtemp(join(tmpdir(), "firezone-sitemap-"));
  try {
    for (const route of [
      "page.tsx",
      "docs/getting-started/page.mdx",
      "(marketing)/contact/page.tsx",
      "contact/page.tsx",
      "_private/page.tsx",
      "@sidebar/page.tsx",
      "blog/[slug]/page.tsx",
      "api/status/route.ts",
      "layout.tsx",
      "sitemap.ts",
    ]) {
      const path = join(root, route);
      await mkdir(dirname(path), { recursive: true });
      await writeFile(path, "");
    }
    assert.deepEqual(await publicPageRoutes(root), ["/", "/contact", "/docs/getting-started"]);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("SITE_URL supports an installation prefix and excludes URL query/fragment data", () => {
  assert.equal(siteUrl("https://example.com/docs/?ignored=yes#top"), "https://example.com/docs");
  assert.throws(() => siteUrl("https://user:password@example.com"), /without credentials/);
  assert.throws(() => siteUrl("file:///tmp/site"), /HTTP/);
});
