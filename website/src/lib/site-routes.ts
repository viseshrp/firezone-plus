import { readdir } from "node:fs/promises";
import { join } from "node:path";

// Enumerate source pages at build time, without a glob/brace-pattern parser.
export async function publicPageRoutes(appDirectory: string): Promise<string[]> {
  const routes = new Set<string>();

  async function visit(directory: string, segments: string[]): Promise<void> {
    for (const entry of await readdir(directory, { withFileTypes: true })) {
      if (entry.isDirectory()) {
        if (/^[_@]/.test(entry.name) || entry.name.includes("[")) continue;
        const nextSegments = entry.name.startsWith("(")
          ? segments
          : [...segments, encodeURIComponent(entry.name)];
        await visit(join(directory, entry.name), nextSegments);
      } else if (entry.isFile() && /^page\.(?:[jt]sx?|mdx?)$/.test(entry.name)) {
        routes.add("/" + segments.join("/"));
      }
    }
  }

  await visit(appDirectory, []);
  return [...routes].sort();
}

export function siteUrl(value = process.env.SITE_URL || "https://firezone.dev"): string {
  const url = new URL(value);
  if (!["http:", "https:"].includes(url.protocol) || url.username || url.password) {
    throw new Error("SITE_URL must be an HTTP(S) URL without credentials");
  }
  url.hash = "";
  url.search = "";
  return url.href.replace(/\/+$/, "");
}
