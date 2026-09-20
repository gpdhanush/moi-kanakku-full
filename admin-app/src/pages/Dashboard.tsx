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
  ChevronLeft,
  ChevronRight,
  LogIn,
  MapPin,
  Smartphone,
  UserPlus,
  Loader2,
  type LucideIcon,
} from "lucide-react";
import { LineChart, lineClasses } from "@mui/x-charts/LineChart";
import { PageTitle } from "@/components/ui/page-title";
import { StatCard, StatCardSkeleton } from "@/components/ui/stat-card";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { usePageMeta } from "@/hooks/usePageMeta";
import { dashboardApi, type DashboardStat } from "@/features/dashboard/api";
import { getCurrentUser } from "@/lib/auth";
import { formatDateTime } from "@/lib/formatters";
import { cn } from "@/lib/utils";

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

const MONTH_NAMES = Array.from({ length: 12 }, (_, index) =>
  new Intl.DateTimeFormat("en", { month: "short" }).format(new Date(2020, index, 1))
);

function MonthPicker({
  value,
  onChange,
}: {
  value: string;
  onChange: (month: string) => void;
}) {
  const [open, setOpen] = useState(false);
  const selectedYear = Number(value.slice(0, 4));
  const selectedMonth = Number(value.slice(5, 7)) - 1;
  const currentDate = new Date();
  const currentYear = currentDate.getFullYear();
  const currentMonth = currentDate.getMonth();
  const [displayYear, setDisplayYear] = useState(selectedYear);

  const handleOpenChange = (nextOpen: boolean) => {
    setOpen(nextOpen);
    if (nextOpen) setDisplayYear(selectedYear);
  };

  return (
    <Popover open={open} onOpenChange={handleOpenChange}>
      <PopoverTrigger asChild>
        <Button
          type="button"
          variant="outline"
          className="h-10 min-w-[190px] justify-start gap-2 border-border/70 bg-background/80 px-3 font-medium shadow-sm"
          aria-label="Choose analytics month"
        >
          <CalendarDays className="h-4 w-4 text-primary" />
          {formatMonthLabel(value)}
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-[300px] p-0" align="end">
        <div className="flex items-center justify-between border-b px-3 py-2.5">
          <p className="text-sm font-semibold">Choose month</p>
          <div className="flex items-center gap-1">
            <Button
              type="button"
              variant="ghost"
              size="icon"
              className="h-8 w-8"
              onClick={() => setDisplayYear((year) => year - 1)}
              aria-label="Previous year"
            >
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <span className="min-w-12 text-center text-sm font-semibold tabular-nums">
              {displayYear}
            </span>
            <Button
              type="button"
              variant="ghost"
              size="icon"
              className="h-8 w-8"
              onClick={() => setDisplayYear((year) => year + 1)}
              disabled={displayYear >= currentYear}
              aria-label="Next year"
            >
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        </div>
        <div className="grid grid-cols-3 gap-2 p-3">
          {MONTH_NAMES.map((monthName, monthIndex) => {
            const isSelected = displayYear === selectedYear && monthIndex === selectedMonth;
            const isFutureMonth =
              displayYear > currentYear ||
              (displayYear === currentYear && monthIndex > currentMonth);
            return (
              <button
                key={monthName}
                type="button"
                disabled={isFutureMonth}
                onClick={() => {
                  if (isFutureMonth) return;
                  onChange(`${displayYear}-${String(monthIndex + 1).padStart(2, "0")}`);
                  setOpen(false);
                }}
                className={cn(
                  "rounded-md border px-2 py-2.5 text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground",
                  isFutureMonth && "cursor-not-allowed opacity-40 hover:bg-transparent hover:text-foreground",
                  isSelected && "border-primary bg-primary text-primary-foreground hover:bg-primary/90 hover:text-primary-foreground"
                )}
              >
                {monthName}
              </button>
            );
          })}
        </div>
      </PopoverContent>
    </Popover>
  );
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

  const recentLogins = analytics?.recentLogins ?? [];
  const recentSignups = analytics?.recentSignups ?? [];

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
                    <MonthPicker value={selectedMonth} onChange={setSelectedMonth} />
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
                              <LineChart
                                height={260}
                                xAxis={[{
                                  scaleType: "point",
                                  data: analytics.dailySignups.map((signup) => signup.date.slice(8)),
                                  height: 28,
                                }]}
                                series={[{
                                  data: analytics.dailySignups.map((signup) => signup.count),
                                  label: "New users",
                                  showMark: true,
                                  color: "hsl(var(--chart-2))",
                                }]}
                                yAxis={[{ width: 50, min: 0 }]}
                                margin={{ top: 8, right: 16, left: 8, bottom: 8 }}
                                sx={{ width: "100%" }}
                              />
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
                              <LineChart
                                height={260}
                                xAxis={[{
                                  scaleType: "point",
                                  data: analytics.cityBreakdown.map((city) => city.city),
                                  height: 44,
                                }]}
                                series={[{
                                  data: analytics.cityBreakdown.map((city) => city.count),
                                  label: "Users",
                                  showMark: true,
                                  color: "hsl(var(--chart-4))",
                                }]}
                                yAxis={[{ width: 50, min: 0 }]}
                                margin={{ top: 8, right: 16, left: 8, bottom: 8 }}
                                sx={{
                                  width: "100%",
                                  [`& .${lineClasses.line}`]: {
                                    strokeDasharray: "6 4",
                                    strokeWidth: 2,
                                  },
                                  [`& .${lineClasses.mark}`]: {
                                    strokeWidth: 2,
                                  },
                                }}
                              />
                            ) : (
                              <div className="flex h-[260px] items-center justify-center text-sm text-muted-foreground">
                                No city data available.
                              </div>
                            )}
                          </CardContent>
                        </Card>
                      </div>

                      <div className="grid gap-4 xl:grid-cols-2">
                        <Card>
                          <CardHeader>
                            <CardTitle className="flex items-center gap-2">
                              <LogIn className="h-5 w-5 text-primary" />
                              Recent user logins
                            </CardTitle>
                            <CardDescription>Latest eight recorded user activities</CardDescription>
                          </CardHeader>
                          <CardContent>
                            {recentLogins.length > 0 ? (
                              <div className="grid gap-3 sm:grid-cols-2">
                                {recentLogins.map((user) => (
                                  <button
                                    key={user.id || `${user.name}-${user.lastLogin}`}
                                    type="button"
                                    disabled={!user.id}
                                    onClick={() => user.id && navigate(`/users/${user.id}`)}
                                    className="rounded-md border bg-muted/20 p-3 text-left transition-colors hover:border-primary/50 hover:bg-accent disabled:cursor-default disabled:hover:border-border disabled:hover:bg-muted/20"
                                  >
                                    <p className="truncate font-medium">{user.name}</p>
                                    <p className="truncate text-xs text-muted-foreground">{user.email || "No email"}</p>
                                    <p className="mt-2 flex items-center gap-1 text-xs text-muted-foreground">
                                      <MapPin className="h-3.5 w-3.5" />
                                      {user.city || "Unknown city"}
                                    </p>
                                    <p className="mt-1 text-xs text-muted-foreground">{formatDateTime(user.lastLogin)}</p>
                                  </button>
                                ))}
                              </div>
                            ) : (
                              <p className="text-sm text-muted-foreground">No recent login activity found.</p>
                            )}
                          </CardContent>
                        </Card>

                        <Card>
                          <CardHeader>
                            <CardTitle className="flex items-center gap-2">
                              <UserPlus className="h-5 w-5 text-primary" />
                              Recent user signups
                            </CardTitle>
                            <CardDescription>Latest eight registered users</CardDescription>
                          </CardHeader>
                          <CardContent>
                            {recentSignups.length > 0 ? (
                              <div className="grid gap-3 sm:grid-cols-2">
                                {recentSignups.map((user) => (
                                  <button
                                    key={user.id || `${user.name}-${user.createdAt}`}
                                    type="button"
                                    disabled={!user.id}
                                    onClick={() => user.id && navigate(`/users/${user.id}`)}
                                    className="rounded-md border bg-muted/20 p-3 text-left transition-colors hover:border-primary/50 hover:bg-accent disabled:cursor-default disabled:hover:border-border disabled:hover:bg-muted/20"
                                  >
                                    <p className="truncate font-medium">{user.name}</p>
                                    <p className="truncate text-xs text-muted-foreground">{user.email || "No email"}</p>
                                    <p className="mt-2 flex items-center gap-1 text-xs text-muted-foreground">
                                      <MapPin className="h-3.5 w-3.5" />
                                      {user.city || "Unknown city"}
                                    </p>
                                    <p className="mt-1 text-xs text-muted-foreground">{formatDateTime(user.createdAt)}</p>
                                  </button>
                                ))}
                              </div>
                            ) : (
                              <p className="text-sm text-muted-foreground">No recent signups found.</p>
                            )}
                          </CardContent>
                        </Card>
                      </div>
                    </>
                  ) : null}
        </section>
      </div>
    </>
  );
}
