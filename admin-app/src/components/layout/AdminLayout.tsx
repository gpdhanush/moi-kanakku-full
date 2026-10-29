import { Outlet, Navigate } from "react-router-dom";
import { useState, useEffect } from "react";
import { AdminSidebar } from "./AdminSidebar";
import { AdminHeader } from "./AdminHeader";
import { AppFooter } from "./AppFooter";
import {
  getAuthToken,
  getCurrentUserAsync,
  getRefreshToken,
  purgeLegacyTokenStorage,
} from "@/lib/auth";
import { authApi } from "@/features/auth/api";
import { useIdleTimeout } from "@/hooks/useIdleTimeout";
import { Loader2 } from "lucide-react";
import { logger } from "@/lib/logger";

function IdleTimeoutGuard() {
  useIdleTimeout({ enabled: true });
  return null;
}

export function AdminLayout() {
  const [isLoading, setIsLoading] = useState(true);
  const [isAuth, setIsAuth] = useState(false);
  const [collapsed, setCollapsed] = useState(false);

  useEffect(() => {
    const checkAuth = async () => {
      try {
        purgeLegacyTokenStorage();

        // Cross-origin (admin host ≠ API host): cookies are blocked.
        // If login already stored a Bearer token in memory, trust it and
        // skip /admin/session (that call 401s without cookies and is noise).
        const memoryUser = await getCurrentUserAsync();
        if (memoryUser?.id && getAuthToken()) {
          setIsAuth(true);
          try {
            const { scheduleAccessTokenRefresh } = await import(
              "@/lib/sessionKeepAlive"
            );
            scheduleAccessTokenRefresh();
          } catch {
            // non-fatal
          }
          return;
        }

        // Soft reload: mint access from tab-scoped refresh, then optional session.
        try {
          const { ensureFreshAccessToken } = await import("@/lib/axios");
          await ensureFreshAccessToken(false);
        } catch {
          // fall through
        }

        let restored = null;
        // Only probe cookie session when we still lack a Bearer (same-site deploys).
        if (!getAuthToken()) {
          restored = await authApi.restoreSession();
        }

        const user =
          restored ||
          (await getCurrentUserAsync()) ||
          (getRefreshToken() ? await getCurrentUserAsync() : null);
        const ok = !!(user?.id && (getAuthToken() || getRefreshToken()));
        setIsAuth(ok);
        if (ok) {
          try {
            const { scheduleAccessTokenRefresh } = await import(
              "@/lib/sessionKeepAlive"
            );
            scheduleAccessTokenRefresh();
          } catch {
            // non-fatal
          }
        }
      } catch (error) {
        logger.error("Authentication check failed:", error);
        setIsAuth(false);
      } finally {
        setIsLoading(false);
      }
    };

    checkAuth();
  }, []);

  if (isLoading) {
    return (
      <div className="flex h-screen w-full items-center justify-center bg-background">
        <div className="flex flex-col items-center gap-4">
          <Loader2 className="h-8 w-8 animate-spin text-primary" />
          <p className="text-sm text-muted-foreground">Loading...</p>
        </div>
      </div>
    );
  }

  if (!isAuth) {
    return <Navigate to="/login" replace />;
  }

  return (
    <div className="flex h-screen w-full overflow-hidden bg-background">
      <IdleTimeoutGuard />
      <AdminSidebar collapsed={collapsed} onCollapsedChange={setCollapsed} />
      <div className="flex flex-1 flex-col overflow-hidden">
        <AdminHeader
          collapsed={collapsed}
          onToggleSidebar={() => setCollapsed((prev) => !prev)}
        />
        <main className="flex-1 overflow-y-auto p-4 md:p-6">
          <Outlet />
        </main>
        <AppFooter />
      </div>
    </div>
  );
}
