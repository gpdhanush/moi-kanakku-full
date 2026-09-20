import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
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
  CalendarDays,
  LogIn,
  MapPin,
  Smartphone,
  UserPlus,
  Loader2,
  type LucideIcon,
} from "lucide-react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { PageTitle } from "@/components/ui/page-title";
import { StatCard, StatCardSkeleton } from "@/components/ui/stat-card";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { usePageMeta } from "@/hooks/usePageMeta";
import { dashboardApi, type DashboardStat } from "@/features/dashboard/api";
import { getCurrentUser } from "@/lib/auth";
import { formatDateTime } from "@/lib/formatters";

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

const DASHBOARD_STAT_TITLES = [
  "Total Users",
  "Total Transactions",
  "Total Notifications",
  "Total Feedbacks",
  "Total User Devices",
] as const;

function resolveIcon(title: string): LucideIcon {
  return STAT_ICON_MAP[title] || LayoutDashboard;
}

function formatCount(count: number | string): string {
  const n = typeof count === "string" ? Number(count) : count;
  if (Number.isNaN(n)) return String(count);
  return n.toLocaleString("en-IN");
}

function getCurrentMonth(): string {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
}

function formatMonthLabel(month: string): string {
  const date = new Date(`${month}-01T00:00:00`);
  return Number.isNaN(date.getTime())
    ? month
    : date.toLocaleDateString("en-IN", { month: "long", year: "numeric" });
}

export default function Dashboard() {
  const navigate = useNavigate();
  const [selectedMonth, setSelectedMonth] = useState(getCurrentMonth);
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

  const {
    data: analytics,
    isLoading: isAnalyticsLoading,
    isFetching: isAnalyticsFetching,
    isError: isAnalyticsError,
  } = useQuery({
    queryKey: ["dashboard", "analytics", selectedMonth],
    queryFn: () => dashboardApi.getAnalytics(selectedMonth),
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
            disabled={isFetching || isAnalyticsFetching}
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

        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
          {isLoading
            ? Array.from({ length: DASHBOARD_STAT_TITLES.length }).map((_, i) => (
                <StatCardSkeleton key={i} />
              ))
            : stats
                .filter((stat: DashboardStat) =>
                  DASHBOARD_STAT_TITLES.includes(
                    stat.title as (typeof DASHBOARD_STAT_TITLES)[number]
                  )
                )
                .map((stat: DashboardStat, index: number) => (
                  <StatCard
                    key={stat.title}
                    title={stat.title}
                    value={formatCount(stat.count)}
                    icon={resolveIcon(stat.title)}
                    colorIndex={index}
                    onClick={
                      stat.title === "Total Users"
                        ? () => navigate("/users")
                        : undefined
                    }
                  />
                ))}
        </div>

        <section className="space-y-4" aria-labelledby="user-analytics-title">
                  <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
                    <div>
                      <h2 id="user-analytics-title" className="text-xl font-semibold tracking-tight">
                        User analytics
                      </h2>
                      <p className="text-sm text-muted-foreground">
                        Growth, activity, and location insights for {formatMonthLabel(selectedMonth)}.
                      </p>
                    </div>
                    <label className="flex items-center gap-2 text-sm font-medium">
                      <CalendarDays className="h-4 w-4 text-muted-foreground" />
                      <span className="sr-only">Analytics month</span>
                      <Input
                        type="month"
                        value={selectedMonth}
                        onChange={(event) => setSelectedMonth(event.target.value)}
                        className="w-auto"
                      />
                    </label>
                  </div>

                  {isAnalyticsError && (
                    <div className="rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3 text-sm text-destructive">
                      Failed to load user analytics.
                    </div>
                  )}

                  {isAnalyticsLoading ? (
                    <div className="grid gap-4 md:grid-cols-3">
                      {Array.from({ length: 3 }).map((_, index) => (
                        <div key={index} className="h-28 animate-pulse rounded-lg border-2 bg-muted/40" />
                      ))}
                    </div>
                  ) : analytics ? (
                    <>
                      <div className="grid gap-4 md:grid-cols-3">
                        <StatCard
                          title="New users this month"
                          value={formatCount(analytics.summary.monthSignups)}
                          icon={UserPlus}
                          color="emerald"
                          description={`${analytics.summary.changePercent >= 0 ? "+" : ""}${analytics.summary.changePercent}% vs previous month`}
                        />
                        <StatCard
                          title="New users today"
                          value={formatCount(analytics.summary.todaySignups)}
                          icon={Calendar}
                          color="amber"
                          description="Registered since midnight"
                        />
                        <StatCard
                          title="Previous month"
                          value={formatCount(analytics.summary.previousMonthSignups)}
                          icon={TrendingUp}
                          color="cyan"
                          description={formatMonthLabel(analytics.previousMonth)}
                        />
                      </div>

                      <div className="grid gap-4 xl:grid-cols-[1.35fr_1fr]">
                        <Card>
                          <CardHeader>
                            <CardTitle>Signup trend</CardTitle>
                            <CardDescription>Daily new users in the selected month</CardDescription>
                          </CardHeader>
                          <CardContent>
                            {analytics.dailySignups.length > 0 ? (
                              <ResponsiveContainer width="100%" height={260}>
                                <BarChart data={analytics.dailySignups} margin={{ top: 8, right: 8, left: -20, bottom: 0 }}>
                                  <CartesianGrid strokeDasharray="3 3" vertical={false} />
                                  <XAxis dataKey="date" tickFormatter={(value) => String(value).slice(8)} />
                                  <YAxis allowDecimals={false} />
                                  <Tooltip labelFormatter={(value) => `Date: ${value}`} />
                                  <Bar dataKey="count" name="New users" fill="hsl(var(--chart-2))" radius={[4, 4, 0, 0]} />
                                </BarChart>
                              </ResponsiveContainer>
                            ) : (
                              <div className="flex h-[260px] items-center justify-center text-sm text-muted-foreground">
                                No signups recorded for this month.
                              </div>
                            )}
                          </CardContent>
                        </Card>

                        <Card>
                          <CardHeader>
                            <CardTitle>Users by city</CardTitle>
                            <CardDescription>Top locations across active users</CardDescription>
                          </CardHeader>
                          <CardContent>
                            {analytics.cityBreakdown.length > 0 ? (
                              <ResponsiveContainer width="100%" height={260}>
                                <BarChart data={analytics.cityBreakdown} layout="vertical" margin={{ top: 8, right: 8, left: 8, bottom: 0 }}>
                                  <CartesianGrid strokeDasharray="3 3" horizontal={false} />
                                  <XAxis type="number" allowDecimals={false} />
                                  <YAxis type="category" dataKey="city" width={90} tick={{ fontSize: 12 }} />
                                  <Tooltip />
                                  <Bar dataKey="count" name="Users" fill="hsl(var(--chart-4))" radius={[0, 4, 4, 0]} />
                                </BarChart>
                              </ResponsiveContainer>
                            ) : (
                              <div className="flex h-[260px] items-center justify-center text-sm text-muted-foreground">
                                No city data available.
                              </div>
                            )}
                          </CardContent>
                        </Card>
                      </div>

                      <Card>
                        <CardHeader>
                          <CardTitle className="flex items-center gap-2">
                            <LogIn className="h-5 w-5 text-primary" />
                            Recent user logins
                          </CardTitle>
                          <CardDescription>Users with the latest recorded activity</CardDescription>
                        </CardHeader>
                        <CardContent>
                          {analytics.recentLogins.length > 0 ? (
                            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
                              {analytics.recentLogins.map((user) => (
                                <div key={user.id || `${user.name}-${user.lastLogin}`} className="rounded-md border bg-muted/20 p-3">
                                  <p className="truncate font-medium">{user.name}</p>
                                  <p className="truncate text-xs text-muted-foreground">{user.email || "No email"}</p>
                                  <p className="mt-2 flex items-center gap-1 text-xs text-muted-foreground">
                                    <MapPin className="h-3.5 w-3.5" />
                                    {user.city || "Unknown city"}
                                  </p>
                                  <p className="mt-1 text-xs text-muted-foreground">{formatDateTime(user.lastLogin)}</p>
                                </div>
                              ))}
                            </div>
                          ) : (
                            <p className="text-sm text-muted-foreground">No recent login activity found.</p>
                          )}
                        </CardContent>
                      </Card>
                    </>
                  ) : null}
        </section>
      </div>
    </>
  );
}
