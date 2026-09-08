import { useQuery } from "@tanstack/react-query";
import {
  LayoutDashboard,
  Users,
  User,
  ArrowLeftRight,
  RefreshCw,
  TrendingUp,
  Bell,
  Mail,
  MailOpen,
  MessageSquare,
  Settings2,
  Calendar,
  Smartphone,
  Loader2,
  type LucideIcon,
} from "lucide-react";
import { PageTitle } from "@/components/ui/page-title";
import { StatCard, StatCardSkeleton } from "@/components/ui/stat-card";
import { Button } from "@/components/ui/button";
import { usePageMeta } from "@/hooks/usePageMeta";
import { dashboardApi, type DashboardStat } from "@/features/dashboard/api";
import { getCurrentUser } from "@/lib/auth";

const STAT_ICON_MAP: Record<string, LucideIcon> = {
  "Total Users": Users,
  "Total Persons": User,
  "Total Transaction Functions": ArrowLeftRight,
  "Total Transactions": RefreshCw,
  "Total Invest Transactions": TrendingUp,
  "Total Return Transactions": Bell,
  "Total Notifications": Mail,
  "Read Notifications": MailOpen,
  "Unread Notifications": MailOpen,
  "Total Feedbacks": MessageSquare,
  "Total Default Functions": Settings2,
  "Total Upcoming Functions": Calendar,
  "Total User Devices": Smartphone,
};

function resolveIcon(title: string): LucideIcon {
  return STAT_ICON_MAP[title] || LayoutDashboard;
}

function formatCount(count: number | string): string {
  const n = typeof count === "string" ? Number(count) : count;
  if (Number.isNaN(n)) return String(count);
  return n.toLocaleString("en-IN");
}

export default function Dashboard() {
  const currentUser = getCurrentUser();
  const userName = currentUser?.name || "Admin";
  const metaElement = usePageMeta({
    title: "Dashboard",
    description: "Moi Kanakku Admin control panel overview",
  });

  const {
    data: stats = [],
    isLoading,
    isFetching,
    refetch,
    isError,
    error,
  } = useQuery({
    queryKey: ["dashboard", "stats"],
    queryFn: () => dashboardApi.getStats(),
    staleTime: 1000 * 60 * 2,
    refetchOnWindowFocus: false,
  });

  return (
    <>
      {metaElement}
      <div className="space-y-6 animate-fade-in">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <PageTitle
            title="Dashboard"
            icon={LayoutDashboard}
            description={`Welcome back, ${userName}`}
          />
          <Button
            variant="outline"
            size="sm"
            onClick={() => refetch()}
            disabled={isFetching}
            className="gap-2 self-start sm:self-auto"
          >
            {isFetching ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <RefreshCw className="h-4 w-4" />
            )}
            Refresh
          </Button>
        </div>

        {isError && (
          <div className="rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3 text-sm text-destructive">
            {(error as Error)?.message || "Failed to load dashboard stats."}
          </div>
        )}

        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {isLoading
            ? Array.from({ length: 13 }).map((_, i) => (
                <StatCardSkeleton key={i} />
              ))
            : stats.map((stat: DashboardStat, index: number) => (
                <StatCard
                  key={stat.title}
                  title={stat.title}
                  value={formatCount(stat.count)}
                  icon={resolveIcon(stat.title)}
                  colorIndex={index}
                />
              ))}
        </div>
      </div>
    </>
  );
}
