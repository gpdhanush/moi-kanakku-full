import { useState } from "react";
import { Link } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  BadgeIndianRupee,
  Check,
  ChevronLeft,
  ChevronRight,
  Clock,
  Loader2,
  RefreshCw,
  Search,
  X,
  XCircle,
} from "lucide-react";
import { PageTitle } from "@/components/ui/page-title";
import { StatCard, StatCardSkeleton } from "@/components/ui/stat-card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
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
import { usePageMeta } from "@/hooks/usePageMeta";
import { toast } from "@/hooks/use-toast";
import {
  exportPaymentsApi,
  type ExportPayment,
  type ExportPaymentStatus,
  type ExportPaymentStatusFilter,
} from "@/features/export-payments/api";
import { PaymentSettingsCard } from "@/features/export-payments/PaymentSettingsCard";
import { displayValue, formatDateTime } from "@/lib/formatters";
import { cn } from "@/lib/utils";

const PAGE_LIMITS = [10, 20, 50] as const;
const STATUS_FILTERS: { value: ExportPaymentStatusFilter; label: string }[] = [
  { value: "pending", label: "Pending" },
  { value: "approved", label: "Approved" },
  { value: "rejected", label: "Rejected" },
  { value: "all", label: "All statuses" },
];

const STATUS_STYLES: Record<ExportPaymentStatus, string> = {
  pending: "border-transparent bg-amber-500/15 text-amber-700 dark:text-amber-300",
  approved:
    "border-transparent bg-emerald-500/15 text-emerald-700 dark:text-emerald-300",
  rejected: "border-transparent bg-rose-500/15 text-rose-700 dark:text-rose-300",
};

const formatAmount = (amount: number) =>
  `₹${Number(amount || 0).toLocaleString("en-IN", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })}`;

type ReviewTarget = { payment: ExportPayment; action: "approve" | "reject" };

export default function ExportPayments() {
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(10);
  const [status, setStatus] = useState<ExportPaymentStatusFilter>("pending");
  const [search, setSearch] = useState("");
  const [submittedSearch, setSubmittedSearch] = useState("");
  const [reviewTarget, setReviewTarget] = useState<ReviewTarget | null>(null);
  const [remarks, setRemarks] = useState("");

  const queryClient = useQueryClient();
  const metaElement = usePageMeta({
    title: "Export Payments",
    description: "Verify UPI payments for paid PDF export",
  });

  const { data, isLoading, isFetching, isError, error, refetch } = useQuery({
    queryKey: ["admin", "export-payments", page, limit, status, submittedSearch],
    queryFn: () =>
      exportPaymentsApi.list({ page, limit, status, search: submittedSearch }),
    staleTime: 15_000,
    placeholderData: (prev) => prev,
  });

  const reviewMutation = useMutation({
    mutationFn: (target: ReviewTarget) =>
      exportPaymentsApi.review({
        paymentId: target.payment.id,
        action: target.action,
        remarks: remarks.trim() || undefined,
      }),
    onSuccess: (_result, target) => {
      toast({
        title: target.action === "approve" ? "Payment approved" : "Payment rejected",
        description:
          target.action === "approve"
            ? `${target.payment.userName || "The user"} can now make 3 PDF exports.`
            : "The user can submit a new transaction ID.",
      });
      closeReview();
      queryClient.invalidateQueries({ queryKey: ["admin", "export-payments"] });
    },
    onError: (err: Error) => {
      toast({
        title: "Update failed",
        description: err.message || "Unable to update payment.",
        variant: "destructive",
      });
      queryClient.invalidateQueries({ queryKey: ["admin", "export-payments"] });
    },
  });

  const openReview = (payment: ExportPayment, action: "approve" | "reject") => {
    setRemarks("");
    setReviewTarget({ payment, action });
  };

  const closeReview = () => {
    setReviewTarget(null);
    setRemarks("");
  };

  const rows = data?.data ?? [];
  const stats = data?.stats;
  const totalItems = data?.pagination.total ?? 0;
  const totalPages = Math.max(1, data?.pagination.totalPages ?? 1);
  const fromItem = totalItems === 0 ? 0 : (page - 1) * limit + 1;
  const toItem = Math.min(page * limit, totalItems);
  const rejectNeedsReason =
    reviewTarget?.action === "reject" && remarks.trim().length === 0;

  return (
    <>
      {metaElement}
      <div className="space-y-6 animate-fade-in">
        <PageTitle
          title="Export Payments"
          icon={BadgeIndianRupee}
          description="Check each UPI transaction ID in your bank or UPI app, then approve or reject it. Each approval gives that user 3 PDF exports."
        />

        <PaymentSettingsCard />

        <div className="grid gap-4 sm:grid-cols-3">
          {isLoading || !stats ? (
            Array.from({ length: 3 }).map((_, i) => (
              <StatCardSkeleton key={i} size="sm" />
            ))
          ) : (
            <>
              <StatCard
                size="sm"
                title="Pending"
                value={stats.pending}
                icon={Clock}
                color="amber"
                onClick={() => {
                  setStatus("pending");
                  setPage(1);
                }}
              />
              <StatCard
                size="sm"
                title="Approved"
                value={stats.approved}
                icon={Check}
                color="emerald"
                onClick={() => {
                  setStatus("approved");
                  setPage(1);
                }}
              />
              <StatCard
                size="sm"
                title="Rejected"
                value={stats.rejected}
                icon={XCircle}
                color="rose"
                onClick={() => {
                  setStatus("rejected");
                  setPage(1);
                }}
              />
            </>
          )}
        </div>

        <div>
          <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <form
              className="flex w-full gap-2 sm:max-w-sm"
              onSubmit={(event) => {
                event.preventDefault();
                setPage(1);
                setSubmittedSearch(search.trim());
              }}
            >
              <div className="relative min-w-0 flex-1">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <Input
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Search transaction ID, name, email, mobile..."
                  className="pl-9 pr-9"
                />
                {search && (
                  <button
                    type="button"
                    aria-label="Clear search"
                    className="absolute right-2 top-1/2 -translate-y-1/2 rounded-md p-1 opacity-60 hover:opacity-100 focus:outline-none focus:ring-2 focus:ring-ring"
                    onClick={() => {
                      setSearch("");
                      setSubmittedSearch("");
                      setPage(1);
                    }}
                  >
                    <X className="h-4 w-4" />
                  </button>
                )}
              </div>
              <Button type="submit" size="sm" className="h-10 shrink-0 gap-2">
                <Search className="h-4 w-4" />
                Search
              </Button>
            </form>
            <div className="flex flex-wrap items-center justify-end gap-2">
              <Select
                value={status}
                onValueChange={(value) => {
                  setStatus(value as ExportPaymentStatusFilter);
                  setPage(1);
                }}
              >
                <SelectTrigger className="h-9 w-full sm:w-44">
                  <SelectValue placeholder="Status" />
                </SelectTrigger>
                <SelectContent>
                  {STATUS_FILTERS.map((option) => (
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
              {(error as Error)?.message || "Failed to load payments."}
            </div>
          )}

          <div className="overflow-x-auto rounded-xl border border-border/60">
            <Table>
              <TableHeader>
                <TableRow className="border-b border-slate-700/80 bg-slate-800 hover:bg-slate-800">
                  <TableHead className="w-16 text-center text-slate-100">S.No</TableHead>
                  <TableHead className="text-slate-100">User</TableHead>
                  <TableHead className="text-right text-slate-100">Amount</TableHead>
                  <TableHead className="text-slate-100">UPI Transaction ID</TableHead>
                  <TableHead className="text-slate-100">Submitted</TableHead>
                  <TableHead className="text-slate-100">Status</TableHead>
                  <TableHead className="text-right text-slate-100">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading ? (
                  <TableRow>
                    <TableCell colSpan={7} className="h-28 text-center text-muted-foreground">
                      <div className="inline-flex items-center gap-2">
                        <Loader2 className="h-4 w-4 animate-spin" />
                        Loading payments...
                      </div>
                    </TableCell>
                  </TableRow>
                ) : rows.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="h-28 text-center text-muted-foreground">
                      No payments found.
                    </TableCell>
                  </TableRow>
                ) : (
                  rows.map((row, index) => (
                    <TableRow key={row.id} className={cn(index % 2 === 1 && "bg-muted/20")}>
                      <TableCell className="text-center font-medium tabular-nums">
                        {(page - 1) * limit + index + 1}
                      </TableCell>
                      <TableCell>
                        <Link
                          to={`/users/${row.userId}`}
                          className="font-medium text-primary hover:underline"
                        >
                          {displayValue(row.userName)}
                        </Link>
                        <p className="text-xs text-muted-foreground">
                          {displayValue(row.userEmail || row.userMobile)}
                        </p>
                      </TableCell>
                      <TableCell className="text-right font-medium tabular-nums">
                        {formatAmount(row.amount)}
                      </TableCell>
                      <TableCell className="font-mono text-sm tracking-wide">
                        {row.upiTxnId}
                      </TableCell>
                      <TableCell className="whitespace-nowrap text-muted-foreground">
                        {formatDateTime(row.createdAt)}
                      </TableCell>
                      <TableCell className="max-w-[240px]">
                        <Badge className={cn("capitalize", STATUS_STYLES[row.status])}>
                          {row.status}
                        </Badge>
                        {row.status === "approved" && row.exportsAllowed != null && (
                          <p className="mt-1 text-xs font-medium tabular-nums">
                            Exports used: {row.exportsUsed ?? 0} / {row.exportsAllowed}
                          </p>
                        )}
                        {row.status !== "pending" && (
                          <p className="mt-1 text-xs text-muted-foreground">
                            {row.reviewedByName ? `by ${row.reviewedByName}` : ""}
                            {row.reviewedAt ? ` · ${formatDateTime(row.reviewedAt)}` : ""}
                          </p>
                        )}
                        {row.adminRemarks && (
                          <p className="mt-1 truncate text-xs text-muted-foreground" title={row.adminRemarks}>
                            {row.adminRemarks}
                          </p>
                        )}
                      </TableCell>
                      <TableCell className="text-right">
                        {row.status === "pending" ? (
                          <div className="flex justify-end gap-2">
                            <Button
                              size="sm"
                              className="gap-1"
                              onClick={() => openReview(row, "approve")}
                            >
                              <Check className="h-4 w-4" />
                              Approve
                            </Button>
                            <Button
                              size="sm"
                              variant="outline"
                              className="gap-1 border-destructive/40 text-destructive hover:bg-destructive/10 hover:text-destructive"
                              onClick={() => openReview(row, "reject")}
                            >
                              <X className="h-4 w-4" />
                              Reject
                            </Button>
                          </div>
                        ) : (
                          <span className="text-sm text-muted-foreground">—</span>
                        )}
                      </TableCell>
                    </TableRow>
                  ))
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
                  disabled={page <= 1}
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                >
                  <ChevronLeft className="h-4 w-4" />
                  Prev
                </Button>
                <span className="text-sm tabular-nums text-muted-foreground">
                  {page} / {totalPages}
                </span>
                <Button
                  variant="outline"
                  size="sm"
                  className="h-8 gap-1"
                  disabled={page >= totalPages}
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

      <Dialog open={reviewTarget !== null} onOpenChange={(open) => !open && closeReview()}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {reviewTarget?.action === "approve" ? "Approve payment" : "Reject payment"}
            </DialogTitle>
            <DialogDescription>
              {reviewTarget?.action === "approve"
                ? "Approve only after you find this transaction in your bank or UPI app for the right amount."
                : "The user will see this reason in the app and can submit a new transaction ID."}
            </DialogDescription>
          </DialogHeader>
          {reviewTarget && (
            <div className="space-y-4">
              <dl className="grid grid-cols-[auto,1fr] gap-x-4 gap-y-1 rounded-lg bg-muted/40 p-3 text-sm">
                <dt className="text-muted-foreground">User</dt>
                <dd className="font-medium">{displayValue(reviewTarget.payment.userName)}</dd>
                <dt className="text-muted-foreground">Amount</dt>
                <dd className="font-medium">{formatAmount(reviewTarget.payment.amount)}</dd>
                <dt className="text-muted-foreground">Transaction ID</dt>
                <dd className="font-mono">{reviewTarget.payment.upiTxnId}</dd>
              </dl>
              <div className="space-y-2">
                <Label htmlFor="export-payment-remarks">
                  {reviewTarget.action === "reject" ? "Reason (required)" : "Remarks (optional)"}
                </Label>
                <Textarea
                  id="export-payment-remarks"
                  value={remarks}
                  maxLength={500}
                  onChange={(e) => setRemarks(e.target.value)}
                  placeholder={
                    reviewTarget.action === "reject"
                      ? "e.g. Transaction not found or amount does not match"
                      : "Internal note"
                  }
                />
              </div>
            </div>
          )}
          <DialogFooter>
            <Button variant="outline" onClick={closeReview} disabled={reviewMutation.isPending}>
              Cancel
            </Button>
            <Button
              variant={reviewTarget?.action === "reject" ? "destructive" : "default"}
              disabled={!reviewTarget || rejectNeedsReason || reviewMutation.isPending}
              onClick={() => reviewTarget && reviewMutation.mutate(reviewTarget)}
            >
              {reviewMutation.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              {reviewTarget?.action === "reject" ? "Reject" : "Approve"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
