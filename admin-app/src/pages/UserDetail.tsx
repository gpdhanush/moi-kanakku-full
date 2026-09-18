import { useEffect, useMemo, useState, type ReactNode } from "react";
import { useNavigate, useParams, Link } from "react-router-dom";
import { useMutation, useQueries, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  ArrowLeft,
  User,
  Phone,
  Mail,
  MailCheck,
  MapPin,
  ShieldCheck,
  Smartphone,
  Users,
  PartyPopper,
  ArrowLeftRight,
  CalendarDays,
  Bell,
  IdCard,
  Clock3,
  Loader2,
  UserCheck,
  UserX,
  Send,
  Trash2,
  ChevronDown,
  ScrollText,
} from "lucide-react";
import { StatCard, StatCardSkeleton } from "@/components/ui/stat-card";
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
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { usePageMeta } from "@/hooks/usePageMeta";
import { toast } from "@/hooks/use-toast";
import { usersApi, type UserDevice } from "@/features/users/api";
import { personsApi, type PersonItem } from "@/features/persons/api";
import {
  transactionFunctionsApi,
  type TransactionFunctionItem,
} from "@/features/transaction-functions/api";
import { transactionsApi, type TransactionItem } from "@/features/transactions/api";
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
  appStatusClassName,
  resolveImageUrl,
} from "@/lib/formatters";
import { cn } from "@/lib/utils";

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

function Field({
  label,
  value,
}: {
  label: string;
  value: string;
}) {
  return (
    <div className="min-w-0 space-y-1">
      <p className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
        {label}
      </p>
      <p className="break-words text-sm font-medium text-foreground">{value}</p>
    </div>
  );
}

function SectionCard({
  title,
  icon,
  children,
}: {
  title: string;
  icon: ReactNode;
  children: ReactNode;
}) {
  return (
    <div className="min-w-0 rounded-2xl border border-border/60 bg-card p-5 shadow-sm">
      <div className="mb-4 flex items-center gap-2.5">
        <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary/10 text-primary">
          {icon}
        </div>
        <h3 className="text-sm font-semibold tracking-tight">{title}</h3>
      </div>
      {children}
    </div>
  );
}

export default function UserDetail() {
  const { userId = "" } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
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

  const userQuery = useQuery({
    queryKey: ["admin", "users", userId],
    queryFn: () => usersApi.getById(userId),
    enabled: !!userId,
    staleTime: 60_000,
  });

  const relatedQueries = useQueries({
    queries: [
      {
        queryKey: ["admin", "persons", userId],
        queryFn: () => personsApi.listByUser(userId),
        enabled: !!userId,
        staleTime: 60_000,
      },
      {
        queryKey: ["admin", "transaction-functions", userId],
        queryFn: () => transactionFunctionsApi.list(userId),
        enabled: !!userId,
        staleTime: 60_000,
      },
      {
        queryKey: ["admin", "transactions", "user", userId],
        queryFn: () => transactionsApi.list(userId),
        enabled: !!userId,
        staleTime: 60_000,
      },
      {
        queryKey: ["admin", "upcoming-functions", userId],
        queryFn: () => upcomingFunctionsApi.list(userId),
        enabled: !!userId,
        staleTime: 60_000,
      },
    ],
  });

  const [personsQuery, functionsQuery, transactionsQuery, upcomingFunctionsQuery] =
    relatedQueries;

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
    title: user?.name ? `User: ${user.name}` : "User Details",
    description: "User profile and related records",
  });

  const initials = useMemo(
    () =>
      (user?.name || "U")
        .split(" ")
        .map((n) => n[0])
        .join("")
        .slice(0, 2)
        .toUpperCase(),
    [user?.name]
  );

  const isActive = (user?.status || "").toUpperCase() === "ACTIVE";
  const isVerified = Boolean(Number(user?.is_verified));
  const deviceRows: UserDevice[] =
    user?.devices && user.devices.length > 0
      ? user.devices
      : user?.device
        ? [user.device]
        : [];
  const profileImage = resolveImageUrl(
    user?.profile?.profile_image_url || null
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
    mutationFn: (status: "ACTIVE" | "INACTIVE") =>
      usersApi.updateStatus(userId, status),
    onSuccess: (result, status) => {
      toast({
        title: status === "INACTIVE" ? "User deactivated" : "User activated",
        description:
          result.message ||
          (status === "INACTIVE"
            ? "This user cannot log in or reset password until reactivated."
            : "This user can log in from the mobile app."),
      });
      setStatusDialogOpen(false);
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
        title: mode === "permanent" ? "User permanently deleted" : "User soft deleted",
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
        title: "Verification email queued",
        description:
          result.message ||
          `A verification link will be sent to ${result.sent_to || user?.email || "the user"}.`,
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
          result.message ||
          `Notification sent to ${user?.name || "user"}.`,
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
      <div className="space-y-6 animate-fade-in">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <Button
            size="sm"
            variant="outline"
            className="h-9 gap-2 self-start"
            onClick={() => navigate("/users")}
          >
            <ArrowLeft className="h-4 w-4" />
            Back to Users
          </Button>
          {user && (
            <div className="flex flex-wrap items-center justify-end gap-2">
              {!isVerified && (
                <Button
                  size="sm"
                  className="h-9 gap-2"
                  onClick={() => setVerifyEmailOpen(true)}
                  disabled={verifyEmailMutation.isPending}
                >
                  <MailCheck className="h-4 w-4" />
                  Verify Email
                </Button>
              )}
              <Button
                size="sm"
                className="h-9 gap-2 bg-emerald-600 text-white hover:bg-emerald-700"
                onClick={() => setEmailOpen(true)}
              >
                <Mail className="h-4 w-4" />
                Send Email
              </Button>
              <Button
                size="sm"
                className="h-9 gap-2 bg-orange-500 text-white hover:bg-orange-600"
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
                    className="h-9 gap-2"
                    disabled={deleteMutation.isPending}
                  >
                    <Trash2 className="h-4 w-4" />
                    Delete
                    <ChevronDown className="h-4 w-4" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" className="w-48">
                  <DropdownMenuItem
                    className="gap-2"
                    onSelect={() => setSoftDeleteOpen(true)}
                  >
                    <Trash2 className="h-4 w-4 text-amber-600" />
                    Soft delete
                  </DropdownMenuItem>
                  <DropdownMenuItem
                    className="gap-2 text-destructive focus:text-destructive"
                    onSelect={() => {
                      setPermanentConfirmName("");
                      setPermanentDeleteOpen(true);
                    }}
                  >
                    <Trash2 className="h-4 w-4" />
                    Delete permanently
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
              <Button
                size="sm"
                variant={isActive ? "destructive" : "default"}
                className={cn(
                  "h-9 gap-2",
                  !isActive && "bg-emerald-600 hover:bg-emerald-700"
                )}
                onClick={() => setStatusDialogOpen(true)}
                disabled={statusMutation.isPending || deleteMutation.isPending}
              >
                {isActive ? (
                  <UserX className="h-4 w-4" />
                ) : (
                  <UserCheck className="h-4 w-4" />
                )}
                {isActive ? "Deactivate" : "Activate"}
              </Button>
            </div>
          )}
        </div>

        {userQuery.isError && (
          <div className="rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3 text-sm text-destructive">
            {(userQuery.error as Error)?.message || "Failed to load user details."}
          </div>
        )}

        <div className="overflow-hidden rounded-2xl border border-border/60 bg-card shadow-sm">
          <div className="h-1.5 bg-primary" />
          {userQuery.isLoading ? (
            <div className="flex items-center gap-4 p-6">
              <div className="h-20 w-20 animate-pulse rounded-full bg-muted" />
              <div className="flex-1 space-y-3">
                <div className="h-6 w-48 animate-pulse rounded bg-muted" />
                <div className="h-4 w-72 animate-pulse rounded bg-muted" />
              </div>
            </div>
          ) : (
            <div className="flex flex-col gap-5 p-5 sm:flex-row sm:items-start sm:p-6">
              <Avatar className="h-20 w-20 ring-4 ring-primary/10">
                <AvatarImage src={profileImage} />
                <AvatarFallback className="bg-primary/10 text-2xl font-semibold text-primary">
                  {initials}
                </AvatarFallback>
              </Avatar>

              <div className="min-w-0 flex-1">
                <div className="flex flex-wrap items-center gap-2">
                  <h2 className="text-xl font-semibold tracking-tight">
                    {user?.name || "—"}
                  </h2>
                  <Badge
                    className={cn(
                      "border-transparent",
                      isActive
                        ? "bg-emerald-500/15 text-emerald-700"
                        : "bg-rose-500/15 text-rose-700"
                    )}
                  >
                    {formatLabel(user?.status) || "Unknown"}
                  </Badge>
                  <Badge
                    className={cn(
                      "border-transparent",
                      appStatusClassName(user?.app_status)
                    )}
                  >
                    App: {formatAppStatus(user?.app_status)}
                  </Badge>
                  <Badge
                    className={cn(
                      "border-transparent",
                      isVerified
                        ? "bg-primary/10 text-primary"
                        : "bg-amber-500/15 text-amber-700"
                    )}
                  >
                    {isVerified ? "Verified" : "Unverified"}
                  </Badge>
                </div>

                <div className="mt-3 grid gap-2 text-sm text-muted-foreground sm:grid-cols-2 xl:grid-cols-3">
                  <div className="flex items-center gap-2">
                    <Mail className="h-4 w-4 shrink-0 text-primary" />
                    <span className="truncate">{displayValue(user?.email)}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Phone className="h-4 w-4 shrink-0 text-primary" />
                    <span className="truncate">{displayValue(user?.mobile)}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <MapPin className="h-4 w-4 shrink-0 text-primary" />
                    <span className="truncate">{locationLabel}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <IdCard className="h-4 w-4 shrink-0 text-primary" />
                    <span className="truncate">
                      Referral: {displayValue(user?.referral_code)}
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Smartphone className="h-4 w-4 shrink-0 text-primary" />
                    <span className="truncate">
                      Last seen: {formatDateTime(user?.last_seen_at)}
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Clock3 className="h-4 w-4 shrink-0 text-primary" />
                    <span className="truncate">
                      Last login: {formatDateTime(user?.last_login)}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
          {userQuery.isLoading ? (
            Array.from({ length: 5 }).map((_, i) => (
              <StatCardSkeleton key={i} />
            ))
          ) : (
            <>
              <StatCard
                title="Persons"
                value={personsCount}
                icon={Users}
                color="blue"
              />
              <StatCard
                title="Functions"
                value={functionsCount}
                icon={PartyPopper}
                color="emerald"
              />
              <StatCard
                title="Transactions"
                value={transactionsCount}
                icon={ArrowLeftRight}
                color="rose"
              />
              <StatCard
                title="Upcoming"
                value={upcomingFunctionsCount}
                icon={CalendarDays}
                color="violet"
              />
              <StatCard
                title="Unread"
                value={notificationsUnread}
                icon={Bell}
                color="amber"
              />
            </>
          )}
        </div>

        <div className="grid min-w-0 gap-4 lg:grid-cols-2">
          <SectionCard title="Personal Information" icon={<User className="h-4 w-4" />}>
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Full Name" value={displayValue(user?.name)} />
              <Field label="Email" value={displayValue(user?.email)} />
              <Field label="Mobile" value={displayValue(user?.mobile)} />
              <Field label="Gender" value={displayValue(user?.profile?.gender)} />
              <Field
                label="Date of Birth"
                value={formatDateOnly(user?.profile?.date_of_birth)}
              />
              <Field label="User ID" value={displayValue(user?.id)} />
            </div>
          </SectionCard>

          <SectionCard title="Account" icon={<ShieldCheck className="h-4 w-4" />}>
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Created At" value={formatDateTime(user?.create_date)} />
              <Field label="Updated At" value={formatDateTime(user?.update_date)} />
              <Field
                label="Email Verified At"
                value={formatDateTime(user?.email_verified_at)}
              />
              <Field label="Referrer ID" value={displayValue(user?.referrer_id)} />
              <Field
                label="Referred Count"
                value={displayValue(user?.referred_count ?? 0)}
              />
              <Field
                label="Member Since"
                value={formatDateTime(user?.create_date)}
              />
            </div>
          </SectionCard>

          <SectionCard title="Address" icon={<MapPin className="h-4 w-4" />}>
            <div className="grid gap-4 sm:grid-cols-2">
              <Field
                label="Address Line 1"
                value={displayValue(user?.profile?.address_line1)}
              />
              <Field
                label="Address Line 2"
                value={displayValue(user?.profile?.address_line2)}
              />
              <Field label="City" value={displayValue(user?.profile?.city)} />
              <Field label="State" value={displayValue(user?.profile?.state)} />
              <Field
                label="Country"
                value={displayValue(user?.profile?.country)}
              />
              <Field
                label="Postal Code"
                value={displayValue(user?.profile?.postal_code)}
              />
            </div>
          </SectionCard>
        </div>

        <SectionCard title="Devices" icon={<Smartphone className="h-4 w-4" />}>
          {deviceRows.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              No device record yet. App status is Unknown until this user
              opens the updated app.
            </p>
          ) : (
            <div className="space-y-4">
              {deviceRows.map((row, index) => (
                <div
                  key={row.id || row.device_id || String(index)}
                  className="rounded-xl border border-border/60 p-4"
                >
                  <div className="mb-3 flex flex-wrap items-center gap-2">
                    <p className="text-sm font-semibold">
                      {displayValue(row.device_name)}
                    </p>
                    <Badge
                      className={cn(
                        "border-transparent",
                        appStatusClassName(row.install_status)
                      )}
                    >
                      {formatAppStatus(row.install_status, { device: true })}
                    </Badge>
                  </div>
                  <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                    <Field label="Brand" value={displayValue(row.brand)} />
                    <Field label="Model" value={displayValue(row.model)} />
                    <Field
                      label="Manufacturer"
                      value={displayValue(row.manufacturer)}
                    />
                    <Field
                      label="Android Version"
                      value={displayValue(row.android_version || row.androidVersion)}
                    />
                    <Field label="RAM" value={displayValue(row.ram_size)} />
                    <Field
                      label="Platform"
                      value={displayValue(row.platform || "android")}
                    />
                    <Field
                      label="App Version"
                      value={displayValue(row.app_version)}
                    />
                    <Field
                      label="Device ID"
                      value={displayValue(row.device_id)}
                    />
                    <Field
                      label="Last Seen"
                      value={formatDateTime(row.last_used_at)}
                    />
                    <Field
                      label="Registered"
                      value={formatDateTime(row.created_at)}
                    />
                  </div>
                </div>
              ))}
              <p className="text-xs text-muted-foreground">
                Likely Uninstalled means FCM reported this token as invalid.
                It is not a guaranteed uninstall time.
              </p>
            </div>
          )}
        </SectionCard>

        <SectionCard title="Recent Activity" icon={<ScrollText className="h-4 w-4" />}>
          <div className="mb-3 flex items-center justify-between gap-2">
            <p className="text-sm text-muted-foreground">
              Latest mobile write actions for this user
            </p>
            <Button
              asChild
              size="sm"
              variant="outline"
              className="h-8"
            >
              <Link to={`/audit-logs?userId=${encodeURIComponent(userId)}`}>
                View all
              </Link>
            </Button>
          </div>
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
              No activity recorded yet. Events appear after the user performs
              actions in the mobile app.
            </p>
          ) : (
            <div className="space-y-3">
              {(activityQuery.data?.data ?? []).map((row) => (
                <div
                  key={String(row.id)}
                  className="rounded-xl border border-border/60 px-4 py-3"
                >
                  <div className="flex flex-wrap items-center gap-2">
                    <Badge className="border-transparent bg-primary/10 text-primary">
                      {formatLabel(row.action)}
                    </Badge>
                    <span className="text-xs text-muted-foreground">
                      {formatDateTime(row.created_at)}
                    </span>
                  </div>
                  <p className="mt-2 text-sm font-medium">
                    {displayValue(row.summary)}
                  </p>
                  {row.entity_type ? (
                    <p className="mt-1 text-xs text-muted-foreground">
                      {formatLabel(row.entity_type)}
                      {row.entity_id ? ` #${row.entity_id}` : ""}
                    </p>
                  ) : null}
                </div>
              ))}
            </div>
          )}
        </SectionCard>

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
          ]}
        />

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
          ]}
        />

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
              render: (row) => (
                <Badge
                  className={cn(
                    "border-transparent",
                    (row.type || "").toUpperCase() === "RETURN"
                      ? "bg-amber-500/15 text-amber-700"
                      : "bg-emerald-500/15 text-emerald-700"
                  )}
                >
                  {formatLabel(row.type)}
                </Badge>
              ),
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
          ]}
        />

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
                        : "bg-rose-500/15 text-rose-700"
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
                      : "bg-amber-500/15 text-amber-700"
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
      </div>

      <AlertDialog
        open={verifyEmailOpen}
        onOpenChange={setVerifyEmailOpen}
      >
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

      <AlertDialog open={statusDialogOpen} onOpenChange={setStatusDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              {isActive ? "Deactivate this user?" : "Activate this user?"}
            </AlertDialogTitle>
            <AlertDialogDescription>
              {isActive ? (
                <>
                  <span className="font-medium text-foreground">
                    {user?.name || "This user"}
                  </span>{" "}
                  will not be able to log in, reset password, or use the mobile
                  app until you activate the account again.
                </>
              ) : (
                <>
                  <span className="font-medium text-foreground">
                    {user?.name || "This user"}
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
              className="gap-2 bg-emerald-600 text-white hover:bg-emerald-700"
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
              className="gap-2 bg-orange-500 text-white hover:bg-orange-600"
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
