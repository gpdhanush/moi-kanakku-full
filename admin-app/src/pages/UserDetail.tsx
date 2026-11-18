import { useEffect, useMemo, useState, type ReactNode } from "react";
import { useNavigate, useParams, useSearchParams, Link } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Mail,
  MailCheck,
  MapPin,
  Phone,
  CalendarDays,
  Bell,
  Clock3,
  Loader2,
  UserCheck,
  UserX,
  ShieldBan,
  Send,
  Trash2,
  Download,
  ChevronLeft,
  ChevronRight,
  MoreHorizontal,
  Users,
  PartyPopper,
  ArrowLeftRight,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { DataSection } from "@/components/ui/data-section";
import { ImageThumb } from "@/components/ui/image-thumb";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
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
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { usePageMeta } from "@/hooks/usePageMeta";
import { toast } from "@/hooks/use-toast";
import { usersApi, type UserDevice } from "@/features/users/api";
import {
  useUserFunctionsQuery,
  useUserPersonsQuery,
  useUserQuery,
  useUserTransactionsQuery,
} from "@/features/users/queries";
import {
  TransactionTypeBadge,
  ViewTransactionButton,
} from "@/features/users/detail-ui";
import {
  functionPath,
  personFullName,
  personPath,
  transactionPersonName,
} from "@/features/users/detail-utils";
import type { PersonItem } from "@/features/persons/api";
import type { TransactionFunctionItem } from "@/features/transaction-functions/api";
import type { TransactionItem } from "@/features/transactions/api";
import {
  upcomingFunctionsApi,
  type UpcomingFunctionItem,
} from "@/features/upcoming-functions/api";
import {
  notificationsApi,
  type NotificationItem,
} from "@/features/notifications/api";
import {
  adminNotificationsApi,
  emailApi,
  type BulkEmailType,
  type BulkNotificationType,
} from "@/features/messaging/api";
import { auditLogsApi } from "@/features/audit-logs/api";
import {
  displayValue,
  formatAmount,
  formatDateOnly,
  formatDateTime,
  formatLabel,
  formatAppStatus,
  resolveImageUrl,
} from "@/lib/formatters";
import { cn, toNameCase } from "@/lib/utils";
import { exportUserDetailsToPDF } from "@/utils/userDetailsPdf";

const EMAIL_TYPES: { value: BulkEmailType; label: string }[] = [
  { value: "notification", label: "Notification" },
  { value: "announcement", label: "Announcement" },
  { value: "custom", label: "Custom" },
];

const NOTIFICATION_TYPES: { value: BulkNotificationType; label: string }[] = [
  { value: "moi", label: "moi" },
  { value: "moiOut", label: "moiOut" },
  { value: "function", label: "function" },
  { value: "account", label: "account" },
  { value: "settings", label: "settings" },
  { value: "general", label: "general" },
];

type Tone = "success" | "warning" | "danger" | "info" | "neutral";

const TONE_CLASSES: Record<Tone, { chip: string; dot: string }> = {
  success: {
    chip: "bg-emerald-500/10 text-emerald-800 ring-emerald-600/20 dark:text-emerald-300",
    dot: "bg-emerald-500",
  },
  warning: {
    chip: "bg-amber-500/10 text-amber-800 ring-amber-600/25 dark:text-amber-300",
    dot: "bg-amber-500",
  },
  danger: {
    chip: "bg-rose-500/10 text-rose-700 ring-rose-600/20 dark:text-rose-300",
    dot: "bg-rose-500",
  },
  info: {
    chip: "bg-sky-500/10 text-sky-800 ring-sky-600/20 dark:text-sky-300",
    dot: "bg-sky-500",
  },
  neutral: {
    chip: "bg-muted text-muted-foreground ring-border",
    dot: "bg-muted-foreground/60",
  },
};

function appStatusTone(value?: string | null): Tone {
  const status = String(value || "UNKNOWN").toUpperCase();
  if (status === "ACTIVE") return "success";
  if (status === "INACTIVE") return "warning";
  if (status === "LIKELY_UNINSTALLED") return "danger";
  return "neutral";
}

function StatusChip({ tone, children }: { tone: Tone; children: ReactNode }) {
  const classes = TONE_CLASSES[tone];
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium ring-1 ring-inset",
        classes.chip,
      )}
    >
      <span aria-hidden className={cn("h-1.5 w-1.5 rounded-full", classes.dot)} />
      {children}
    </span>
  );
}

function Panel({
  title,
  description,
  action,
  children,
}: {
  title: string;
  description?: string;
  action?: ReactNode;
  children: ReactNode;
}) {
  return (
    <section className="min-w-0 rounded-2xl border border-border/60 bg-card p-5 shadow-sm">
      <div className="mb-3 flex items-start justify-between gap-3">
        <div className="min-w-0">
          <h2 className="text-[15px] font-semibold tracking-tight">{title}</h2>
          {description && (
            <p className="mt-0.5 text-sm text-muted-foreground">{description}</p>
          )}
        </div>
        {action}
      </div>
      {children}
    </section>
  );
}

function InfoList({ children }: { children: ReactNode }) {
  return <dl className="divide-y divide-border/60">{children}</dl>;
}

function InfoRow({ label, value }: { label: string; value: ReactNode }) {
  return (
    <div className="grid grid-cols-[minmax(0,2fr)_minmax(0,3fr)] gap-4 py-2.5">
      <dt className="text-sm text-muted-foreground">{label}</dt>
      <dd className="min-w-0 break-words text-sm font-medium text-foreground">
        {value}
      </dd>
    </div>
  );
}

function MiniField({ label, value }: { label: string; value: ReactNode }) {
  return (
    <div className="min-w-0">
      <dt className="text-xs text-muted-foreground">{label}</dt>
      <dd className="mt-0.5 break-words font-medium">{value}</dd>
    </div>
  );
}

function ContactItem({
  icon,
  label,
  value,
}: {
  icon: ReactNode;
  label: string;
  value: ReactNode;
}) {
  return (
    <div className="flex min-w-0 items-start gap-3 border-b border-border/60 px-6 py-4 last:border-b-0 sm:[&:nth-child(n+3)]:border-b-0 sm:[&:nth-child(odd)]:border-r lg:border-b-0 lg:border-r lg:last:border-r-0">
      <span className="mt-0.5 text-muted-foreground [&>svg]:h-4 [&>svg]:w-4">
        {icon}
      </span>
      <div className="min-w-0">
        <dt className="text-xs text-muted-foreground">{label}</dt>
        <dd className="mt-0.5 truncate text-sm font-medium" title={typeof value === "string" ? value : undefined}>
          {value}
        </dd>
      </div>
    </div>
  );
}

const TAB_ITEMS = [
  { value: "overview", label: "Overview" },
  { value: "persons", label: "Persons" },
  { value: "functions", label: "Functions" },
  { value: "transactions", label: "Transactions" },
  { value: "upcoming", label: "Upcoming" },
  { value: "notifications", label: "Notifications" },
] as const;

type TabValue = (typeof TAB_ITEMS)[number]["value"];

export default function UserDetail() {
  const { userId = "" } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [searchParams, setSearchParams] = useSearchParams();
  const requestedTab = searchParams.get("tab");
  const activeTab: TabValue = TAB_ITEMS.some((t) => t.value === requestedTab)
    ? (requestedTab as TabValue)
    : "overview";
  const handleTabChange = (value: string) => {
    setSearchParams(
      (prev) => {
        const next = new URLSearchParams(prev);
        if (value === "overview") next.delete("tab");
        else next.set("tab", value);
        return next;
      },
      { replace: true },
    );
  };
  const [blockOpen, setBlockOpen] = useState(false);
  const [notificationsPage, setNotificationsPage] = useState(1);
  const [notificationsLimit, setNotificationsLimit] = useState(10);
  const [statusDialogOpen, setStatusDialogOpen] = useState(false);
  const [softDeleteOpen, setSoftDeleteOpen] = useState(false);
  const [permanentDeleteOpen, setPermanentDeleteOpen] = useState(false);
  const [permanentConfirmName, setPermanentConfirmName] = useState("");
  const [emailOpen, setEmailOpen] = useState(false);
  const [verifyEmailOpen, setVerifyEmailOpen] = useState(false);
  const [emailSubject, setEmailSubject] = useState("");
  const [emailBody, setEmailBody] = useState("");
  const [emailType, setEmailType] = useState<BulkEmailType>("notification");
  const [notificationOpen, setNotificationOpen] = useState(false);
  const [notificationTitle, setNotificationTitle] = useState("");
  const [notificationBody, setNotificationBody] = useState("");
  const [notificationType, setNotificationType] =
    useState<BulkNotificationType>("general");
  const [isExporting, setIsExporting] = useState(false);

  const userQuery = useUserQuery(userId);
  const personsQuery = useUserPersonsQuery(userId);
  const functionsQuery = useUserFunctionsQuery(userId);
  const transactionsQuery = useUserTransactionsQuery(userId);
  const upcomingFunctionsQuery = useQuery({
    queryKey: ["admin", "upcoming-functions", userId],
    queryFn: () => upcomingFunctionsApi.list(userId),
    enabled: !!userId,
    staleTime: 60_000,
  });

  const notificationsQuery = useQuery({
    queryKey: [
      "admin",
      "notifications",
      userId,
      notificationsPage,
      notificationsLimit,
    ],
    queryFn: () =>
      notificationsApi.listByUser(userId, {
        page: notificationsPage,
        limit: notificationsLimit,
      }),
    enabled: !!userId,
    staleTime: 60_000,
    placeholderData: (previous) => previous,
  });

  const activityQuery = useQuery({
    queryKey: ["admin", "audit-logs", "user", userId],
    queryFn: () =>
      auditLogsApi.list({
        page: 1,
        limit: 10,
        userId,
      }),
    enabled: !!userId,
    staleTime: 30_000,
  });

  const notificationsUnread = notificationsQuery.data?.unreadCount ?? 0;
  const notificationsRows = notificationsQuery.data?.data ?? [];
  const notificationsTotal = notificationsQuery.data?.totalCount ?? 0;

  useEffect(() => {
    if (
      notificationsQuery.isSuccess &&
      notificationsPage > 1 &&
      notificationsRows.length === 0
    ) {
      setNotificationsPage((p) => Math.max(1, p - 1));
    }
  }, [
    notificationsQuery.isSuccess,
    notificationsPage,
    notificationsRows.length,
  ]);

  const user = userQuery.data;
  const metaElement = usePageMeta({
    title: user?.name ? `User: ${toNameCase(user.name)}` : "User Details",
    description: "User profile and related records",
  });

  const displayName = toNameCase(user?.name);
  const initials = useMemo(
    () =>
      (user?.name?.trim() || "U")
        .split(" ")
        .map((n) => n[0])
        .join("")
        .slice(0, 2)
        .toUpperCase(),
    [user?.name],
  );

  const isActive = (user?.status || "").toUpperCase() === "ACTIVE";
  const isDeleted = (user?.status || "").toUpperCase() === "DELETED";
  const isBlocked = (user?.status || "").toUpperCase() === "BLOCKED";
  const isVerified = Boolean(Number(user?.is_verified));
  const deviceRows: UserDevice[] =
    user?.devices && user.devices.length > 0
      ? user.devices
      : user?.device
        ? [user.device]
        : [];
  const profileImage = resolveImageUrl(
    user?.profile?.profile_image_url || null,
  );

  const personsCount =
    personsQuery.data?.count ?? personsQuery.data?.data.length ?? 0;
  const functionsCount =
    functionsQuery.data?.count ?? functionsQuery.data?.data.length ?? 0;
  const transactionsCount =
    transactionsQuery.data?.count ?? transactionsQuery.data?.data.length ?? 0;
  const upcomingFunctionsCount =
    upcomingFunctionsQuery.data?.count ??
    upcomingFunctionsQuery.data?.data.length ??
    0;

  const exportDataLoading =
    userQuery.isLoading ||
    personsQuery.isLoading ||
    functionsQuery.isLoading ||
    transactionsQuery.isLoading ||
    upcomingFunctionsQuery.isLoading;
  const exportDataError =
    userQuery.isError ||
    personsQuery.isError ||
    functionsQuery.isError ||
    transactionsQuery.isError ||
    upcomingFunctionsQuery.isError;

  const addressLines = [
    user?.profile?.address_line1,
    user?.profile?.address_line2,
    [user?.profile?.city, user?.profile?.state, user?.profile?.postal_code]
      .filter(Boolean)
      .join(", "),
    user?.profile?.country,
  ]
    .map((line) => String(line ?? "").trim())
    .filter(Boolean);

  const accountTone: Tone = isActive
    ? "success"
    : isDeleted
      ? "neutral"
      : isBlocked
        ? "danger"
        : "warning";
  const appTone = appStatusTone(user?.app_status);

  const tabCounts: Record<TabValue, number | null> = {
    overview: null,
    persons: personsQuery.isLoading ? null : personsCount,
    functions: functionsQuery.isLoading ? null : functionsCount,
    transactions: transactionsQuery.isLoading ? null : transactionsCount,
    upcoming: upcomingFunctionsQuery.isLoading ? null : upcomingFunctionsCount,
    notifications: notificationsQuery.isLoading ? null : notificationsTotal,
  };

  const locationLabel =
    [user?.profile?.city, user?.profile?.state].filter(Boolean).join(", ") ||
    "N/A";

  const resetEmailForm = () => {
    setEmailSubject("");
    setEmailBody("");
    setEmailType("notification");
  };

  const resetNotificationForm = () => {
    setNotificationTitle("");
    setNotificationBody("");
    setNotificationType("general");
  };

  const statusMutation = useMutation({
    mutationFn: (status: "ACTIVE" | "INACTIVE" | "BLOCKED") =>
      status === "ACTIVE" && String(user?.status).toUpperCase() === "DELETED"
        ? usersApi.restore(userId)
        : usersApi.updateStatus(userId, status),
    onSuccess: (result, status) => {
      toast({
        title:
          status === "INACTIVE"
            ? "User deactivated"
            : status === "BLOCKED"
              ? "User blocked"
              : "User activated",
        description:
          result.message ||
          (status === "INACTIVE"
            ? "This user cannot log in or reset password until reactivated."
            : status === "BLOCKED"
              ? "This user cannot access the mobile app until unblocked."
              : "This user can log in from the mobile app."),
      });
      setStatusDialogOpen(false);
      setBlockOpen(false);
      queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
    },
    onError: (err: Error) => {
      toast({
        title: "Status update failed",
        description: err.message || "Unable to update user status.",
        variant: "destructive",
      });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (mode: "soft" | "permanent") =>
      usersApi.deleteUser(userId, mode),
    onSuccess: (result, mode) => {
      toast({
        title:
          mode === "permanent"
            ? "User permanently deleted"
            : "User soft deleted",
        description:
          result.message ||
          (mode === "permanent"
            ? "The user and related records were removed."
            : "The account was marked deleted. Related records were kept."),
      });
      setSoftDeleteOpen(false);
      setPermanentDeleteOpen(false);
      setPermanentConfirmName("");
      queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
      navigate("/users");
    },
    onError: (err: Error) => {
      toast({
        title: "Delete failed",
        description: err.message || "Unable to delete this user.",
        variant: "destructive",
      });
    },
  });

  const verifyEmailMutation = useMutation({
    mutationFn: () => emailApi.sendVerifyEmail(userId),
    onSuccess: (result) => {
      toast({
        title: "Verification email sent",
        description:
          result.message ||
          `A verification link was sent to ${result.sent_to || user?.email || "the user"}. Ask them to check Inbox and Spam.`,
      });
      setVerifyEmailOpen(false);
      queryClient.invalidateQueries({ queryKey: ["admin", "users", userId] });
    },
    onError: (err: Error) => {
      toast({
        title: "Failed to send verification email",
        description: err.message || "Unable to send the verification email.",
        variant: "destructive",
      });
    },
  });

  const emailMutation = useMutation({
    mutationFn: () =>
      emailApi.sendBulk({
        userIds: [userId],
        subject: emailSubject.trim(),
        body: emailBody.trim(),
        type: emailType,
      }),
    onSuccess: (result) => {
      toast({
        title: "Email sent",
        description:
          result.message ||
          `Email sent to ${user?.name || user?.email || "user"}.`,
      });
      setEmailOpen(false);
      resetEmailForm();
    },
    onError: (err: Error) => {
      toast({
        title: "Failed to send email",
        description: err.message || "Something went wrong.",
        variant: "destructive",
      });
    },
  });

  const notificationMutation = useMutation({
    mutationFn: () =>
      adminNotificationsApi.sendBulk({
        userIds: [userId],
        title: notificationTitle.trim(),
        body: notificationBody.trim(),
        type: notificationType,
      }),
    onSuccess: (result) => {
      toast({
        title: "Notification sent",
        description:
          result.message || `Notification sent to ${user?.name || "user"}.`,
      });
      setNotificationOpen(false);
      resetNotificationForm();
      queryClient.invalidateQueries({
        queryKey: ["admin", "notifications", userId],
      });
    },
    onError: (err: Error) => {
      toast({
        title: "Failed to send notification",
        description: err.message || "Something went wrong.",
        variant: "destructive",
      });
    },
  });

  const handleSendEmail = () => {
    if (!emailSubject.trim() || !emailBody.trim()) {
      toast({
        title: "Missing fields",
        description: "Subject and body are required.",
        variant: "destructive",
      });
      return;
    }
    emailMutation.mutate();
  };

  const handleSendNotification = () => {
    if (!notificationTitle.trim() || !notificationBody.trim()) {
      toast({
        title: "Missing fields",
        description: "Title and body are required.",
        variant: "destructive",
      });
      return;
    }
    notificationMutation.mutate();
  };

  const handleExportUserDetails = (watermark: boolean) => {
    if (!user || exportDataLoading || exportDataError) {
      toast({
        title: "Export unavailable",
        description: exportDataError
          ? "Wait for all user details to load successfully before exporting."
          : "User details are still loading. Please try again shortly.",
        variant: "destructive",
      });
      return;
    }

    try {
      setIsExporting(true);
      exportUserDetailsToPDF(
        {
          user,
          persons: personsQuery.data?.data ?? [],
          functions: functionsQuery.data?.data ?? [],
          transactions: transactionsQuery.data?.data ?? [],
          upcomingFunctions: upcomingFunctionsQuery.data?.data ?? [],
        },
        { watermark },
      );
      toast({
        title: "Export ready",
        description: `The printable PDF report ${watermark ? "with" : "without"} watermark opened in a new window.`,
      });
    } catch (error) {
      toast({
        title: "Export failed",
        description:
          error instanceof Error
            ? error.message
            : "Unable to create the PDF report.",
        variant: "destructive",
      });
    } finally {
      setIsExporting(false);
    }
  };

  if (!userId) {
    return (
      <div className="rounded-lg border border-destructive/30 bg-destructive/5 p-4 text-sm text-destructive">
        Invalid user id.
      </div>
    );
  }

  return (
    <>
      {metaElement}
      <div className="mx-auto max-w-7xl space-y-6 animate-fade-in">
        {/* Top bar: back navigation + actions */}
        <div className="flex flex-wrap items-center justify-between gap-3">
          <Button
            size="sm"
            variant="ghost"
            className="-ml-2 h-9 gap-1 text-muted-foreground hover:text-foreground"
            onClick={() => navigate("/users")}
          >
            <ChevronLeft className="h-4 w-4" />
            Users
          </Button>
          {user && (
            <div className="flex flex-wrap items-center gap-2">
              <Button
                size="sm"
                variant="outline"
                className="h-9 gap-2"
                onClick={() => setEmailOpen(true)}
              >
                <Mail className="h-4 w-4" />
                Send Email
              </Button>
              <Button
                size="sm"
                className="h-9 gap-2"
                onClick={() => setNotificationOpen(true)}
              >
                <Bell className="h-4 w-4" />
                Send Notification
              </Button>
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button
                    size="sm"
                    variant="outline"
                    className="h-9 w-9 p-0"
                    aria-label="More actions"
                    title="More actions"
                    disabled={
                      statusMutation.isPending || deleteMutation.isPending
                    }
                  >
                    <MoreHorizontal className="h-4 w-4" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" className="w-60">
                  {!isVerified && (
                    <>
                      <DropdownMenuItem
                        className="gap-2"
                        disabled={verifyEmailMutation.isPending}
                        onSelect={() => setVerifyEmailOpen(true)}
                      >
                        <MailCheck className="h-4 w-4" />
                        Send Verification Email
                      </DropdownMenuItem>
                      <DropdownMenuSeparator />
                    </>
                  )}
                  <DropdownMenuLabel className="text-xs font-medium text-muted-foreground">
                    Export
                  </DropdownMenuLabel>
                  <DropdownMenuItem
                    className="gap-2"
                    disabled={
                      isExporting || exportDataLoading || exportDataError
                    }
                    onSelect={() => handleExportUserDetails(true)}
                  >
                    <Download className="h-4 w-4" />
                    PDF with Watermark
                  </DropdownMenuItem>
                  <DropdownMenuItem
                    className="gap-2"
                    disabled={
                      isExporting || exportDataLoading || exportDataError
                    }
                    onSelect={() => handleExportUserDetails(false)}
                  >
                    <Download className="h-4 w-4" />
                    PDF without Watermark
                  </DropdownMenuItem>
                  <DropdownMenuSeparator />
                  <DropdownMenuLabel className="text-xs font-medium text-muted-foreground">
                    Account
                  </DropdownMenuLabel>
                  <DropdownMenuItem
                    className="gap-2"
                    onSelect={() => setStatusDialogOpen(true)}
                  >
                    {isActive ? (
                      <UserX className="h-4 w-4" />
                    ) : (
                      <UserCheck className="h-4 w-4" />
                    )}
                    {isDeleted
                      ? "Restore User"
                      : isActive
                        ? "Deactivate User"
                        : "Activate User"}
                  </DropdownMenuItem>
                  {!isDeleted && !isBlocked && (
                    <DropdownMenuItem
                      className="gap-2"
                      onSelect={() => setBlockOpen(true)}
                    >
                      <ShieldBan className="h-4 w-4" />
                      Block User
                    </DropdownMenuItem>
                  )}
                  <DropdownMenuSeparator />
                  {!isDeleted && (
                    <DropdownMenuItem
                      className="gap-2"
                      onSelect={() => setSoftDeleteOpen(true)}
                    >
                      <Trash2 className="h-4 w-4" />
                      Soft Delete
                    </DropdownMenuItem>
                  )}
                  <DropdownMenuItem
                    className="gap-2 text-destructive focus:text-destructive"
                    onSelect={() => {
                      setPermanentConfirmName("");
                      setPermanentDeleteOpen(true);
                    }}
                  >
                    <Trash2 className="h-4 w-4" />
                    Delete Permanently
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          )}
        </div>

        {userQuery.isError && (
          <div className="rounded-xl border border-destructive/30 bg-destructive/5 px-4 py-3 text-sm text-destructive">
            {(userQuery.error as Error)?.message ||
              "Failed to load user details."}
          </div>
        )}

        {/* Identity header */}
        <section className="overflow-hidden rounded-2xl border border-border/60 bg-card shadow-sm">
          {userQuery.isLoading ? (
            <div className="flex items-center gap-5 p-6">
              <div className="h-[72px] w-[72px] animate-pulse rounded-full bg-muted" />
              <div className="flex-1 space-y-3">
                <div className="h-7 w-56 animate-pulse rounded-md bg-muted" />
                <div className="h-4 w-80 animate-pulse rounded-md bg-muted" />
              </div>
            </div>
          ) : (
            <>
              <div className="flex flex-col gap-5 p-6 sm:flex-row sm:items-center">
                <Avatar className="h-[72px] w-[72px] shrink-0">
                  <AvatarImage src={profileImage} alt="" />
                  <AvatarFallback className="bg-primary/10 text-2xl font-semibold text-primary">
                    {initials}
                  </AvatarFallback>
                </Avatar>
                <div className="min-w-0 flex-1">
                  <h1 className="truncate text-2xl font-semibold tracking-tight">
                    {displayName || "—"}
                  </h1>
                  <p className="mt-1 text-sm text-muted-foreground">
                    Member since {formatDateOnly(user?.create_date)}
                    {user?.signup_type
                      ? ` · Signed up with ${formatLabel(user.signup_type)}`
                      : ""}
                  </p>
                  <div className="mt-3 flex flex-wrap gap-2">
                    <StatusChip tone={accountTone}>
                      {formatLabel(user?.status) || "Unknown"}
                    </StatusChip>
                    <StatusChip tone={appTone}>
                      App {formatAppStatus(user?.app_status).toLowerCase()}
                    </StatusChip>
                    <StatusChip tone={isVerified ? "success" : "warning"}>
                      {isVerified ? "Email verified" : "Email not verified"}
                    </StatusChip>
                  </div>
                </div>
              </div>
              <dl className="grid border-t border-border/60 sm:grid-cols-2 lg:grid-cols-4">
                <ContactItem
                  icon={<Mail />}
                  label="Email"
                  value={displayValue(user?.email)}
                />
                <ContactItem
                  icon={<Phone />}
                  label="Mobile"
                  value={displayValue(user?.mobile)}
                />
                <ContactItem
                  icon={<MapPin />}
                  label="Location"
                  value={locationLabel}
                />
                <ContactItem
                  icon={<Clock3 />}
                  label="Last seen"
                  value={formatDateTime(user?.last_seen_at)}
                />
              </dl>
            </>
          )}
        </section>

        {/* Sections */}
        <Tabs value={activeTab} onValueChange={handleTabChange}>
          <TabsList className="h-auto w-full justify-start gap-1 overflow-x-auto rounded-none border-b border-border/60 bg-transparent p-0">
            {TAB_ITEMS.map((item) => {
              const count = tabCounts[item.value];
              return (
                <TabsTrigger
                  key={item.value}
                  value={item.value}
                  className="group -mb-px gap-2 rounded-none border-b-2 border-transparent px-3 pb-3 pt-2 text-sm hover:bg-transparent hover:text-foreground data-[state=active]:border-primary data-[state=active]:bg-transparent data-[state=inactive]:bg-transparent data-[state=active]:shadow-none"
                >
                  {item.label}
                  {count != null && (
                    <span className="rounded-full bg-muted px-2 py-0.5 text-xs font-medium tabular-nums text-muted-foreground group-data-[state=active]:bg-primary/10 group-data-[state=active]:text-primary">
                      {count}
                    </span>
                  )}
                </TabsTrigger>
              );
            })}
          </TabsList>

          <TabsContent value="overview" className="mt-6">
            <div className="grid gap-6 lg:grid-cols-3">
              <div className="min-w-0 space-y-6 lg:col-span-2">
                <Panel title="Personal Information">
                  <InfoList>
                    <InfoRow label="Full name" value={displayName || "N/A"} />
                    <InfoRow label="Email" value={displayValue(user?.email)} />
                    <InfoRow label="Mobile" value={displayValue(user?.mobile)} />
                    <InfoRow
                      label="Gender"
                      value={formatLabel(user?.profile?.gender)}
                    />
                    <InfoRow
                      label="Date of birth"
                      value={formatDateOnly(user?.profile?.date_of_birth)}
                    />
                    <InfoRow
                      label="Address"
                      value={
                        addressLines.length > 0 ? (
                          <address className="not-italic">
                            {addressLines.map((line) => (
                              <span key={line} className="block">
                                {line}
                              </span>
                            ))}
                          </address>
                        ) : (
                          <span className="text-muted-foreground">
                            No address added
                          </span>
                        )
                      }
                    />
                    <InfoRow
                      label="User ID"
                      value={
                        <span className="font-mono text-xs">
                          {displayValue(user?.id)}
                        </span>
                      }
                    />
                  </InfoList>
                </Panel>

                <Panel
                  title="Devices"
                  description={
                    deviceRows.length > 0
                      ? `${deviceRows.length} registered ${deviceRows.length === 1 ? "device" : "devices"}`
                      : undefined
                  }
                >
                  {deviceRows.length === 0 ? (
                    <p className="text-sm text-muted-foreground">
                      No device record yet. App status stays Unknown until this
                      user opens the updated app.
                    </p>
                  ) : (
                    <div className="space-y-3">
                      {deviceRows.map((row, index) => {
                        const version =
                          row.android_version || row.androidVersion;
                        const summary = [
                          [row.brand, row.model].filter(Boolean).join(" "),
                          version ? `Android ${version}` : "",
                          row.app_version ? `App ${row.app_version}` : "",
                        ]
                          .filter(Boolean)
                          .join(" · ");
                        return (
                          <div
                            key={row.id || row.device_id || String(index)}
                            className="rounded-xl bg-muted/40 p-4"
                          >
                            <div className="flex flex-wrap items-start justify-between gap-2">
                              <div className="min-w-0">
                                <p className="truncate text-sm font-semibold">
                                  {displayValue(row.device_name)}
                                </p>
                                {summary && (
                                  <p className="mt-0.5 text-sm text-muted-foreground">
                                    {summary}
                                  </p>
                                )}
                              </div>
                              <StatusChip
                                tone={appStatusTone(row.install_status)}
                              >
                                {formatAppStatus(row.install_status, {
                                  device: true,
                                })}
                              </StatusChip>
                            </div>
                            <dl className="mt-4 grid gap-x-6 gap-y-3 text-sm sm:grid-cols-2 xl:grid-cols-3">
                              <MiniField
                                label="Manufacturer"
                                value={displayValue(row.manufacturer)}
                              />
                              <MiniField
                                label="RAM"
                                value={displayValue(row.ram_size)}
                              />
                              <MiniField
                                label="Platform"
                                value={formatLabel(row.platform || "android")}
                              />
                              <MiniField
                                label="Last seen"
                                value={formatDateTime(row.last_used_at)}
                              />
                              <MiniField
                                label="Registered"
                                value={formatDateTime(row.created_at)}
                              />
                              <MiniField
                                label="Device ID"
                                value={
                                  <span className="font-mono text-xs">
                                    {displayValue(row.device_id)}
                                  </span>
                                }
                              />
                            </dl>
                          </div>
                        );
                      })}
                      <p className="text-xs text-muted-foreground">
                        Uninstalled means FCM reported this device&apos;s token
                        as invalid. It is not a guaranteed uninstall time.
                      </p>
                    </div>
                  )}
                </Panel>
              </div>

              <div className="min-w-0 space-y-6">
                <Panel title="Account">
                  <InfoList>
                    <InfoRow
                      label="Sign-in method"
                      value={formatLabel(user?.signup_type)}
                    />
                    <InfoRow
                      label="Google account"
                      value={user?.google_linked ? "Linked" : "Not linked"}
                    />
                    <InfoRow
                      label="App password"
                      value={user?.password_set ? "Set" : "Not set"}
                    />
                    <InfoRow
                      label="Email verified"
                      value={
                        isVerified
                          ? user?.email_verified_at
                            ? formatDateTime(user.email_verified_at)
                            : "Yes"
                          : "No"
                      }
                    />
                    <InfoRow
                      label="Referral code"
                      value={displayValue(user?.referral_code)}
                    />
                    <InfoRow
                      label="Referred by"
                      value={displayValue(user?.referrer_id)}
                    />
                    <InfoRow
                      label="Referrals"
                      value={displayValue(user?.referred_count ?? 0)}
                    />
                    <InfoRow
                      label="Last login"
                      value={formatDateTime(user?.last_login)}
                    />
                    <InfoRow
                      label="Created"
                      value={formatDateTime(user?.create_date)}
                    />
                    <InfoRow
                      label="Updated"
                      value={formatDateTime(user?.update_date)}
                    />
                  </InfoList>
                </Panel>

                <Panel
                  title="Recent Activity"
                  action={
                    <Button
                      asChild
                      size="sm"
                      variant="ghost"
                      className="-mr-2 h-8 text-primary"
                    >
                      <Link
                        to={`/audit-logs?userId=${encodeURIComponent(userId)}`}
                      >
                        View All
                      </Link>
                    </Button>
                  }
                >
                  {activityQuery.isLoading ? (
                    <div className="inline-flex items-center gap-2 text-sm text-muted-foreground">
                      <Loader2 className="h-4 w-4 animate-spin" />
                      Loading activity...
                    </div>
                  ) : activityQuery.isError ? (
                    <p className="text-sm text-destructive">
                      {(activityQuery.error as Error)?.message ||
                        "Failed to load activity."}
                    </p>
                  ) : (activityQuery.data?.data?.length ?? 0) === 0 ? (
                    <p className="text-sm text-muted-foreground">
                      No activity yet. Events appear after the user makes
                      changes in the mobile app.
                    </p>
                  ) : (
                    <ol className="relative space-y-5 border-l border-border/70 pl-5">
                      {(activityQuery.data?.data ?? []).map((row) => (
                        <li key={String(row.id)} className="relative">
                          <span
                            aria-hidden
                            className="absolute -left-[25px] top-1.5 h-2 w-2 rounded-full bg-primary ring-4 ring-card"
                          />
                          <p className="text-sm font-medium leading-snug">
                            {displayValue(row.summary)}
                          </p>
                          <p className="mt-1 text-xs text-muted-foreground">
                            {formatLabel(row.action)}
                            {row.entity_type
                              ? ` · ${formatLabel(row.entity_type)}${row.entity_id ? ` #${row.entity_id}` : ""}`
                              : ""}
                          </p>
                          <p className="mt-0.5 text-xs text-muted-foreground">
                            {formatDateTime(row.created_at)}
                          </p>
                        </li>
                      ))}
                    </ol>
                  )}
                </Panel>
              </div>
            </div>
          </TabsContent>

          <TabsContent value="persons" className="mt-6">
          <DataSection<PersonItem>
            title="Person Details"
            totalLabel={String(personsCount)}
            icon={<Users className="h-4 w-4" />}
            accentClassName="bg-primary"
            rows={personsQuery.data?.data ?? []}
            isLoading={personsQuery.isLoading}
            getRowKey={(row) => row.id}
            columns={[
              {
                key: "sno",
                header: "S.No",
                className: "w-16",
                render: (_row, index) => index + 1,
                searchValue: () => "",
              },
              {
                key: "firstName",
                header: "First Name",
                render: (row) => displayValue(row.firstName),
                searchValue: (row) => row.firstName || "",
              },
              {
                key: "secondName",
                header: "Second Name",
                render: (row) => displayValue(row.secondName),
                searchValue: (row) => row.secondName || "",
              },
              {
                key: "business",
                header: "Business",
                render: (row) => displayValue(row.business),
                searchValue: (row) => row.business || "",
              },
              {
                key: "city",
                header: "City",
                render: (row) => displayValue(row.city),
                searchValue: (row) => row.city || "",
              },
              {
                key: "mobile",
                header: "Mobile",
                render: (row) => displayValue(row.mobile),
                searchValue: (row) => row.mobile || "",
              },
              {
                key: "createdAt",
                header: "Created At",
                className: "whitespace-nowrap",
                render: (row) => formatDateTime(row.createdAt),
                searchValue: (row) => row.createdAt || "",
              },
              {
                key: "actions",
                header: "Actions",
                className: "w-20 text-right",
                render: (row) => (
                  <Button
                    asChild
                    size="icon"
                    variant="ghost"
                    className="h-8 w-8"
                    title="View person details"
                  >
                    <Link
                      to={personPath(userId, row.id)}
                      aria-label={`View details for ${personFullName(row)}`}
                    >
                      <ChevronRight className="h-4 w-4" />
                    </Link>
                  </Button>
                ),
                searchValue: () => "",
              },
            ]}
          />
          </TabsContent>

          <TabsContent value="functions" className="mt-6">
          <DataSection<TransactionFunctionItem>
            title="Functions Details"
            totalLabel={String(functionsCount)}
            icon={<PartyPopper className="h-4 w-4" />}
            accentClassName="bg-primary"
            rows={functionsQuery.data?.data ?? []}
            isLoading={functionsQuery.isLoading}
            getRowKey={(row) => row.id}
            columns={[
              {
                key: "sno",
                header: "S.No",
                className: "w-16",
                render: (_row, index) => index + 1,
                searchValue: () => "",
              },
              {
                key: "image",
                header: "Image",
                className: "w-16",
                render: (row) => (
                  <ImageThumb
                    src={resolveImageUrl(row.imageUrl)}
                    alt={row.functionName || "Function image"}
                  />
                ),
                searchValue: () => "",
              },
              {
                key: "functionName",
                header: "Function Name",
                render: (row) => displayValue(row.functionName),
                searchValue: (row) => row.functionName || "",
              },
              {
                key: "functionDate",
                header: "Function Date",
                render: (row) => formatDateOnly(row.functionDate),
                searchValue: (row) => row.functionDate || "",
              },
              {
                key: "location",
                header: "Location",
                render: (row) => displayValue(row.location),
                searchValue: (row) => row.location || "",
              },
              {
                key: "notes",
                header: "Notes",
                render: (row) => displayValue(row.notes),
                searchValue: (row) => row.notes || "",
              },
              {
                key: "createdAt",
                header: "Created At",
                className: "whitespace-nowrap",
                render: (row) => formatDateTime(row.createdAt),
                searchValue: (row) => row.createdAt || "",
              },
              {
                key: "actions",
                header: "Actions",
                className: "w-20 text-right",
                render: (row) => (
                  <Button
                    asChild
                    size="icon"
                    variant="ghost"
                    className="h-8 w-8"
                    title="View function details"
                  >
                    <Link
                      to={functionPath(userId, row.id)}
                      aria-label={`View details for ${row.functionName || "function"}`}
                    >
                      <ChevronRight className="h-4 w-4" />
                    </Link>
                  </Button>
                ),
                searchValue: () => "",
              },
            ]}
          />
          </TabsContent>

          <TabsContent value="transactions" className="mt-6">
          <DataSection<TransactionItem>
            title="Transactions Details"
            totalLabel={String(transactionsCount)}
            icon={<ArrowLeftRight className="h-4 w-4" />}
            accentClassName="bg-primary"
            rows={transactionsQuery.data?.data ?? []}
            isLoading={transactionsQuery.isLoading}
            getRowKey={(row) => row.id}
            columns={[
              {
                key: "sno",
                header: "S.No",
                className: "w-16",
                render: (_row, index) => index + 1,
                searchValue: () => "",
              },
              {
                key: "person",
                header: "Person",
                render: (row) => transactionPersonName(row),
                searchValue: (row) => transactionPersonName(row),
              },
              {
                key: "transactionFunction",
                header: "Transaction Function",
                render: (row) => displayValue(row.transactionFunctionName),
                searchValue: (row) => row.transactionFunctionName || "",
              },
              {
                key: "transactionDate",
                header: "Transaction Date",
                render: (row) => formatDateOnly(row.transactionDate),
                searchValue: (row) => row.transactionDate || "",
              },
              {
                key: "type",
                header: "Type",
                render: (row) => <TransactionTypeBadge type={row.type} />,
                searchValue: (row) => row.type || "",
              },
              {
                key: "amount",
                header: "Amount",
                render: (row) => (
                  <span className="font-semibold tabular-nums">
                    {formatAmount(row.amount)}
                  </span>
                ),
                searchValue: (row) => String(row.amount ?? ""),
              },
              {
                key: "functionName",
                header: "Function Name",
                render: (row) => displayValue(row.function?.name),
                searchValue: (row) => row.function?.name || "",
              },
              {
                key: "createdAt",
                header: "Created At",
                className: "whitespace-nowrap",
                render: (row) => formatDateTime(row.createdAt),
                searchValue: (row) => row.createdAt || "",
              },
              {
                key: "actions",
                header: "Actions",
                className: "w-20 text-right",
                render: (row) => (
                  <ViewTransactionButton userId={userId} row={row} />
                ),
                searchValue: () => "",
              },
            ]}
          />
          </TabsContent>

          <TabsContent value="upcoming" className="mt-6">
          <DataSection<UpcomingFunctionItem>
            title="Upcoming Functions"
            totalLabel={String(upcomingFunctionsCount)}
            icon={<CalendarDays className="h-4 w-4" />}
            accentClassName="bg-primary"
            rows={upcomingFunctionsQuery.data?.data ?? []}
            isLoading={upcomingFunctionsQuery.isLoading}
            getRowKey={(row) => row.id}
            columns={[
              {
                key: "sno",
                header: "S.No",
                className: "w-16",
                render: (_row, index) => index + 1,
                searchValue: () => "",
              },
              {
                key: "image",
                header: "Image",
                className: "w-16",
                render: (row) => (
                  <ImageThumb
                    src={resolveImageUrl(row.invitationUrl)}
                    alt={row.title || "Invitation image"}
                  />
                ),
                searchValue: () => "",
              },
              {
                key: "title",
                header: "Title",
                render: (row) => displayValue(row.title),
                searchValue: (row) => row.title || "",
              },
              {
                key: "functionDate",
                header: "Date",
                render: (row) => formatDateOnly(row.functionDate),
                searchValue: (row) => row.functionDate || "",
              },
              {
                key: "location",
                header: "Location",
                render: (row) => displayValue(row.location),
                searchValue: (row) => row.location || "",
              },
              {
                key: "status",
                header: "Status",
                render: (row) => (
                  <Badge
                    className={cn(
                      "border-transparent",
                      String(row.status || "").toUpperCase() === "ACTIVE"
                        ? "bg-emerald-500/15 text-emerald-700"
                        : String(row.status || "").toUpperCase() === "COMPLETED"
                          ? "bg-sky-500/15 text-sky-700"
                          : "bg-rose-500/15 text-rose-700",
                    )}
                  >
                    {formatLabel(row.status)}
                  </Badge>
                ),
                searchValue: (row) => row.status || "",
              },
              {
                key: "createdAt",
                header: "Created At",
                className: "whitespace-nowrap",
                render: (row) => formatDateTime(row.createdAt),
                searchValue: (row) => row.createdAt || "",
              },
            ]}
          />
          </TabsContent>

          <TabsContent value="notifications" className="mt-6">
          <DataSection<NotificationItem>
            title="Notifications"
            totalLabel={`${notificationsTotal} · Unread ${notificationsUnread}`}
            icon={<Bell className="h-4 w-4" />}
            accentClassName="bg-primary"
            rows={notificationsRows}
            isLoading={
              notificationsQuery.isLoading || notificationsQuery.isFetching
            }
            getRowKey={(row) => row.id}
            serverPagination
            page={notificationsPage}
            limit={notificationsLimit}
            totalCount={notificationsTotal}
            onPageChange={setNotificationsPage}
            onLimitChange={(nextLimit) => {
              setNotificationsLimit(nextLimit);
              setNotificationsPage(1);
            }}
            columns={[
              {
                key: "sno",
                header: "S.No",
                className: "w-16",
                render: (_row, index) => index + 1,
                searchValue: () => "",
              },
              {
                key: "title",
                header: "Title",
                render: (row) => (
                  <div>
                    <p className="font-medium">{row.title}</p>
                    <p className="line-clamp-2 text-xs text-muted-foreground">
                      {row.body}
                    </p>
                  </div>
                ),
                searchValue: (row) => `${row.title} ${row.body}`,
              },
              {
                key: "type",
                header: "Type",
                render: (row) => formatLabel(row.type),
                searchValue: (row) => row.type || "",
              },
              {
                key: "status",
                header: "Status",
                render: (row) => (
                  <Badge
                    className={cn(
                      "border-transparent",
                      row.isRead
                        ? "bg-emerald-500/15 text-emerald-700"
                        : "bg-amber-500/15 text-amber-700",
                    )}
                  >
                    {row.isRead ? "Read" : "Unread"}
                  </Badge>
                ),
                searchValue: (row) => (row.isRead ? "read" : "unread"),
              },
              {
                key: "createdAt",
                header: "Created At",
                render: (row) => formatDateTime(row.createdAt),
                searchValue: (row) => row.createdAt || "",
              },
            ]}
          />
          </TabsContent>
        </Tabs>
      </div>

      <AlertDialog open={verifyEmailOpen} onOpenChange={setVerifyEmailOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Send verification email?</AlertDialogTitle>
            <AlertDialogDescription>
              A verification link will be sent to{" "}
              <span className="font-medium text-foreground">
                {user?.email || "this user"}
              </span>
              . They can tap the button in the email to verify their address.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={verifyEmailMutation.isPending}>
              Cancel
            </AlertDialogCancel>
            <AlertDialogAction
              className="gap-2"
              disabled={verifyEmailMutation.isPending || !user?.email}
              onClick={(e) => {
                e.preventDefault();
                verifyEmailMutation.mutate();
              }}
            >
              {verifyEmailMutation.isPending ? (
                <span className="inline-flex items-center gap-2">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Sending...
                </span>
              ) : (
                "Send verification email"
              )}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <AlertDialog open={blockOpen} onOpenChange={setBlockOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Block this user?</AlertDialogTitle>
            <AlertDialogDescription>
              <span className="font-medium text-foreground">
                {displayName || "This user"}
              </span>{" "}
              will be signed out and cannot use the mobile app until you
              activate the account again.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={statusMutation.isPending}>
              Cancel
            </AlertDialogCancel>
            <AlertDialogAction
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              disabled={statusMutation.isPending}
              onClick={(e) => {
                e.preventDefault();
                statusMutation.mutate("BLOCKED");
              }}
            >
              {statusMutation.isPending ? (
                <span className="inline-flex items-center gap-2">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Blocking...
                </span>
              ) : (
                "Block"
              )}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <AlertDialog open={statusDialogOpen} onOpenChange={setStatusDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              {isActive
                ? "Deactivate this user?"
                : isDeleted
                  ? "Restore this user?"
                  : "Activate this user?"}
            </AlertDialogTitle>
            <AlertDialogDescription>
              {isActive ? (
                <>
                  <span className="font-medium text-foreground">
                    {displayName || "This user"}
                  </span>{" "}
                  will not be able to log in, reset password, or use the mobile
                  app until you activate the account again.
                </>
              ) : (
                <>
                  <span className="font-medium text-foreground">
                    {displayName || "This user"}
                  </span>{" "}
                  will be able to log in from the mobile app again.
                </>
              )}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={statusMutation.isPending}>
              Cancel
            </AlertDialogCancel>
            <AlertDialogAction
              className={
                isActive
                  ? "bg-destructive text-destructive-foreground hover:bg-destructive/90"
                  : "bg-emerald-600 text-white hover:bg-emerald-700"
              }
              disabled={statusMutation.isPending}
              onClick={(e) => {
                e.preventDefault();
                statusMutation.mutate(isActive ? "INACTIVE" : "ACTIVE");
              }}
            >
              {statusMutation.isPending ? (
                <span className="inline-flex items-center gap-2">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Updating...
                </span>
              ) : isActive ? (
                "Deactivate"
              ) : (
                "Activate"
              )}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <AlertDialog open={softDeleteOpen} onOpenChange={setSoftDeleteOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Soft delete this user?</AlertDialogTitle>
            <AlertDialogDescription>
              <span className="font-medium text-foreground">
                {user?.name || "This user"}
              </span>{" "}
              will be marked deleted and cannot log in. Persons, functions, and
              transactions stay in the database and can be restored later.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleteMutation.isPending}>
              Cancel
            </AlertDialogCancel>
            <AlertDialogAction
              className="bg-amber-600 text-white hover:bg-amber-700"
              disabled={deleteMutation.isPending}
              onClick={(e) => {
                e.preventDefault();
                deleteMutation.mutate("soft");
              }}
            >
              {deleteMutation.isPending ? (
                <span className="inline-flex items-center gap-2">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Deleting...
                </span>
              ) : (
                "Soft delete"
              )}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <Dialog
        open={permanentDeleteOpen}
        onOpenChange={(open) => {
          setPermanentDeleteOpen(open);
          if (!open) setPermanentConfirmName("");
        }}
      >
        <DialogContent className="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>Delete this user permanently?</DialogTitle>
          </DialogHeader>
          <p className="text-sm text-muted-foreground">
            This removes{" "}
            <span className="font-medium text-foreground">
              {user?.name || "this user"}
            </span>{" "}
            and all related records: transactions, persons, functions,
            notifications, feedback, devices, and OTPs. This cannot be undone.
          </p>
          <div className="space-y-2">
            <Label htmlFor="permanent-confirm-name">
              Type the user name to confirm
            </Label>
            <Input
              id="permanent-confirm-name"
              value={permanentConfirmName}
              onChange={(e) => setPermanentConfirmName(e.target.value)}
              placeholder={user?.name || "User name"}
              autoComplete="off"
            />
          </div>
          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              disabled={deleteMutation.isPending}
              onClick={() => setPermanentDeleteOpen(false)}
            >
              Cancel
            </Button>
            <Button
              type="button"
              variant="destructive"
              disabled={
                deleteMutation.isPending ||
                permanentConfirmName.trim().toLowerCase() !==
                  (user?.name || "").trim().toLowerCase() ||
                !user?.name
              }
              onClick={() => deleteMutation.mutate("permanent")}
            >
              {deleteMutation.isPending ? (
                <span className="inline-flex items-center gap-2">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Deleting...
                </span>
              ) : (
                "Delete permanently"
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog
        open={emailOpen}
        onOpenChange={(open) => {
          setEmailOpen(open);
          if (!open) resetEmailForm();
        }}
      >
        <DialogContent className="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>Send Email</DialogTitle>
          </DialogHeader>
          <p className="text-sm text-muted-foreground">
            Sending to{" "}
            <span className="font-semibold text-foreground">
              {user?.name || user?.email || "this user"}
            </span>
            .
          </p>
          <div className="space-y-4 py-2">
            <div className="space-y-2">
              <Label htmlFor="user-email-subject">Subject</Label>
              <Input
                id="user-email-subject"
                value={emailSubject}
                onChange={(e) => setEmailSubject(e.target.value)}
                placeholder="Subject"
              />
            </div>
            <div className="space-y-2">
              <Label>Type</Label>
              <Select
                value={emailType}
                onValueChange={(value) => setEmailType(value as BulkEmailType)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {EMAIL_TYPES.map((item) => (
                    <SelectItem key={item.value} value={item.value}>
                      {item.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="user-email-body">Body</Label>
              <Textarea
                id="user-email-body"
                value={emailBody}
                onChange={(e) => setEmailBody(e.target.value)}
                placeholder="Email content"
                rows={5}
              />
            </div>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setEmailOpen(false)}
              disabled={emailMutation.isPending}
            >
              Cancel
            </Button>
            <Button
              className="gap-2"
              onClick={handleSendEmail}
              disabled={emailMutation.isPending}
            >
              {emailMutation.isPending ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <Send className="h-4 w-4" />
              )}
              Send Email
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog
        open={notificationOpen}
        onOpenChange={(open) => {
          setNotificationOpen(open);
          if (!open) resetNotificationForm();
        }}
      >
        <DialogContent className="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>Send Notification</DialogTitle>
          </DialogHeader>
          <p className="text-sm text-muted-foreground">
            Sending to{" "}
            <span className="font-semibold text-foreground">
              {user?.name || "this user"}
            </span>
            .
          </p>
          <div className="space-y-4 py-2">
            <div className="space-y-2">
              <Label htmlFor="user-notification-title">Title</Label>
              <Input
                id="user-notification-title"
                value={notificationTitle}
                onChange={(e) => setNotificationTitle(e.target.value)}
                placeholder="Notification Title"
              />
            </div>
            <div className="space-y-2">
              <Label>Type (Optional)</Label>
              <Select
                value={notificationType}
                onValueChange={(value) =>
                  setNotificationType(value as BulkNotificationType)
                }
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {NOTIFICATION_TYPES.map((item) => (
                    <SelectItem key={item.value} value={item.value}>
                      {item.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="user-notification-body">Body</Label>
              <Textarea
                id="user-notification-body"
                value={notificationBody}
                onChange={(e) => setNotificationBody(e.target.value)}
                placeholder="Notification content"
                rows={5}
              />
            </div>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setNotificationOpen(false)}
              disabled={notificationMutation.isPending}
            >
              Cancel
            </Button>
            <Button
              className="gap-2"
              onClick={handleSendNotification}
              disabled={notificationMutation.isPending}
            >
              {notificationMutation.isPending ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <Send className="h-4 w-4" />
              )}
              Send Notification
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
