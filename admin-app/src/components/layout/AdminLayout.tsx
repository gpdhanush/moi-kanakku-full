import { Outlet, Navigate } from "react-router-dom";
import { useState, useEffect } from "react";
import { AdminSidebar } from "./AdminSidebar";
import { AdminHeader } from "./AdminHeader";
import { AppFooter } from "./AppFooter";
import { getCurrentUserAsync, getAuthTokenAsync } from "@/lib/auth";
import { initializeSecureStorage } from "@/lib/secureStorage";
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
        await initializeSecureStorage();
        const token = await getAuthTokenAsync();
        const user = await getCurrentUserAsync();
        setIsAuth(!!(token && user));
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
        <div className="flex flex-1 flex-col overflow-hidden">
          <main
            className="flex-1 overflow-y-scroll overflow-x-hidden p-6"
            style={{ scrollbarGutter: "stable", minHeight: 0 }}
          >
            <Outlet />
          </main>
          <AppFooter />
        </div>
      </div>
    </div>
  );
}
