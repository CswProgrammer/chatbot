import { generateDummyPassword } from "./db/utils";

export const isProductionEnvironment = process.env.NODE_ENV === "production";
export const isDevelopmentEnvironment = process.env.NODE_ENV === "development";
export const isTestEnvironment = Boolean(
  process.env.PLAYWRIGHT_TEST_BASE_URL ||
    process.env.PLAYWRIGHT ||
    process.env.CI_PLAYWRIGHT
);

export function shouldUseSecureCookies(hostname?: string) {
  if (isDevelopmentEnvironment || isTestEnvironment) {
    return false;
  }

  if (hostname === "localhost" || hostname === "127.0.0.1") {
    return false;
  }

  // Keep middleware cookie reads aligned with NextAuth (auth.ts useSecureCookies).
  return getSecureCookiesForAuth();
}

export function getSecureCookiesForAuth() {
  if (isDevelopmentEnvironment || isTestEnvironment) {
    return false;
  }

  const authUrl = process.env.AUTH_URL ?? process.env.NEXTAUTH_URL ?? "";
  if (
    authUrl === "" ||
    authUrl.includes("localhost") ||
    authUrl.startsWith("http://")
  ) {
    return false;
  }

  return true;
}

/** BotId requires a secure context (HTTPS). Disable on HTTP self-hosted deploys. */
export function isBotIdEnabled() {
  if (isDevelopmentEnvironment || isTestEnvironment) {
    return false;
  }

  const authUrl = process.env.AUTH_URL ?? process.env.NEXTAUTH_URL ?? "";
  if (authUrl.startsWith("http://")) {
    return false;
  }

  return true;
}

export const guestRegex = /^guest-\d+$/;

export const DUMMY_PASSWORD = generateDummyPassword();

export const suggestions = [
  "What are the advantages of using Next.js?",
  "Write code to demonstrate Dijkstra's algorithm",
  "Help me write an essay about Silicon Valley",
  "What is the weather in San Francisco?",
];
