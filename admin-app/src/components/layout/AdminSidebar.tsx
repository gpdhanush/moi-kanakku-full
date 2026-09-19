import { NavLink, useLocation, useNavigate } from "react-router-dom";
import { cn } from "@/lib/utils";
import {
  LayoutDashboard,
  Users,
  ArrowLeftRight,
  PartyPopper,
  CalendarDays,
  MessageSquare,
  Bell,
  KeyRound,
  Database,
  ScrollText,
  Settings,
  SlidersHorizontal,
  LogOut,
  ChevronLeft,
  ChevronRight,
  Megaphone,
} from "lucide-react";
import { useEffect, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { getCurrentUser, clearAuth } from "@/lib/auth";
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
  // { name: "Transactions", href: "/transactions", icon: ArrowLeftRight },
  // { name: "Functions", href: "/functions", icon: PartyPopper },
  // { name: "Upcoming Functions", href: "/upcoming-functions", icon: CalendarDays },
  { name: "Feedback", href: "/feedback", icon: MessageSquare },
  { name: "Notifications", href: "/notifications", icon: Bell },
  { name: "App Alerts", href: "/app-alerts", icon: Megaphone },
  { name: "User OTPs", href: "/user-otps", icon: KeyRound },
  { name: "Audit Logs", href: "/audit-logs", icon: ScrollText },
  { name: "Database Backup", href: "/database-backup", icon: Database },
  {
    name: "App Configuration",
    href: "/app-configuration",
    icon: SlidersHorizontal,
  },
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
          "relative z-50 flex h-screen flex-col overflow-visible border-r border-sidebar-border bg-sidebar text-sidebar-foreground shadow-xl transition-[width] duration-300",
          collapsed ? "w-16" : "w-72"
        )}
      >
        <Button
          variant="outline"
          size="icon"
          className="absolute -right-3 top-4 z-50 h-6 w-6 rounded-full border-sidebar-border bg-sidebar text-muted-foreground shadow-sm hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
          onClick={() => onCollapsedChange(!collapsed)}
          aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
        >
          {collapsed ? <ChevronRight className="h-3 w-3" /> : <ChevronLeft className="h-3 w-3" />}
        </Button>

        <div
          className={cn(
            "border-b border-sidebar-border px-4 py-5",
            collapsed && "flex justify-center px-2"
          )}
        >
          <div className={cn("flex items-center gap-3", collapsed && "justify-center")}>
            <Avatar className="h-10 w-10 shrink-0">
              <AvatarFallback className="bg-primary/20 text-sm font-semibold text-primary">
                {userInitials}
              </AvatarFallback>
            </Avatar>
            {!collapsed && (
              <div className="min-w-0">
                <p className="truncate text-sm font-semibold uppercase tracking-wide text-sidebar-foreground">
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

        <nav aria-label="Main navigation" className="sidebar-nav flex-1 space-y-1 overflow-y-auto px-3 py-4">
          {!collapsed && (
            <p className="mb-3 px-3 text-[10px] font-semibold uppercase tracking-[0.16em] text-muted-foreground">
              Main Navigation
            </p>
          )}
          {menuItems.map((item) => (
            <NavLink
              key={item.href}
              to={item.href}
              title={collapsed ? item.name : undefined}
              aria-current={isActive(item.href) ? "page" : undefined}
              className={cn(
                "group relative flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium text-sidebar-foreground/80 transition-all duration-200 before:absolute before:bottom-1 before:left-0 before:top-1 before:w-1 before:rounded-full before:bg-primary before:opacity-0 before:transition-opacity hover:bg-sidebar-accent hover:text-sidebar-accent-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary",
                collapsed && "justify-center px-2",
                isActive(item.href)
                  ? cn(
                      "bg-sidebar-accent text-sidebar-accent-foreground before:opacity-100",
                      !collapsed && "translate-x-2"
                    )
                  : "hover:translate-x-1"
              )}
            >
              <item.icon className="h-[18px] w-[18px] shrink-0 text-muted-foreground transition-colors group-hover:text-primary group-[[aria-current=page]]:text-primary" />
              {!collapsed && <span>{item.name}</span>}
            </NavLink>
          ))}
        </nav>

        <div className="shrink-0 border-t border-sidebar-border p-3">
          <button
            type="button"
            title={collapsed ? "Logout" : undefined}
            onClick={() => setShowLogoutDialog(true)}
            className={cn(
              "group relative flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium text-destructive transition-all duration-200 hover:translate-x-1 hover:bg-destructive/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-destructive",
              collapsed && "justify-center px-2"
            )}
          >
            <LogOut className="h-4 w-4 shrink-0" />
            {!collapsed && <span>Logout</span>}
          </button>
        </div>
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
