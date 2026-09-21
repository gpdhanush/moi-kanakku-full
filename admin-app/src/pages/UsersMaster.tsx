import { useMemo, useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
import {
  Users,
  RefreshCw,
  Loader2,
  Search,
  ChevronLeft,
  ChevronRight,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  Smartphone,
  Mail,
  Bell,
  Send,
  UserX,
} from "lucide-react";
import { PageTitle } from "@/components/ui/page-title";
import { StatCard, StatCardSkeleton } from "@/components/ui/stat-card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Checkbox } from "@/components/ui/checkbox";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";
import { usePageMeta } from "@/hooks/usePageMeta";
import { toast } from "@/hooks/use-toast";
import { usersApi, type AppInstallStatus, type UserListItem } from "@/features/users/api";
import {
  adminNotificationsApi,
  emailApi,
  type BulkEmailType,
  type BulkNotificationType,
} from "@/features/messaging/api";
import { formatDateTime, displayValue, resolveImageUrl, formatAppStatus, appStatusClassName } from "@/lib/formatters";
import { cn } from "@/lib/utils";

const PAGE_LIMITS = [5, 10, 20, 50] as const;
const APP_STATUS_FILTERS: { value: "ALL" | AppInstallStatus; label: string }[] = [
  { value: "ALL", label: "Status" },
  { value: "ACTIVE", label: "Installed" },
  { value: "INACTIVE", label: "Inactive" },
  { value: "LIKELY_UNINSTALLED", label: "Likely Uninstalled" },
  { value: "UNKNOWN", label: "Unknown" },
];

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

type SortKey =
  | "sno"
  | "name"
  | "app_status"
  | "last_seen_at"
  | "last_login"
  | "city"
  | "status";

type SortDir = "asc" | "desc";

function compareValues(a: string | number, b: string | number, dir: SortDir) {
  if (a < b) return dir === "asc" ? -1 : 1;
  if (a > b) return dir === "asc" ? 1 : -1;
  return 0;
}

function toSortTime(value?: string | null): number {
  if (!value) return 0;
  const time = new Date(value).getTime();
  return Number.isNaN(time) ? 0 : time;
}

function SortIcon({ active, direction }: { active: boolean; direction: SortDir }) {
  if (!active) return <ArrowUpDown className="h-3.5 w-3.5 opacity-50" />;
  return direction === "asc" ? (
    <ArrowUp className="h-3.5 w-3.5" />
  ) : (
    <ArrowDown className="h-3.5 w-3.5" />
  );
}

export default function UsersMaster() {
  const navigate = useNavigate();
  const [search, setSearch] = useState("");
  const [appStatusFilter, setAppStatusFilter] = useState<"ALL" | AppInstallStatus>("ALL");
  const [sortKey, setSortKey] = useState<SortKey>("sno");
  const [sortDir, setSortDir] = useState<SortDir>("desc");
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(10);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());

  const [emailOpen, setEmailOpen] = useState(false);
  const [emailSubject, setEmailSubject] = useState("");
  const [emailBody, setEmailBody] = useState("");
  const [emailType, setEmailType] = useState<BulkEmailType>("notification");

  const [notificationOpen, setNotificationOpen] = useState(false);
  const [notificationTitle, setNotificationTitle] = useState("");
  const [notificationBody, setNotificationBody] = useState("");
  const [notificationType, setNotificationType] =
    useState<BulkNotificationType>("general");

  const metaElement = usePageMeta({
    title: "Users Master",
    description: "Manage app users and profiles",
  });

  const { data = [], isLoading, isFetching, isError, error, refetch } = useQuery({
    queryKey: ["admin", "users"],
    queryFn: () => usersApi.list(),
    staleTime: 60_000,
    refetchOnWindowFocus: false,
  });

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    const list = data.filter((user) => {
      const appStatus = String(user.app_status || "UNKNOWN").toUpperCase();
      if (appStatusFilter !== "ALL" && appStatus !== appStatusFilter) return false;
      if (!q) return true;
      return [user.name, user.mobile, user.city, user.device_name, user.status, user.app_status]
        .join(" ")
        .toLowerCase()
        .includes(q);
    });

    list.sort((a, b) => {
      switch (sortKey) {
        case "sno":
          return compareValues(Number(a.id) || 0, Number(b.id) || 0, sortDir);
        case "name":
          return compareValues(
            (a.name || "").toLowerCase(),
            (b.name || "").toLowerCase(),
            sortDir
          );
        case "app_status":
          return compareValues(
            String(a.app_status || "UNKNOWN").toUpperCase(),
            String(b.app_status || "UNKNOWN").toUpperCase(),
            sortDir
          );
        case "last_seen_at":
          return compareValues(toSortTime(a.last_seen_at), toSortTime(b.last_seen_at), sortDir);
        case "last_login":
          return compareValues(toSortTime(a.last_login), toSortTime(b.last_login), sortDir);
        case "city":
          return compareValues(
            (a.city || "").toLowerCase(),
            (b.city || "").toLowerCase(),
            sortDir
          );
        case "status":
          return compareValues(
            (a.status || "ACTIVE").toUpperCase(),
            (b.status || "ACTIVE").toUpperCase(),
            sortDir
          );
        default:
          return 0;
      }
    });

    return list;
  }, [data, search, appStatusFilter, sortKey, sortDir]);

  const totalItems = filtered.length;
  const totalPages = Math.max(1, Math.ceil(totalItems / limit));
  const currentPage = Math.min(page, totalPages);
  const pageRows = filtered.slice((currentPage - 1) * limit, currentPage * limit);
  const fromItem = totalItems === 0 ? 0 : (currentPage - 1) * limit + 1;
  const toItem = Math.min(currentPage * limit, totalItems);

  const selectedCount = selectedIds.size;
  const pageIds = pageRows.map((u) => String(u.id));
  const allPageSelected =
    pageIds.length > 0 && pageIds.every((id) => selectedIds.has(id));
  const somePageSelected =
    pageIds.some((id) => selectedIds.has(id)) && !allPageSelected;

  const toggleUser = (user: UserListItem, checked: boolean) => {
    const id = String(user.id);
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (checked) next.add(id);
      else next.delete(id);
      return next;
    });
  };

  const togglePage = (checked: boolean) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      pageIds.forEach((id) => {
        if (checked) next.add(id);
        else next.delete(id);
      });
      return next;
    });
  };

  const selectedUserIds = useMemo(() => Array.from(selectedIds), [selectedIds]);
  const recipientUserIds = useMemo(
    () =>
      selectedCount > 0
        ? selectedUserIds
        : filtered.map((user) => String(user.id)),
    [selectedCount, selectedUserIds, filtered]
  );
  const sendingToAll = selectedCount === 0;

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

  const emailMutation = useMutation({
    mutationFn: () =>
      emailApi.sendBulk({
        userIds: recipientUserIds,
        subject: emailSubject.trim(),
        body: emailBody.trim(),
        type: emailType,
      }),
    onSuccess: (result) => {
      toast({
        title: "Email sent",
        description:
          result.message ||
          `Successfully sent to ${result.successful ?? recipientUserIds.length} user(s).`,
      });
      setEmailOpen(false);
      resetEmailForm();
      setSelectedIds(new Set());
    },
    onError: (err: Error) => {
      const timedOut = /timeout/i.test(err.message || "");
      toast({
        title: timedOut ? "Email request timed out" : "Failed to send email",
        description: timedOut
          ? "Sending to all users is still running on the server. Wait a moment before trying again."
          : err.message || "Something went wrong.",
        variant: "destructive",
      });
    },
  });

  const notificationMutation = useMutation({
    mutationFn: () =>
      adminNotificationsApi.sendBulk({
        userIds: recipientUserIds,
        title: notificationTitle.trim(),
        body: notificationBody.trim(),
        type: notificationType,
      }),
    onSuccess: (result) => {
      toast({
        title: "Notification sent",
        description:
          result.message ||
          `Successfully sent to ${result.successful ?? recipientUserIds.length} user(s).`,
      });
      setNotificationOpen(false);
      resetNotificationForm();
      setSelectedIds(new Set());
    },
    onError: (err: Error) => {
      const timedOut = /timeout/i.test(err.message || "");
      toast({
        title: timedOut ? "Notification request timed out" : "Failed to send notification",
        description: timedOut
          ? "Sending to all users is still running on the server. Wait a moment before trying again."
          : err.message || "Something went wrong.",
        variant: "destructive",
      });
    },
  });

  const handleSendEmail = () => {
    if (!recipientUserIds.length) {
      toast({
        title: "No users to email",
        description: "There are no users matching the current list.",
        variant: "destructive",
      });
      return;
    }
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
    if (!recipientUserIds.length) {
      toast({
        title: "No users to notify",
        description: "There are no users matching the current list.",
        variant: "destructive",
      });
      return;
    }
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

  const handleSort = (key: SortKey) => {
    if (sortKey === key) {
      setSortDir((prev) => (prev === "asc" ? "desc" : "asc"));
    } else {
      setSortKey(key);
      setSortDir("asc");
    }
    setPage(1);
  };

  const SortableHead = ({
    label,
    column,
    className,
  }: {
    label: string;
    column: SortKey;
    className?: string;
  }) => (
    <TableHead className={cn("text-center text-slate-100", className)}>
      <button
        type="button"
        onClick={() => handleSort(column)}
        className="inline-flex w-full items-center justify-center gap-1.5 font-medium text-inherit hover:text-white"
      >
        {label}
        <SortIcon active={sortKey === column} direction={sortDir} />
      </button>
    </TableHead>
  );

  return (
    <>
      {metaElement}
      <div className="space-y-6 animate-fade-in">
        <PageTitle
          title="Users Master"
          icon={Users}
          description="Browse and manage registered app users"
        />

        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {isLoading ? (
            Array.from({ length: 3 }).map((_, i) => <StatCardSkeleton key={i} size="sm" />)
          ) : (
            <>
              <StatCard size="sm" title="Total Users" value={data.length} icon={Users} color="blue" />
              <StatCard
                size="sm"
                title="Installed"
                value={data.filter((u) => String(u.app_status || "").toUpperCase() === "ACTIVE").length}
                icon={Smartphone}
                color="emerald"
              />
              <StatCard
                size="sm"
                title="Likely Uninstalled"
                value={
                  data.filter(
                    (u) => String(u.app_status || "").toUpperCase() === "LIKELY_UNINSTALLED"
                  ).length
                }
                icon={UserX}
                color="violet"
              />
            </>
          )}
        </div>

        <div>
          <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div className="relative w-full sm:max-w-sm">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                value={search}
                onChange={(e) => {
                  setSearch(e.target.value);
                  setPage(1);
                }}
                placeholder="Search users..."
                className="pl-9"
              />
            </div>
            <div className="flex flex-wrap items-center justify-end gap-2">
              {selectedCount > 0 && (
                <p className="text-sm text-muted-foreground sm:mr-1">
                  Selected: <span className="font-semibold text-foreground">{selectedCount}</span>
                </p>
              )}
              <Select
                value={appStatusFilter}
                onValueChange={(value) => {
                  setAppStatusFilter(value as "ALL" | AppInstallStatus);
                  setPage(1);
                }}
              >
                <SelectTrigger className="h-9 w-full sm:w-44">
                  <SelectValue placeholder="Status" />
                </SelectTrigger>
                <SelectContent>
                  {APP_STATUS_FILTERS.map((option) => (
                    <SelectItem key={option.value} value={option.value}>
                      {option.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <Button
                variant="outline"
                size="sm"
                className="gap-2"
                onClick={() => refetch()}
                disabled={isFetching}
              >
                {isFetching ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
                Refresh
              </Button>
              <Button
                size="sm"
                className="gap-2 bg-emerald-600 text-white hover:bg-emerald-700"
                onClick={() => setEmailOpen(true)}
                disabled={recipientUserIds.length === 0}
              >
                <Mail className="h-4 w-4" />
                Send Email
              </Button>
              <Button
                size="sm"
                className="gap-2 bg-orange-500 text-white hover:bg-orange-600"
                onClick={() => setNotificationOpen(true)}
                disabled={recipientUserIds.length === 0}
              >
                <Bell className="h-4 w-4" />
                Send Notification
              </Button>
            </div>
          </div>

          {isError && (
            <div className="mb-4 rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3 text-sm text-destructive">
              {(error as Error)?.message || "Failed to load users."}
            </div>
          )}

          <div className="overflow-hidden rounded-xl border border-border/60">
            <Table>
              <TableHeader>
                <TableRow className="border-b border-slate-700/80 bg-slate-800 hover:bg-slate-800">
                  <TableHead className="w-12 text-center text-slate-100">
                    <div className="flex justify-center">
                      <Checkbox
                        checked={
                          allPageSelected
                            ? true
                            : somePageSelected
                              ? "indeterminate"
                              : false
                        }
                        onCheckedChange={(value) => togglePage(value === true)}
                        aria-label="Select all users on this page"
                        className="border-slate-300 data-[state=checked]:bg-primary data-[state=indeterminate]:bg-primary"
                      />
                    </div>
                  </TableHead>
                  <SortableHead label="S.No" column="sno" className="w-16" />
                  <SortableHead label="Name" column="name" />
                  <SortableHead label="App Status" column="app_status" />
                  <SortableHead label="Last Seen" column="last_seen_at" />
                  <SortableHead label="Last Login" column="last_login" />
                  <SortableHead label="City" column="city" />
                  <SortableHead label="Status" column="status" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading ? (
                  <TableRow>
                    <TableCell colSpan={8} className="h-28 text-center text-muted-foreground">
                      <div className="inline-flex items-center gap-2">
                        <Loader2 className="h-4 w-4 animate-spin" />
                        Loading users...
                      </div>
                    </TableCell>
                  </TableRow>
                ) : pageRows.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={8} className="h-28 text-center text-muted-foreground">
                      {search.trim() ? "No users match your search." : "No users found."}
                    </TableCell>
                  </TableRow>
                ) : (
                  pageRows.map((user, index) => {
                    const id = String(user.id);
                    const serialNo = (currentPage - 1) * limit + index + 1;
                    const checked = selectedIds.has(id);
                    const initials = (user.name || "U")
                      .split(" ")
                      .map((n) => n[0])
                      .join("")
                      .slice(0, 2)
                      .toUpperCase();
                    const isActive =
                      (user.status || "ACTIVE").toUpperCase() === "ACTIVE";
                    const accountStatus = (user.status || "ACTIVE").toUpperCase();
                    const isBlocked = accountStatus === "BLOCKED";
                    return (
                      <TableRow
                        key={id}
                        className={cn(
                          index % 2 === 1 && "bg-muted/20",
                          checked && "bg-primary/5"
                        )}
                      >
                        <TableCell>
                          <Checkbox
                            checked={checked}
                            onCheckedChange={(value) =>
                              toggleUser(user, value === true)
                            }
                            aria-label={`Select ${user.name || id}`}
                          />
                        </TableCell>
                        <TableCell className="text-center font-medium tabular-nums">{serialNo}</TableCell>
                        <TableCell>
                          <button
                            type="button"
                            onClick={() => navigate(`/users/${user.id}`)}
                            className="flex items-center gap-3 text-left"
                          >
                            <Avatar className="h-9 w-9">
                              <AvatarImage src={resolveImageUrl(user.profile_image_url)} />
                              <AvatarFallback className="bg-primary/10 text-xs font-semibold text-primary">
                                {initials}
                              </AvatarFallback>
                            </Avatar>
                            <p className="font-medium text-primary hover:underline">
                              {user.name || "N/A"}
                            </p>
                          </button>
                        </TableCell>
                        <TableCell className="text-center">
                          <Badge
                            className={cn(
                              "border-transparent",
                              appStatusClassName(user.app_status)
                            )}
                          >
                            {formatAppStatus(user.app_status)}
                          </Badge>
                        </TableCell>
                        <TableCell className="whitespace-nowrap text-muted-foreground">
                          {formatDateTime(user.last_seen_at)}
                        </TableCell>
                        <TableCell className="whitespace-nowrap text-muted-foreground">
                          {formatDateTime(user.last_login)}
                        </TableCell>
                        <TableCell>{displayValue(user.city)}</TableCell>
                        <TableCell>
                          <Badge
                            className={cn(
                              "border-transparent",
                              isActive
                                ? "bg-emerald-500/15 text-emerald-700 hover:bg-emerald-500/20"
                                : accountStatus === "DELETED"
                                  ? "bg-amber-500/15 text-amber-700 hover:bg-amber-500/20"
                                  : isBlocked
                                    ? "bg-orange-500/15 text-orange-700 hover:bg-orange-500/20"
                                  : "bg-rose-500/15 text-rose-700 hover:bg-rose-500/20"
                            )}
                          >
                            {accountStatus === "DELETED"
                              ? "Deleted"
                              : isBlocked
                                ? "Blocked"
                              : isActive
                                ? "Active"
                                : "Inactive"}
                          </Badge>
                        </TableCell>
                      </TableRow>
                    );
                  })
                )}
              </TableBody>
            </Table>
          </div>

          <div className="mt-4 flex flex-col gap-3 border-t border-border/50 pt-4 sm:flex-row sm:items-center sm:justify-between">
            <p className="text-sm text-muted-foreground">
              Showing {fromItem} to {toItem} of {totalItems}
            </p>
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
              <div className="flex items-center gap-2">
                <span className="text-sm text-muted-foreground">Show</span>
                <Select
                  value={String(limit)}
                  onValueChange={(value) => {
                    setLimit(Number(value));
                    setPage(1);
                  }}
                >
                  <SelectTrigger className="h-8 w-[80px]">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {PAGE_LIMITS.map((value) => (
                      <SelectItem key={value} value={String(value)}>
                        {value}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <span className="text-sm text-muted-foreground">entries</span>
              </div>
              <div className="flex items-center gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  className="h-8 gap-1"
                  disabled={currentPage <= 1}
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                >
                  <ChevronLeft className="h-4 w-4" />
                  Prev
                </Button>
                <span className="min-w-[90px] text-center text-sm tabular-nums text-muted-foreground">
                  Page {currentPage} of {totalPages}
                </span>
                <Button
                  variant="outline"
                  size="sm"
                  className="h-8 gap-1"
                  disabled={currentPage >= totalPages}
                  onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                >
                  Next
                  <ChevronRight className="h-4 w-4" />
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <Dialog
        open={emailOpen}
        onOpenChange={(open) => {
          setEmailOpen(open);
          if (!open) resetEmailForm();
        }}
      >
        <DialogContent className="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>
              {sendingToAll
                ? "Send Email to All Users"
                : "Send Email to Selected Users"}
            </DialogTitle>
          </DialogHeader>
          <p className="text-sm text-muted-foreground">
            {sendingToAll ? (
              <>
                Sending to all{" "}
                <span className="font-semibold text-foreground">
                  {recipientUserIds.length}
                </span>{" "}
                users
                {appStatusFilter !== "ALL" || search.trim()
                  ? " matching the current filters"
                  : ""}
                .
              </>
            ) : (
              <>
                Sending to{" "}
                <span className="font-semibold text-foreground">{selectedCount}</span>{" "}
                selected users.
              </>
            )}
          </p>
          <div className="space-y-4 py-2">
            <div className="space-y-2">
              <Label htmlFor="email-subject">Subject</Label>
              <Input
                id="email-subject"
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
              <Label htmlFor="email-body">Body</Label>
              <Textarea
                id="email-body"
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
            <DialogTitle>
              {sendingToAll
                ? "Send Notification to All Users"
                : "Send Notification to Selected Users"}
            </DialogTitle>
          </DialogHeader>
          <p className="text-sm text-muted-foreground">
            {sendingToAll ? (
              <>
                Sending to all{" "}
                <span className="font-semibold text-foreground">
                  {recipientUserIds.length}
                </span>{" "}
                users
                {appStatusFilter !== "ALL" || search.trim()
                  ? " matching the current filters"
                  : ""}
                .
              </>
            ) : (
              <>
                Sending to{" "}
                <span className="font-semibold text-foreground">{selectedCount}</span>{" "}
                selected users.
              </>
            )}
          </p>
          <div className="space-y-4 py-2">
            <div className="space-y-2">
              <Label htmlFor="notification-title">Title</Label>
              <Input
                id="notification-title"
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
              <Label htmlFor="notification-body">Body</Label>
              <Textarea
                id="notification-body"
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
