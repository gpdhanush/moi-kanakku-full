import "./lib/error-capture";

import { consumeLastCapturedError } from "./lib/error-capture";
import { renderErrorPage } from "./lib/error-page";

type ServerEntry = {
  fetch: (request: Request, env: unknown, ctx: unknown) => Promise<Response> | Response;
};

let serverEntryPromise: Promise<ServerEntry> | undefined;

async function getServerEntry(): Promise<ServerEntry> {
  if (!serverEntryPromise) {
    serverEntryPromise = import("@tanstack/react-start/server-entry").then(
      (m) => (m.default ?? m) as ServerEntry,
    );
  }
  return serverEntryPromise;
}

// h3 swallows in-handler throws into a normal 500 Response with body
// {"unhandled":true,"message":"HTTPError"} — try/catch alone never fires for those.
async function normalizeCatastrophicSsrResponse(response: Response): Promise<Response> {
  if (response.status < 500) return response;
  const contentType = response.headers.get("content-type") ?? "";
  if (!contentType.includes("application/json")) return response;

  const body = await response.clone().text();
  if (!isH3SwallowedErrorBody(body)) return response;

  console.error(consumeLastCapturedError() ?? new Error(`h3 swallowed SSR error: ${body}`));
  return new Response(renderErrorPage(), {
    status: 500,
    headers: { "content-type": "text/html; charset=utf-8" },
  });
}

function isH3SwallowedErrorBody(body: string): boolean {
  try {
    const payload = JSON.parse(body) as { unhandled?: unknown; message?: unknown };
    return payload.unhandled === true && payload.message === "HTTPError";
  } catch {
    return false;
  }
}

// Hardening headers added to every response. These raise the cost of framing,
// embedding and automated scraping/cloning of the site. They do not make the
// page un-copyable (browsers must receive the HTML), but they stop clickjacking,
// cross-origin embedding, and tell AI crawlers not to archive or snippet.
const SECURITY_HEADERS: Record<string, string> = {
  // No other site may frame us (clickjacking / "wrap our UI" clones).
  "X-Frame-Options": "DENY",
  // Don't let browsers MIME-sniff responses into executable types.
  "X-Content-Type-Options": "nosniff",
  // Don't leak full URLs/paths to third parties.
  "Referrer-Policy": "strict-origin-when-cross-origin",
  // Lock down powerful features by default.
  "Permissions-Policy": "camera=(), microphone=(), geolocation=(), browsing-topics=()",
  // Tell search/AI crawlers: index, but do NOT archive or build large snippets
  // (limits wholesale reproduction of our content by AI answer engines).
  "X-Robots-Tag": "noarchive, nosnippet, max-snippet:160, notranslate",
  // Isolate our browsing context from cross-origin openers.
  "Cross-Origin-Opener-Policy": "same-origin",
};

function withSecurityHeaders(response: Response): Response {
  // Response headers are immutable on some runtimes; clone to mutate safely.
  const headers = new Headers(response.headers);
  // Only add frame protection to documents, not to CORS-enabled API/data responses.
  for (const [key, value] of Object.entries(SECURITY_HEADERS)) {
    if (!headers.has(key)) headers.set(key, value);
  }
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

export default {
  async fetch(request: Request, env: unknown, ctx: unknown) {
    try {
      const handler = await getServerEntry();
      const response = await handler.fetch(request, env, ctx);
      return withSecurityHeaders(await normalizeCatastrophicSsrResponse(response));
    } catch (error) {
      console.error(error);
      return withSecurityHeaders(
        new Response(renderErrorPage(), {
          status: 500,
          headers: { "content-type": "text/html; charset=utf-8" },
        }),
      );
    }
  },
};
