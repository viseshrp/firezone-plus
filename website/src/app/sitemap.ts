import type { MetadataRoute } from "next";
import { join } from "node:path";
import { publicPageRoutes, siteUrl } from "@/lib/site-routes";

export const dynamic = "force-static";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const routes = await publicPageRoutes(join(process.cwd(), "src/app"));
  const base = siteUrl();
  return routes.map((route) => ({ url: base + route }));
}
