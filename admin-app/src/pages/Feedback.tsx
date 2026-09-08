import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  MessageSquare,
  CheckCircle2,
  Clock3,
  RefreshCw,
  Loader2,
  Search,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  Eye,
  Reply,
  Trash2,
  Send,
  ChevronLeft,
  ChevronRight,
} from "lucide-react";
import { PageTitle } from "@/components/ui/page-title";
import { StatCard, StatCardSkeleton } from "@/components/ui/stat-card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
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
  feedbacksApi,
  type FeedbackItem,
  type FeedbackStatus,
} from "@/features/feedbacks/api";
import { cn } from "@/lib/utils";

const PAGE_LIMITS = [5, 10, 20, 50] as const;

type SortKey = "userName" | "status" | "message";

type SortDir = "asc" | "desc";

function formatDateTime(value?: string | null): string {
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
  const seconds = String(date.getSeconds()).padStart(2, "0");
  const ampm = hours >= 12 ? "PM" : "AM";
  hours = hours % 12 || 12;

  return `${day}-${month}-${year} ${String(hours).padStart(2, "0")}:${minutes}:${seconds} ${ampm}`;
}

function formatLabel(value?: string | null): string {
  if (!value) return "—";
  return value
    .toLowerCase()
    .split("_")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function isPendingStatus(status?: string | null): boolean {
  const normalized = (status || "").toUpperCase();
  return normalized !== "RESOLVED";
}

function compareValues(a: string | number, b: string | number, dir: SortDir) {
  if (a < b) return dir === "asc" ? -1 : 1;
  if (a > b) return dir === "asc" ? 1 : -1;
  return 0;
}

function truncate(text?: string | null, max = 72): string {
  if (!text) return "—";
  if (text.length <= max) return text;
  return `${text.slice(0, max)}…`;
}

function SortIcon({ active, direction }: { active: boolean; direction: SortDir }) {
  if (!active) return <ArrowUpDown className="h-3.5 w-3.5 opacity-50" />;
  return direction === "asc" ? (
    <ArrowUp className="h-3.5 w-3.5" />
  ) : (
    <ArrowDown className="h-3.5 w-3.5" />
  );
}

export default function Feedback() {
  const [search, setSearch] = useState("");
  const [sortKey, setSortKey] = useState<SortKey>("userName");
  const [sortDir, setSortDir] = useState<SortDir>("asc");
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(10);

  const [viewItem, setViewItem] = useState<FeedbackItem | null>(null);
  const [replyItem, setReplyItem] = useState<FeedbackItem | null>(null);
  const [deleteItem, setDeleteItem] = useState<FeedbackItem | null>(null);
  const [replyStatus, setReplyStatus] = useState<FeedbackStatus>("IN_PROGRESS");
  const [replyText, setReplyText] = useState("");

  const queryClient = useQueryClient();
  const metaElement = usePageMeta({
    title: "Feedbacks",
    description: "Review user messages and send replies",
  });

  const { data, isLoading, isFetching, isError, error, refetch } = useQuery({
    queryKey: ["admin", "feedbacks"],
    queryFn: () => feedbacksApi.list(),
    staleTime: 30_000,
    refetchOnWindowFocus: false,
  });

  const replyMutation = useMutation({
    mutationFn: () =>
      feedbacksApi.reply({
        feedbackId: String(replyItem!.id),
        adminResponse: replyText.trim(),
        status: replyStatus,
      }),
    onSuccess: (result) => {
      toast({
        title: "Reply sent",
        description: result?.message || "Feedback reply saved successfully",
      });
      setReplyItem(null);
      setReplyText("");
      queryClient.invalidateQueries({ queryKey: ["admin", "feedbacks"] });
    },
    onError: (err: Error) => {
      toast({
        title: "Reply failed",
        description: err.message || "Unable to send reply",
        variant: "destructive",
      });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: () => feedbacksApi.delete(String(deleteItem!.id)),
    onSuccess: (result) => {
      toast({
        title: "Deleted",
        description: result?.message || "Feedback deleted successfully!",
      });
      setDeleteItem(null);
      setViewItem(null);
      queryClient.invalidateQueries({ queryKey: ["admin", "feedbacks"] });
    },
    onError: (err: Error) => {
      toast({
        title: "Delete failed",
        description: err.message || "Unable to delete feedback",
        variant: "destructive",
      });
    },
  });

  const rows = data?.data ?? [];

  const summary = useMemo(() => {
    const total = data?.count ?? rows.length;
    const resolved = rows.filter((item) => !isPendingStatus(item.status)).length;
    const pending = rows.filter((item) => isPendingStatus(item.status)).length;
    return { total, resolved, pending };
  }, [data?.count, rows]);

  const filteredSorted = useMemo(() => {
    const q = search.trim().toLowerCase();
    let list = [...rows];

    if (q) {
      list = list.filter((item) => {
        const haystack = [
          item.userName,
          item.userEmail,
          item.type,
          item.status,
          item.message,
          item.adminResponse,
        ]
          .join(" ")
          .toLowerCase();
        return haystack.includes(q);
      });
    }

    list.sort((a, b) => {
      switch (sortKey) {
        case "userName":
          return compareValues(
            (a.userName || "").toLowerCase(),
            (b.userName || "").toLowerCase(),
            sortDir
          );
        case "status":
          return compareValues(
            (a.status || "").toLowerCase(),
            (b.status || "").toLowerCase(),
            sortDir
          );
        case "message":
          return compareValues(
            (a.message || "").toLowerCase(),
            (b.message || "").toLowerCase(),
            sortDir
          );
        default:
          return 0;
      }
    });

    return list;
  }, [rows, search, sortKey, sortDir]);

  const totalItems = filteredSorted.length;
  const totalPages = Math.max(1, Math.ceil(totalItems / limit));
  const currentPage = Math.min(page, totalPages);
  const pageRows = filteredSorted.slice(
    (currentPage - 1) * limit,
    currentPage * limit
  );
  const fromItem = totalItems === 0 ? 0 : (currentPage - 1) * limit + 1;
  const toItem = Math.min(currentPage * limit, totalItems);

  const handleSort = (key: SortKey) => {
    if (sortKey === key) {
      setSortDir((prev) => (prev === "asc" ? "desc" : "asc"));
    } else {
      setSortKey(key);
      setSortDir("asc");
    }
  };

  const openReply = (item: FeedbackItem) => {
    setReplyItem(item);
    setReplyText(item.adminResponse || "");
    setReplyStatus(
      isPendingStatus(item.status) ? "IN_PROGRESS" : "RESOLVED"
    );
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
          title="Feedbacks"
          icon={MessageSquare}
          description="Review user messages and send replies"
        />

        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {isLoading ? (
            Array.from({ length: 3 }).map((_, i) => <StatCardSkeleton key={i} />)
          ) : (
            <>
              <StatCard
                title="Total Feedbacks"
                value={summary.total}
                icon={MessageSquare}
                color="blue"
              />
              <StatCard
                title="Resolved"
                value={summary.resolved}
                icon={CheckCircle2}
                color="emerald"
              />
              <StatCard
                title="Pending Replies"
                value={summary.pending}
                icon={Clock3}
                color="amber"
              />
            </>
          )}
        </div>

        <div className="glass-card p-4 sm:p-6">
          <div className="mb-4 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <h2 className="text-lg font-semibold">All Feedbacks</h2>
              <p className="mt-1 text-sm text-muted-foreground">
                Manage user feedback messages and admin replies
              </p>
            </div>

            <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
              <div className="relative w-full sm:w-64">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <Input
                  value={search}
                  onChange={(e) => {
                    setSearch(e.target.value);
                    setPage(1);
                  }}
                  placeholder="Search user, message, status..."
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
              {(error as Error)?.message || "Failed to load feedbacks."}
            </div>
          )}

          <div className="overflow-hidden rounded-xl border border-border/60">
            <Table>
              <TableHeader>
                <TableRow className="border-b border-slate-700/80 bg-slate-800 hover:bg-slate-800 dark:bg-slate-900 dark:hover:bg-slate-900">
                  <TableHead className="w-16 text-slate-100">S.No</TableHead>
                  <SortableHead label="User" column="userName" className="text-slate-100" />
                  <SortableHead label="Status" column="status" className="text-slate-100" />
                  <SortableHead label="Message" column="message" className="text-slate-100" />
                  <TableHead className="w-[120px] text-center text-slate-100">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading ? (
                  <TableRow>
                    <TableCell colSpan={5} className="h-28 text-center text-muted-foreground">
                      <div className="inline-flex items-center gap-2">
                        <Loader2 className="h-4 w-4 animate-spin" />
                        Loading feedbacks...
                      </div>
                    </TableCell>
                  </TableRow>
                ) : pageRows.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={5} className="h-28 text-center text-muted-foreground">
                      {search.trim()
                        ? "No feedbacks match your search."
                        : "No feedbacks found."}
                    </TableCell>
                  </TableRow>
                ) : (
                  pageRows.map((item, index) => {
                    const pending = isPendingStatus(item.status);
                    const serialNo = (currentPage - 1) * limit + index + 1;
                    return (
                      <TableRow
                        key={item.id}
                        className={cn(index % 2 === 1 && "bg-muted/20")}
                      >
                        <TableCell className="font-medium tabular-nums">
                          {serialNo}
                        </TableCell>
                        <TableCell>
                          <div className="min-w-[150px]">
                            <p className="font-medium">{item.userName || "—"}</p>
                            <p className="text-xs text-muted-foreground">
                              {item.userEmail || "—"}
                            </p>
                          </div>
                        </TableCell>
                        <TableCell>
                          <Badge
                            className={cn(
                              "border-transparent",
                              pending
                                ? "bg-amber-500/15 text-amber-700 hover:bg-amber-500/20 dark:text-amber-300"
                                : "bg-emerald-500/15 text-emerald-700 hover:bg-emerald-500/20 dark:text-emerald-300"
                            )}
                          >
                            {formatLabel(item.status)}
                          </Badge>
                        </TableCell>
                        <TableCell className="max-w-[360px]">
                          <p className="line-clamp-2 text-sm">{truncate(item.message, 120)}</p>
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
                              title="Reply"
                              aria-label="Reply"
                              className="h-8 w-8 border-teal-300 bg-teal-50 text-teal-700 hover:bg-teal-100 dark:border-teal-700 dark:bg-teal-950/40 dark:text-teal-300"
                              onClick={() => openReply(item)}
                            >
                              <Reply className="h-4 w-4" />
                            </Button>
                            <Button
                              size="icon"
                              variant="outline"
                              title="Delete"
                              aria-label="Delete"
                              className="h-8 w-8 border-rose-300 bg-rose-50 text-rose-700 hover:bg-rose-100 dark:border-rose-700 dark:bg-rose-950/40 dark:text-rose-300"
                              onClick={() => setDeleteItem(item)}
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
            </p>
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
              <div className="flex items-center gap-2">
                <span className="whitespace-nowrap text-sm text-muted-foreground">
                  Rows per page
                </span>
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

      {/* View details */}
      <Dialog open={!!viewItem} onOpenChange={(open) => !open && setViewItem(null)}>
        <DialogContent className="max-h-[90vh] max-w-2xl overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Feedback Details</DialogTitle>
            <DialogDescription>
              Full feedback record and admin response
            </DialogDescription>
          </DialogHeader>

          {viewItem && (
            <div className="space-y-4">
              <div className="grid gap-3 sm:grid-cols-2">
                {[
                  ["USER NAME", viewItem.userName],
                  ["USER EMAIL", viewItem.userEmail],
                  ["TYPE", formatLabel(viewItem.type)],
                  ["STATUS", formatLabel(viewItem.status)],
                  ["RESPONDED AT", formatDateTime(viewItem.respondedAt)],
                  ["CREATED AT", formatDateTime(viewItem.createdAt)],
                  ["UPDATED AT", formatDateTime(viewItem.updatedAt)],
                ].map(([label, value]) => (
                  <div key={label} className="rounded-lg border border-border/60 bg-muted/20 p-3">
                    <p className="text-[11px] font-semibold uppercase tracking-wide text-muted-foreground">
                      {label}
                    </p>
                    <p className="mt-1 break-words text-sm font-medium">{value || "—"}</p>
                  </div>
                ))}
              </div>

              <div className="space-y-2">
                <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                  User Message
                </p>
                <div className="rounded-lg border border-border/60 bg-muted/20 p-3 text-sm whitespace-pre-wrap">
                  {viewItem.message || "—"}
                </div>
              </div>

              <div className="space-y-2">
                <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                  Admin Response
                </p>
                <div className="rounded-lg border border-border/60 bg-muted/20 p-3 text-sm whitespace-pre-wrap">
                  {viewItem.adminResponse || "—"}
                </div>
              </div>
            </div>
          )}

          <DialogFooter className="gap-2 sm:gap-2">
            <Button variant="outline" onClick={() => setViewItem(null)}>
              Close
            </Button>
            {viewItem && (
              <>
                <Button
                  className="gap-2"
                  onClick={() => {
                    openReply(viewItem);
                    setViewItem(null);
                  }}
                >
                  <Reply className="h-4 w-4" />
                  Reply
                </Button>
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
              </>
            )}
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Reply modal */}
      <Dialog open={!!replyItem} onOpenChange={(open) => !open && setReplyItem(null)}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>Reply to Feedback</DialogTitle>
            <DialogDescription>
              Update status and send an admin response
            </DialogDescription>
          </DialogHeader>

          {replyItem && (
            <div className="space-y-4">
              <div className="rounded-lg border-l-4 border-l-primary bg-primary/5 p-3">
                <p className="text-sm font-semibold">
                  {replyItem.userName}{" "}
                  <span className="font-normal text-muted-foreground">
                    ({replyItem.userEmail})
                  </span>
                </p>
                <p className="mt-2 text-sm whitespace-pre-wrap">{replyItem.message}</p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="reply-status">Status</Label>
                <Select
                  value={replyStatus}
                  onValueChange={(value) => setReplyStatus(value as FeedbackStatus)}
                >
                  <SelectTrigger id="reply-status">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="IN_PROGRESS">In Progress</SelectItem>
                    <SelectItem value="RESOLVED">Resolved</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="admin-response">Admin Response</Label>
                <Textarea
                  id="admin-response"
                  value={replyText}
                  onChange={(e) => setReplyText(e.target.value)}
                  placeholder="Type the admin reply here"
                  rows={5}
                />
              </div>
            </div>
          )}

          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setReplyItem(null)}
              disabled={replyMutation.isPending}
            >
              Cancel
            </Button>
            <Button
              className="gap-2"
              disabled={!replyText.trim() || replyMutation.isPending}
              onClick={() => replyMutation.mutate()}
            >
              {replyMutation.isPending ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <Send className="h-4 w-4" />
              )}
              Send Reply
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete confirmation */}
      <AlertDialog
        open={!!deleteItem}
        onOpenChange={(open) => !open && setDeleteItem(null)}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <div className="mb-2 flex h-12 w-12 items-center justify-center rounded-full bg-rose-100 text-rose-600 dark:bg-rose-950/50 dark:text-rose-300">
              <Trash2 className="h-5 w-5" />
            </div>
            <AlertDialogTitle>Delete Feedback?</AlertDialogTitle>
            <AlertDialogDescription>
              This will permanently delete the feedback from{" "}
              <span className="font-semibold text-foreground">
                {deleteItem?.userName || "this user"}
              </span>
              .
            </AlertDialogDescription>
          </AlertDialogHeader>

          {deleteItem && (
            <div className="rounded-lg border border-border bg-muted/30 p-3 text-sm">
              <div className="flex justify-between gap-4">
                <span className="text-muted-foreground">Feedback ID</span>
                <span className="font-medium">{deleteItem.id}</span>
              </div>
              <div className="mt-2 flex justify-between gap-4">
                <span className="text-muted-foreground">Type</span>
                <span className="font-medium">{formatLabel(deleteItem.type)}</span>
              </div>
            </div>
          )}

          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleteMutation.isPending}>
              Cancel
            </AlertDialogCancel>
            <AlertDialogAction
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              disabled={deleteMutation.isPending}
              onClick={(e) => {
                e.preventDefault();
                deleteMutation.mutate();
              }}
            >
              {deleteMutation.isPending ? (
                <span className="inline-flex items-center gap-2">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Deleting...
                </span>
              ) : (
                "Yes, Delete"
              )}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
