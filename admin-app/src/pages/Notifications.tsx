import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Bell,
  BellRing,
  CheckCircle2,
  MailOpen,
  RefreshCw,
  Loader2,
  Search,
  ChevronLeft,
  ChevronRight,
  Eye,
  Trash2,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
} from "lucide-react";
import { Link } from "react-router-dom";
import { PageTitle } from "@/components/ui/page-title";
import { StatCard, StatCardSkeleton } from "@/components/ui/stat-card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Checkbox } from "@/components/ui/checkbox";
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
  DialogDescription,
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
import { usePageMeta } from "@/hooks/usePageMeta";
import { toast } from "@/hooks/use-toast";
import {
  notificationsApi,
  type AdminNotificationItem,
} from "@/features/notifications/api";
import {
  displayValue,
  formatDateTime,
  formatLabel,
} from "@/lib/formatters";
import { cn } from "@/lib/utils";

const PAGE_LIMITS = [5, 10, 20, 50] as const;

type SortKey = "user" | "title" | "type" | "status";
type SortDir = "asc" | "desc";

function compareValues(
  a: string | number | boolean,
  b: string | number | boolean,
  dir: SortDir
) {
  if (a < b) return dir === "asc" ? -1 : 1;
  if (a > b) return dir === "asc" ? 1 : -1;
  return 0;
}

function SortIcon({
  active,
  direction,
}: {
  active: boolean;
  direction: SortDir;
}) {
  if (!active) return <ArrowUpDown className="h-3.5 w-3.5 opacity-50" />;
  return direction === "asc" ? (
    <ArrowUp className="h-3.5 w-3.5" />
  ) : (
    <ArrowDown className="h-3.5 w-3.5" />
  );
}

export default function Notifications() {
  const queryClient = useQueryClient();
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(10);
  const [search, setSearch] = useState("");
  const [sortKey, setSortKey] = useState<SortKey>("title");
  const [sortDir, setSortDir] = useState<SortDir>("asc");
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [viewItem, setViewItem] = useState<AdminNotificationItem | null>(null);
  const [deleteItem, setDeleteItem] = useState<AdminNotificationItem | null>(
    null
  );
  const [bulkDeleteOpen, setBulkDeleteOpen] = useState(false);

  const metaElement = usePageMeta({
    title: "Notifications",
    description: "Browse all user notifications",
  });

  const {
    data,
    isLoading,
    isFetching,
    isError,
    error,
    refetch,
  } = useQuery({
    queryKey: ["admin", "notifications", "all", page, limit],
    queryFn: () => notificationsApi.listAll({ page, limit }),
    staleTime: 30_000,
    refetchOnWindowFocus: false,
    placeholderData: (prev) => prev,
  });

  const deleteOneMutation = useMutation({
    mutationFn: (notificationId: string) =>
      notificationsApi.deleteOne(notificationId),
    onSuccess: (result, notificationId) => {
      toast({
        title: "Notification deleted",
        description:
          result?.message || "Notification deleted successfully.",
      });
      setDeleteItem(null);
      setSelectedIds((prev) => {
        const next = new Set(prev);
        next.delete(String(notificationId));
        return next;
      });
      queryClient.invalidateQueries({
        queryKey: ["admin", "notifications"],
      });
    },
    onError: (err: Error) => {
      toast({
        title: "Delete failed",
        description: err.message || "Unable to delete notification.",
        variant: "destructive",
      });
    },
  });

  const deleteBulkMutation = useMutation({
    mutationFn: (notificationIds: string[]) =>
      notificationsApi.deleteBulk(notificationIds),
    onSuccess: (result) => {
      toast({
        title: "Notifications deleted",
        description:
          result?.message ||
          `Deleted ${result?.deletedCount ?? selectedIds.size} notification(s).`,
      });
      setBulkDeleteOpen(false);
      setSelectedIds(new Set());
      queryClient.invalidateQueries({
        queryKey: ["admin", "notifications"],
      });
    },
    onError: (err: Error) => {
      toast({
        title: "Bulk delete failed",
        description: err.message || "Unable to delete selected notifications.",
        variant: "destructive",
      });
    },
  });

  const rows = data?.data ?? [];
  const totalItems = data?.totalCount ?? 0;
  const totalPages = Math.max(1, data?.pages ?? 1);
  const unreadCount = data?.unreadCount ?? 0;

  const summary = useMemo(() => {
    const read = rows.filter((item) => item.isRead).length;
    const unreadOnPage = rows.filter((item) => !item.isRead).length;
    return {
      total: totalItems,
      unread: unreadCount || unreadOnPage,
      readOnPage: read,
      pageCount: rows.length,
    };
  }, [rows, totalItems, unreadCount]);

  const displayRows = useMemo(() => {
    const q = search.trim().toLowerCase();
    let list = [...rows];

    if (q) {
      list = list.filter((item) => {
        const haystack = [
          item.title,
          item.body,
          item.type,
          item.userName,
          item.userId,
          item.isRead ? "read" : "unread",
        ]
          .join(" ")
          .toLowerCase();
        return haystack.includes(q);
      });
    }

    list.sort((a, b) => {
      switch (sortKey) {
        case "user":
          return compareValues(
            (a.userName || "").toLowerCase(),
            (b.userName || "").toLowerCase(),
            sortDir
          );
        case "title":
          return compareValues(
            (a.title || "").toLowerCase(),
            (b.title || "").toLowerCase(),
            sortDir
          );
        case "type":
          return compareValues(
            (a.type || "").toLowerCase(),
            (b.type || "").toLowerCase(),
            sortDir
          );
        case "status":
          return compareValues(Number(a.isRead), Number(b.isRead), sortDir);
        default:
          return 0;
      }
    });

    return list;
  }, [rows, search, sortKey, sortDir]);

  const selectedCount = selectedIds.size;
  const pageIds = displayRows.map((item) => String(item.id));
  const allPageSelected =
    pageIds.length > 0 && pageIds.every((id) => selectedIds.has(id));
  const somePageSelected =
    pageIds.some((id) => selectedIds.has(id)) && !allPageSelected;

  const toggleRow = (id: string, checked: boolean) => {
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

  const handleSort = (key: SortKey) => {
    if (sortKey === key) {
      setSortDir((prev) => (prev === "asc" ? "desc" : "asc"));
    } else {
      setSortKey(key);
      setSortDir("asc");
    }
  };

  const handleLimitChange = (value: string) => {
    setLimit(Number(value));
    setPage(1);
    setSelectedIds(new Set());
  };

  const handlePageChange = (nextPage: number) => {
    if (nextPage < 1 || nextPage > totalPages) return;
    setPage(nextPage);
    setSelectedIds(new Set());
  };

  const fromItem = totalItems === 0 ? 0 : (page - 1) * limit + 1;
  const toItem = Math.min(page * limit, totalItems);
  const isDeleting =
    deleteOneMutation.isPending || deleteBulkMutation.isPending;

  const SortableHead = ({
    label,
    column,
    className,
  }: {
    label: string;
    column: SortKey;
    className?: string;
  }) => (
    <TableHead className={className}>
      <button
        type="button"
        onClick={() => handleSort(column)}
        className="inline-flex items-center gap-1.5 font-medium text-inherit hover:text-white"
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
          title="Notifications"
          icon={Bell}
          description="Browse all user notifications across the platform"
        />

        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {isLoading ? (
            Array.from({ length: 4 }).map((_, i) => <StatCardSkeleton key={i} />)
          ) : (
            <>
              <StatCard
                title="Total Notifications"
                value={summary.total}
                icon={Bell}
                color="blue"
              />
              <StatCard
                title="Unread"
                value={summary.unread}
                icon={BellRing}
                color="amber"
              />
              <StatCard
                title="Read (this page)"
                value={summary.readOnPage}
                icon={CheckCircle2}
                color="emerald"
              />
              <StatCard
                title="Rows on page"
                value={summary.pageCount}
                icon={MailOpen}
                color="violet"
              />
            </>
          )}
        </div>

        <div className="glass-card p-4 sm:p-6">
          <div className="mb-4 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <h2 className="text-lg font-semibold">Notification List</h2>
              <p className="mt-1 text-sm text-muted-foreground">
                Server-paginated list of all notifications
              </p>
            </div>

            <div className="flex flex-col gap-2 sm:flex-row sm:flex-wrap sm:items-center">
              {selectedCount > 0 && (
                <>
                  <p className="text-sm text-muted-foreground sm:mr-1">
                    Selected:{" "}
                    <span className="font-semibold text-foreground">
                      {selectedCount}
                    </span>
                  </p>
                  <Button
                    variant="destructive"
                    size="sm"
                    className="gap-2"
                    onClick={() => setBulkDeleteOpen(true)}
                    disabled={isDeleting}
                  >
                    <Trash2 className="h-4 w-4" />
                    Delete All
                  </Button>
                </>
              )}
              <div className="relative w-full sm:w-72">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <Input
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Search title, user, type..."
                  className="pl-9"
                />
              </div>
              <Button
                variant="outline"
                size="sm"
                className="gap-2"
                onClick={() => refetch()}
                disabled={isFetching}
              >
                {isFetching ? (
                  <Loader2 className="h-4 w-4 animate-spin" />
                ) : (
                  <RefreshCw className="h-4 w-4" />
                )}
                Refresh
              </Button>
            </div>
          </div>

          {isError && (
            <div className="mb-4 rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3 text-sm text-destructive">
              {(error as Error)?.message || "Failed to load notifications."}
            </div>
          )}

          <div className="overflow-hidden rounded-xl border border-border/60">
            <Table>
              <TableHeader>
                <TableRow className="border-b border-slate-700/80 bg-slate-800 hover:bg-slate-800 dark:bg-slate-900 dark:hover:bg-slate-900">
                  <TableHead className="w-12 text-slate-100">
                    <Checkbox
                      checked={
                        allPageSelected
                          ? true
                          : somePageSelected
                            ? "indeterminate"
                            : false
                      }
                      onCheckedChange={(value) => togglePage(value === true)}
                      aria-label="Select all notifications on this page"
                      className="border-slate-300 data-[state=checked]:bg-primary data-[state=indeterminate]:bg-primary"
                    />
                  </TableHead>
                  <TableHead className="w-16 text-slate-100">S.No</TableHead>
                  <SortableHead
                    label="User"
                    column="user"
                    className="text-slate-100"
                  />
                  <SortableHead
                    label="Title"
                    column="title"
                    className="text-slate-100"
                  />
                  <SortableHead
                    label="Type"
                    column="type"
                    className="text-slate-100"
                  />
                  <SortableHead
                    label="Status"
                    column="status"
                    className="text-slate-100"
                  />
                  <TableHead className="w-[140px] text-center text-slate-100">
                    Action
                  </TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading ? (
                  <TableRow>
                    <TableCell
                      colSpan={7}
                      className="h-28 text-center text-muted-foreground"
                    >
                      <div className="inline-flex items-center gap-2">
                        <Loader2 className="h-4 w-4 animate-spin" />
                        Loading notifications...
                      </div>
                    </TableCell>
                  </TableRow>
                ) : displayRows.length === 0 ? (
                  <TableRow>
                    <TableCell
                      colSpan={7}
                      className="h-28 text-center text-muted-foreground"
                    >
                      {search.trim()
                        ? "No notifications match your search on this page."
                        : "No notifications found."}
                    </TableCell>
                  </TableRow>
                ) : (
                  displayRows.map((item, index) => {
                    const id = String(item.id);
                    const checked = selectedIds.has(id);
                    return (
                      <TableRow
                        key={id}
                        className={cn(index % 2 === 1 && "bg-muted/20")}
                      >
                        <TableCell>
                          <Checkbox
                            checked={checked}
                            onCheckedChange={(value) =>
                              toggleRow(id, value === true)
                            }
                            aria-label={`Select notification ${id}`}
                          />
                        </TableCell>
                        <TableCell className="font-medium tabular-nums">
                          {(page - 1) * limit + index + 1}
                        </TableCell>
                        <TableCell>
                          {item.userId ? (
                            <Link
                              to={`/users/${item.userId}`}
                              className="font-medium text-primary hover:underline"
                            >
                              {displayValue(item.userName)}
                            </Link>
                          ) : (
                            <span className="font-medium">
                              {displayValue(item.userName)}
                            </span>
                          )}
                        </TableCell>
                        <TableCell>
                          <div className="max-w-[320px]">
                            <p className="font-medium">{item.title}</p>
                            <p className="line-clamp-2 text-xs text-muted-foreground">
                              {item.body}
                            </p>
                          </div>
                        </TableCell>
                        <TableCell>
                          <Badge className="border-transparent bg-violet-500/15 text-violet-700 hover:bg-violet-500/20 dark:text-violet-300">
                            {formatLabel(item.type)}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <Badge
                            className={cn(
                              "border-transparent",
                              item.isRead
                                ? "bg-emerald-500/15 text-emerald-700 hover:bg-emerald-500/20 dark:text-emerald-300"
                                : "bg-amber-500/15 text-amber-700 hover:bg-amber-500/20 dark:text-amber-300"
                            )}
                          >
                            {item.isRead ? "Read" : "Unread"}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center justify-center gap-1.5">
                            <Button
                              size="icon"
                              variant="outline"
                              title="View"
                              aria-label="View"
                              className="h-8 w-8 border-sky-300 bg-sky-50 text-sky-700 hover:bg-sky-100 dark:border-sky-700 dark:bg-sky-950/40 dark:text-sky-300"
                              onClick={() => setViewItem(item)}
                            >
                              <Eye className="h-4 w-4" />
                            </Button>
                            <Button
                              size="icon"
                              variant="outline"
                              title="Delete"
                              aria-label="Delete"
                              className="h-8 w-8 border-rose-300 bg-rose-50 text-rose-700 hover:bg-rose-100 dark:border-rose-700 dark:bg-rose-950/40 dark:text-rose-300"
                              onClick={() => setDeleteItem(item)}
                              disabled={isDeleting}
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </div>
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
              {search.trim()
                ? ` · ${displayRows.length} match on this page`
                : ""}
            </p>

            <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
              <div className="flex items-center gap-2">
                <span className="whitespace-nowrap text-sm text-muted-foreground">
                  Rows per page
                </span>
                <Select value={String(limit)} onValueChange={handleLimitChange}>
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
              </div>

              <div className="flex items-center gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  className="h-8 gap-1"
                  disabled={page <= 1 || isFetching}
                  onClick={() => handlePageChange(page - 1)}
                >
                  <ChevronLeft className="h-4 w-4" />
                  Prev
                </Button>
                <span className="min-w-[90px] text-center text-sm tabular-nums text-muted-foreground">
                  Page {page} of {totalPages}
                </span>
                <Button
                  variant="outline"
                  size="sm"
                  className="h-8 gap-1"
                  disabled={page >= totalPages || isFetching}
                  onClick={() => handlePageChange(page + 1)}
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
        open={!!viewItem}
        onOpenChange={(open) => !open && setViewItem(null)}
      >
        <DialogContent className="max-h-[90vh] max-w-2xl overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Notification Details</DialogTitle>
            <DialogDescription>
              Full notification record for review
            </DialogDescription>
          </DialogHeader>

          {viewItem && (
            <div className="space-y-4">
              <div className="grid gap-3 sm:grid-cols-2">
                {[
                  ["USER", viewItem.userName],
                  ["USER EMAIL", viewItem.userEmail],
                  ["USER MOBILE", viewItem.userMobile],
                  ["TYPE", formatLabel(viewItem.type)],
                  ["STATUS", viewItem.isRead ? "Read" : "Unread"],
                  ["CREATED AT", formatDateTime(viewItem.createdAt)],
                  ["UPDATED AT", formatDateTime(viewItem.updatedAt)],
                  ["READ AT", formatDateTime(viewItem.readAt)],
                ].map(([label, value]) => (
                  <div
                    key={label}
                    className="rounded-lg border border-border/60 bg-muted/20 p-3"
                  >
                    <p className="text-[11px] font-semibold uppercase tracking-wide text-muted-foreground">
                      {label}
                    </p>
                    <p className="mt-1 break-words text-sm font-medium">
                      {displayValue(value)}
                    </p>
                  </div>
                ))}
              </div>

              <div className="space-y-2">
                <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                  Title
                </p>
                <div className="rounded-lg border border-border/60 bg-muted/20 p-3 text-sm font-medium">
                  {viewItem.title || "—"}
                </div>
              </div>

              <div className="space-y-2">
                <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                  Body
                </p>
                <div className="rounded-lg border border-border/60 bg-muted/20 p-3 text-sm whitespace-pre-wrap">
                  {viewItem.body || "—"}
                </div>
              </div>
            </div>
          )}

          <DialogFooter className="gap-2 sm:gap-2">
            <Button variant="outline" onClick={() => setViewItem(null)}>
              Close
            </Button>
            {viewItem && (
              <Button
                variant="destructive"
                className="gap-2"
                onClick={() => {
                  setDeleteItem(viewItem);
                  setViewItem(null);
                }}
              >
                <Trash2 className="h-4 w-4" />
                Delete
              </Button>
            )}
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <AlertDialog
        open={!!deleteItem}
        onOpenChange={(open) => !open && setDeleteItem(null)}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete notification?</AlertDialogTitle>
            <AlertDialogDescription>
              This will permanently delete the notification
              {deleteItem?.title ? (
                <>
                  {" "}
                  <span className="font-medium text-foreground">
                    “{deleteItem.title}”
                  </span>
                </>
              ) : null}
              . This action cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleteOneMutation.isPending}>
              Cancel
            </AlertDialogCancel>
            <AlertDialogAction
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              disabled={deleteOneMutation.isPending || !deleteItem}
              onClick={(e) => {
                e.preventDefault();
                if (!deleteItem) return;
                deleteOneMutation.mutate(String(deleteItem.id));
              }}
            >
              {deleteOneMutation.isPending ? (
                <span className="inline-flex items-center gap-2">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Deleting...
                </span>
              ) : (
                "Confirm delete"
              )}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <AlertDialog open={bulkDeleteOpen} onOpenChange={setBulkDeleteOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete selected notifications?</AlertDialogTitle>
            <AlertDialogDescription>
              This will permanently delete{" "}
              <span className="font-medium text-foreground">
                {selectedCount}
              </span>{" "}
              selected notification{selectedCount === 1 ? "" : "s"}. This action
              cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleteBulkMutation.isPending}>
              Cancel
            </AlertDialogCancel>
            <AlertDialogAction
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              disabled={deleteBulkMutation.isPending || selectedCount === 0}
              onClick={(e) => {
                e.preventDefault();
                deleteBulkMutation.mutate(Array.from(selectedIds));
              }}
            >
              {deleteBulkMutation.isPending ? (
                <span className="inline-flex items-center gap-2">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Deleting...
                </span>
              ) : (
                "Delete All"
              )}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
