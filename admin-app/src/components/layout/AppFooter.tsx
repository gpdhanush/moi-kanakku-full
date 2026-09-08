import { ENV_CONFIG } from "@/lib/config";

export function AppFooter() {
  const year = new Date().getFullYear();
  const yearLabel = year > 2025 ? `2025-${year}` : "2025";

  return (
    <footer className="border-t border-border bg-background mt-auto">
      <div className="flex h-12 items-center justify-between gap-4 px-6">
        <p className="text-xs text-muted-foreground">
          Copyright © {yearLabel} &nbsp;
          <a
            href="https://gpdhanush.github.io/portfolio/"
            target="_blank"
            rel="noreferrer"
            className="font-medium text-foreground hover:underline"
          >
            gpdhanush
          </a>
          . All rights reserved.
        </p>
        <p className="shrink-0 text-xs text-muted-foreground">
          Version {ENV_CONFIG.APP_VERSION}
        </p>
      </div>
    </footer>
  );
}
