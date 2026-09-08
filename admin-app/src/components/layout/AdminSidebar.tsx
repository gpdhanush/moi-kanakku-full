import { NavLink, useLocation, useNavigate } from "react-router-dom";
import { cn } from "@/lib/utils";
import {
  LayoutDashboard,
  Users,
  ArrowLeftRight,
  MessageSquare,
  Bell,
  KeyRound,
  Settings,
  LogOut,
  ChevronLeft,
  ChevronRight,
} from "lucide-react";
import { useEffect, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { getCurrentUser, clearAuth } from "@/lib/auth";
import { APP_LOGO_SRC } from "@/components/Logo";
import { ENV_CONFIG } from "@/lib/config";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";

const menuItems = [
  { name: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
  { name: "Users Master", href: "/users", icon: Users },
  { name: "Transactions", href: "/transactions", icon: ArrowLeftRight },
  { name: "Feedback", href: "/feedback", icon: MessageSquare },
  { name: "Notifications", href: "/notifications", icon: Bell },
  { name: "User OTPs", href: "/user-otps", icon: KeyRound },
  { name: "Settings", href: "/settings", icon: Settings },
];

function formatLastLogin(value?: string | null): string {
  if (!value) return "—";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "—";
  const day = String(date.getDate()).padStart(2, "0");
  const months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
  ];
  const month = months[date.getMonth()];
  const year = date.getFullYear();
  let hours = date.getHours();
  const minutes = String(date.getMinutes()).padStart(2, "0");
  const ampm = hours >= 12 ? "PM" : "AM";
  hours = hours % 12 || 12;
  return `${day}-${month}-${year} ${String(hours).padStart(2, "0")}:${minutes} ${ampm}`;
}

interface AdminSidebarProps {
  collapsed: boolean;
  onCollapsedChange: (collapsed: boolean) => void;
}

export function AdminSidebar({ collapsed, onCollapsedChange }: AdminSidebarProps) {
  const location = useLocation();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [showLogoutDialog, setShowLogoutDialog] = useState(false);
  const [now, setNow] = useState(() => new Date());
  const [userTick, setUserTick] = useState(0);

  const currentUser = getCurrentUser();
  const userName = currentUser?.name || "Admin";
  const userInitials = userName
    .split(" ")
    .map((n: string) => n[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
  const lastLoginLabel = formatLastLogin(currentUser?.last_login) !== "—"
    ? formatLastLogin(currentUser?.last_login)
    : formatLastLogin(now.toISOString());

  useEffect(() => {
    const timer = setInterval(() => setNow(new Date()), 60_000);
    return () => clearInterval(timer);
  }, []);

  useEffect(() => {
    const onUserUpdated = () => setUserTick((value) => value + 1);
    window.addEventListener("moi-admin-user-updated", onUserUpdated);
    return () =>
      window.removeEventListener("moi-admin-user-updated", onUserUpdated);
  }, []);

  // Re-read getCurrentUser() when profile is updated
  void userTick;

  const isActive = (href: string) => {
    if (href === "/dashboard") return location.pathname === href;
    return location.pathname === href || location.pathname.startsWith(href + "/");
  };

  const handleLogout = async () => {
    await clearAuth();
    queryClient.clear();
    navigate("/login");
  };

  return (
    <>
      <aside
        className={cn(
          "relative flex h-screen flex-col border-r border-sidebar-border bg-sidebar transition-all duration-300",
          collapsed ? "w-16" : "w-64"
        )}
      >
        <div className="flex h-14 items-center border-b border-sidebar-border px-3">
          {!collapsed ? (
            <div className="flex min-w-0 flex-1 items-center gap-2 px-1">
              <img
                src={APP_LOGO_SRC}
                alt="Moi Kanakku"
                className="h-10 w-auto max-w-[160px] object-contain"
              />
            </div>
          ) : (
            <div className="flex flex-1 justify-center">
              <img
                src={APP_LOGO_SRC}
                alt="Moi Kanakku"
                className="h-8 w-8 rounded object-cover"
              />
            </div>
          )}
          {!collapsed && (
            <Button
              variant="ghost"
              size="icon"
              className="h-8 w-8 shrink-0 text-muted-foreground"
              onClick={() => onCollapsedChange(true)}
              aria-label="Collapse sidebar"
            >
              <ChevronLeft className="h-4 w-4" />
            </Button>
          )}
        </div>

        {collapsed && (
          <Button
            variant="outline"
            size="icon"
            className="absolute -right-3 top-4 z-50 h-6 w-6 rounded-full bg-background shadow-sm"
            onClick={() => onCollapsedChange(false)}
            aria-label="Expand sidebar"
          >
            <ChevronRight className="h-3 w-3" />
          </Button>
        )}

        <div
          className={cn(
            "border-b border-sidebar-border px-3 py-4",
            collapsed && "flex justify-center px-2"
          )}
        >
          <div className={cn("flex items-center gap-3", collapsed && "justify-center")}>
            <Avatar className="h-10 w-10 shrink-0">
              <AvatarFallback className="bg-primary/10 text-sm font-semibold text-primary">
                {userInitials}
              </AvatarFallback>
            </Avatar>
            {!collapsed && (
              <div className="min-w-0">
                <p className="truncate text-sm font-semibold uppercase tracking-wide">
                  {userName}
                </p>
                <p className="mt-0.5 flex items-center gap-1.5 text-xs text-muted-foreground">
                  <span className="h-1.5 w-1.5 rounded-full bg-status-success" />
                  {lastLoginLabel}
                </p>
              </div>
            )}
          </div>
        </div>

        <nav className="flex-1 space-y-1 overflow-y-auto p-3">
          {!collapsed && (
            <p className="mb-2 px-3 text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">
              Main Navigation
            </p>
          )}
          {menuItems.map((item) => (
            <NavLink
              key={item.href}
              to={item.href}
              title={collapsed ? item.name : undefined}
              className={cn(
                "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all duration-200",
                collapsed && "justify-center px-2",
                isActive(item.href)
                  ? "bg-primary/10 text-primary"
                  : "text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
              )}
            >
              <item.icon className="h-4 w-4 shrink-0" />
              {!collapsed && <span>{item.name}</span>}
            </NavLink>
          ))}

          <button
            type="button"
            title={collapsed ? "Logout" : undefined}
            onClick={() => setShowLogoutDialog(true)}
            className={cn(
              "flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium text-destructive transition-all duration-200 hover:bg-destructive/10",
              collapsed && "justify-center px-2"
            )}
          >
            <LogOut className="h-4 w-4 shrink-0" />
            {!collapsed && <span>Logout</span>}
          </button>
        </nav>
      </aside>

      <AlertDialog open={showLogoutDialog} onOpenChange={setShowLogoutDialog}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Confirm logout</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to log out of {ENV_CONFIG.COMPANY_NAME}?
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={handleLogout}>Logout</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
