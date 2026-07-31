import path from "node:path";
import { fileURLToPath } from "node:url";
import { withBotId } from "botid/next/config";
import type { NextConfig } from "next";

const projectRoot = path.dirname(fileURLToPath(import.meta.url));
const isDemo = process.env.IS_DEMO === "1";
const basePath = process.env.BASE_PATH ?? (isDemo ? "/demo" : "");

const nextConfig: NextConfig = {
  ...(basePath
    ? {
        ...(isDemo ? { assetPrefix: "/demo-assets" } : {}),
        basePath,
        ...(isDemo
          ? {
              redirects: async () => [
                {
                  basePath: false,
                  destination: basePath,
                  permanent: false,
                  source: "/",
                },
              ],
            }
          : {}),
      }
    : {}),
  cacheComponents: true,
  devIndicators: false,
  env: {
    NEXT_PUBLIC_BASE_PATH: basePath,
  },
  experimental: {
    appNewScrollHandler: true,
    cachedNavigations: true,
    inlineCss: true,
    prefetchInlining: true,
    turbopackFileSystemCacheForDev: true,
  },
  images: {
    remotePatterns: [
      {
        hostname: "avatar.vercel.sh",
      },
      {
        hostname: "*.public.blob.vercel-storage.com",
        protocol: "https",
      },
    ],
  },
  logging: {
    fetches: {
      fullUrl: false,
    },
    incomingRequests: false,
  },
  output: "standalone",
  poweredByHeader: false,
  reactCompiler: true,
  serverExternalPackages: ["pdf-parse", "pdfjs-dist"],
  transpilePackages: ["geist"],
  turbopack: {
    root: projectRoot,
  },
};

const authUrl = process.env.AUTH_URL ?? process.env.NEXTAUTH_URL ?? "";
const enableBotId =
  authUrl === "" ||
  authUrl.startsWith("https://") ||
  authUrl.includes("localhost");

export default enableBotId ? withBotId(nextConfig) : nextConfig;
