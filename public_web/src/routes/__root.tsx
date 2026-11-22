import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import {
  Outlet,
  createRootRouteWithContext,
  useRouter,
  HeadContent,
  Scripts,
  type ErrorComponentProps,
} from "@tanstack/react-router";
import { useEffect, type ReactNode } from "react";

import appCss from "../styles.css?url";
import { reportLovableError } from "../lib/lovable-error-reporting";
import { LangProvider } from "../lib/lang";
import { Header, Footer, ScrollTopButton } from "../components/site";
import { StatusScreen } from "../components/status-screen";
import {
  buildPageHead,
  jsonLdScript,
  localBusinessSchema,
  organizationSchema,
  softwareAppSchema,
  websiteSchema,
} from "../lib/seo";

function NotFoundComponent() {
  return <StatusScreen kind="not-found" />;
}

function ErrorComponent({ error, reset }: ErrorComponentProps) {
  console.error(error);
  const router = useRouter();
  useEffect(() => {
    reportLovableError(error, { boundary: "tanstack_root_error_component" });
  }, [error]);

  return (
    <StatusScreen
      kind="error"
      onRetry={() => {
        router.invalidate();
        reset();
      }}
    />
  );
}

const rootSeo = buildPageHead({
  title: "Moi Kanakku Dindigul - Free Moi App | மொய் கணக்கு",
  description:
    "Moi Kanakku (மொய் கணக்கு) from Dindigul: free Android moi app to record moi gifts for weddings and family functions across Tamil Nadu. No ads.",
  path: "/",
});

export const Route = createRootRouteWithContext<{ queryClient: QueryClient }>()({
  head: () => ({
    meta: [
      { charSet: "utf-8" },
      { name: "viewport", content: "width=device-width, initial-scale=1" },
      ...rootSeo.meta,
      { name: "theme-color", content: "#0b3d2e" },
      { name: "application-name", content: "Moi Kanakku" },
      { name: "apple-mobile-web-app-title", content: "Moi Kanakku" },
      { name: "color-scheme", content: "light" },
      {
        name: "google-site-verification",
        content: import.meta.env["VITE_GOOGLE_SITE_VERIFICATION"] || "",
      },
    ].filter((m) => !("content" in m) || m.content !== ""),
    links: [
      { rel: "stylesheet", href: appCss },
      { rel: "icon", href: "/favicon.png", type: "image/png" },
      { rel: "apple-touch-icon", href: "/icons/apple-touch-icon.png", sizes: "180x180" },
      { rel: "manifest", href: "/site.webmanifest" },
      { rel: "sitemap", type: "application/xml", href: "/sitemap.xml" },
      { rel: "preconnect", href: "https://fonts.googleapis.com" },
      { rel: "preconnect", href: "https://fonts.gstatic.com", crossOrigin: "anonymous" },
      {
        rel: "stylesheet",
        href: "https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:ital,wght@0,400..800;1,400..800&family=Space+Grotesk:wght@300..700&family=Anek+Tamil:wght@400..800&family=Mukta+Malar:wght@200;300;400;500;600;700;800&family=Noto+Sans+Tamil:wght@100..900&display=swap",
      },
    ],
    scripts: [
      jsonLdScript([
        organizationSchema(),
        websiteSchema(),
        softwareAppSchema(),
        localBusinessSchema(),
      ]),
    ],
  }),
  shellComponent: RootShell,
  component: RootComponent,
  notFoundComponent: NotFoundComponent,
  errorComponent: ErrorComponent,
});

function RootShell({ children }: { children: ReactNode }) {
  return (
    <html lang="ta" className="lang-ta">
      <head>
        <HeadContent />
      </head>
      <body className="lang-ta">
        {children}
        <Scripts />
      </body>
    </html>
  );
}

function RootComponent() {
  const { queryClient } = Route.useRouteContext();

  return (
    <QueryClientProvider client={queryClient}>
      {/* Required: nested routes render here. Removing <Outlet /> breaks all child routes. */}
      <LangProvider>
        <div className="flex min-h-screen flex-col">
          <Header />
          <main className="flex-1">
            <Outlet />
          </main>
          <Footer />
          <ScrollTopButton />
        </div>
      </LangProvider>
    </QueryClientProvider>
  );
}
