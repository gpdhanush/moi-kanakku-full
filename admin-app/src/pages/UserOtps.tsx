import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  KeyRound,
  CheckCircle2,
  Clock3,
  Trash2,
  RefreshCw,
  Loader2,
  Search,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  ChevronLeft,
  ChevronRight,
} from "lucide-react";
import { PageTitle } from "@/components/ui/page-title";
import { StatCard, StatCardSkeleton } from "@/components/ui/stat-card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
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
import { otpsApi, type OtpRecord } from "@/features/otps/api";
import { cn } from "@/lib/utils";

const PAGE_LIMITS = [5, 10, 20, 50] as const;

type SortKey =
  | "name"
  | "code"
  | "type"
  | "created_at"
  | "expires_at"
  | "is_used"
  | "expiry";

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

function isExpired(otp: OtpRecord, now = Date.now()): boolean {
  const expires = new Date(otp.expires_at).getTime();
  return !Number.isNaN(expires) && expires < now;
}

function formatType(type: string): string {
  if (!type) return "—";
  return type.charAt(0) + type.slice(1).toLowerCase();
}

function compareValues(a: string | number | boolean, b: string | number | boolean, dir: SortDir) {
  if (a < b) return dir === "asc" ? -1 : 1;
  if (a > b) return dir === "asc" ? 1 : -1;
  return 0;
}

function SortIcon({ active, direction }: { active: boolean; direction: SortDir }) {
  if (!active) return <ArrowUpDown className="h-3.5 w-3.5 opacity-50" />;
  return direction === "asc" ? (
    <ArrowUp className="h-3.5 w-3.5" />
  ) : (
    <ArrowDown className="h-3.5 w-3.5" />
  );
}

export default function UserOtps() {
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState<number>(10);
  const [search, setSearch] = useState("");
  const [sortKey, setSortKey] = useState<SortKey>("created_at");
  const [sortDir, setSortDir] = useState<SortDir>("desc");
  const [showCleanupDialog, setShowCleanupDialog] = useState(false);
  const queryClient = useQueryClient();
  const metaElement = usePageMeta({
    title: "User OTPs",
    description: "Monitor verification and forgot-password codes",
  });

  const {
    data,
    isLoading,
    isFetching,
    isError,
    error,
    refetch,
  } = useQuery({
    queryKey: ["admin", "otps", page, limit],
    queryFn: () => otpsApi.list({ page, limit }),
    staleTime: 30_000,
    refetchOnWindowFocus: false,
    placeholderData: (prev) => prev,
  });

  const cleanupMutation = useMutation({
    mutationFn: () => otpsApi.cleanupExpired(),
    onSuccess: (result) => {
      const deleted = result.deleted_count ?? 0;
      toast({
        title: "Cleanup complete",
        description: `${result.message || "Expired OTPs deleted successfully"} — Deleted: ${deleted}`,
      });
      queryClient.invalidateQueries({ queryKey: ["admin", "otps"] });
      setShowCleanupDialog(false);
    },
  });

  const rows = data?.data ?? [];
  const pagination = data?.pagination;
  const message = data?.message;
  const totalPages = Math.max(1, pagination?.pages ?? 1);
  const totalItems = pagination?.total ?? 0;

  const summary = useMemo(() => {
    const now = Date.now();
    const used = rows.filter((otp) => otp.is_used).length;
    const unused = rows.filter((otp) => !otp.is_used).length;
    const expired = rows.filter((otp) => isExpired(otp, now)).length;
    return {
      total: totalItems || rows.length,
      used,
      unused,
      expired,
    };
  }, [rows, totalItems]);

  const displayRows = useMemo(() => {
    const now = Date.now();
    const q = search.trim().toLowerCase();

    let list = [...rows];

    if (q) {
      list = list.filter((otp) => {
        const haystack = [
          otp.name,
          otp.email,
          otp.mobile,
          otp.code,
          otp.type,
          otp.is_used ? "used" : "unused",
          isExpired(otp, now) ? "expired" : "active",
        ]
          .join(" ")
          .toLowerCase();
        return haystack.includes(q);
      });
    }

    list.sort((a, b) => {
      switch (sortKey) {
        case "name":
          return compareValues(
            (a.name || "").toLowerCase(),
            (b.name || "").toLowerCase(),
            sortDir
          );
        case "code":
          return compareValues(a.code || "", b.code || "", sortDir);
        case "type":
          return compareValues(
            (a.type || "").toLowerCase(),
            (b.type || "").toLowerCase(),
            sortDir
          );
        case "created_at":
          return compareValues(
            new Date(a.created_at).getTime() || 0,
            new Date(b.created_at).getTime() || 0,
            sortDir
          );
        case "expires_at":
          return compareValues(
            new Date(a.expires_at).getTime() || 0,
            new Date(b.expires_at).getTime() || 0,
            sortDir
          );
        case "is_used":
          return compareValues(Number(a.is_used), Number(b.is_used), sortDir);
        case "expiry":
          return compareValues(
            Number(isExpired(a, now)),
            Number(isExpired(b, now)),
            sortDir
          );
        default:
          return 0;
      }
    });

    return list;
  }, [rows, search, sortKey, sortDir]);

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
  };

  const handlePageChange = (nextPage: number) => {
    if (nextPage < 1 || nextPage > totalPages) return;
    setPage(nextPage);
  };

  const fromItem = totalItems === 0 ? 0 : (page - 1) * limit + 1;
  const toItem = Math.min(page * limit, totalItems);

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
          title="User OTPs"
          icon={KeyRound}
          description="Monitor verification and forgot-password codes"
        />

        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {isLoading ? (
            Array.from({ length: 4 }).map((_, i) => <StatCardSkeleton key={i} />)
          ) : (
            <>
              <StatCard title="Total OTPs" value={summary.total} icon={KeyRound} color="blue" />
              <StatCard title="Used OTPs" value={summary.used} icon={CheckCircle2} color="emerald" />
              <StatCard title="Unused OTPs" value={summary.unused} icon={Clock3} color="amber" />
              <StatCard title="Expired OTPs" value={summary.expired} icon={Trash2} color="rose" />
            </>
          )}
        </div>

        <div className="glass-card p-4 sm:p-6">
          <div className="mb-4 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <h2 className="text-lg font-semibold">OTP List</h2>
              <p className="mt-1 text-sm text-muted-foreground">
                {message || "OTP list"}
              </p>
            </div>

            <div className="flex flex-col gap-2 sm:flex-row sm:flex-wrap sm:items-center">
              <div className="relative w-full sm:w-64">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <Input
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Search name, email, code..."
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
              <Button
                variant="destructive"
                size="sm"
                className="gap-2"
                onClick={() => setShowCleanupDialog(true)}
                disabled={cleanupMutation.isPending}
              >
                <Trash2 className="h-4 w-4" />
                Cleanup Expired
              </Button>
            </div>
          </div>

          {isError && (
            <div className="mb-4 rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3 text-sm text-destructive">
              {(error as Error)?.message || "Failed to load OTP list."}
            </div>
          )}

          <div className="rounded-xl border border-border/60 overflow-hidden">
            <Table>
              <TableHeader>
                <TableRow className="border-b border-slate-700/80 bg-slate-800 hover:bg-slate-800 dark:bg-slate-900 dark:hover:bg-slate-900">
                  <TableHead className="w-16 text-slate-100">S.No</TableHead>
                  <SortableHead label="Name" column="name" className="text-slate-100" />
                  <SortableHead label="Code" column="code" className="text-slate-100" />
                  <SortableHead label="Type" column="type" className="text-slate-100" />
                  <SortableHead label="Created At" column="created_at" className="text-slate-100" />
                  <SortableHead label="Expires At" column="expires_at" className="text-slate-100" />
                  <SortableHead label="Usage" column="is_used" className="text-slate-100" />
                  <SortableHead label="Expiry" column="expiry" className="text-slate-100" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading ? (
                  <TableRow>
                    <TableCell colSpan={8} className="h-28 text-center text-muted-foreground">
                      <div className="inline-flex items-center gap-2">
                        <Loader2 className="h-4 w-4 animate-spin" />
                        Loading OTPs...
                      </div>
                    </TableCell>
                  </TableRow>
                ) : displayRows.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={8} className="h-28 text-center text-muted-foreground">
                      {search.trim()
                        ? "No OTP records match your search on this page."
                        : "No OTP records found."}
                    </TableCell>
                  </TableRow>
                ) : (
                  displayRows.map((otp, index) => {
                    const expired = isExpired(otp);
                    const serialNo = (page - 1) * limit + index + 1;
                    return (
                      <TableRow
                        key={otp.id}
                        className={cn(index % 2 === 1 && "bg-muted/20")}
                      >
                        <TableCell className="font-medium tabular-nums">
                          {serialNo}
                        </TableCell>
                        <TableCell>
                          <div className="min-w-[140px]">
                            <p className="font-medium">{otp.name || "—"}</p>
                            <p className="text-xs text-muted-foreground">
                              {otp.email || otp.mobile || "—"}
                            </p>
                          </div>
                        </TableCell>
                        <TableCell>
                          <code className="rounded bg-muted px-2 py-1 text-sm font-semibold tracking-wider">
                            {otp.code}
                          </code>
                        </TableCell>
                        <TableCell>
                          <Badge className="border-transparent bg-amber-500/15 text-amber-700 hover:bg-amber-500/20 dark:text-amber-300">
                            {formatType(otp.type)}
                          </Badge>
                        </TableCell>
                        <TableCell className="whitespace-nowrap text-muted-foreground">
                          {formatDateTime(otp.created_at)}
                        </TableCell>
                        <TableCell className="whitespace-nowrap text-muted-foreground">
                          {formatDateTime(otp.expires_at)}
                        </TableCell>
                        <TableCell>
                          <Badge
                            className={cn(
                              "border-transparent",
                              otp.is_used
                                ? "bg-emerald-500/15 text-emerald-700 hover:bg-emerald-500/20 dark:text-emerald-300"
                                : "bg-sky-500/15 text-sky-700 hover:bg-sky-500/20 dark:text-sky-300"
                            )}
                          >
                            {otp.is_used ? "Used" : "Unused"}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <Badge
                            className={cn(
                              "border-transparent",
                              expired
                                ? "bg-rose-500/15 text-rose-700 hover:bg-rose-500/20 dark:text-rose-300"
                                : "bg-emerald-500/15 text-emerald-700 hover:bg-emerald-500/20 dark:text-emerald-300"
                            )}
                          >
                            {expired ? "Expired" : "Active"}
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
              {search.trim() ? ` · ${displayRows.length} match on this page` : ""}
            </p>

            <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
              <div className="flex items-center gap-2">
                <span className="text-sm text-muted-foreground whitespace-nowrap">
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

      <AlertDialog open={showCleanupDialog} onOpenChange={setShowCleanupDialog}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Cleanup expired OTPs?</AlertDialogTitle>
            <AlertDialogDescription>
              This will permanently delete all expired OTP records. This action
              cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={cleanupMutation.isPending}>
              Cancel
            </AlertDialogCancel>
            <AlertDialogAction
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              disabled={cleanupMutation.isPending}
              onClick={(e) => {
                e.preventDefault();
                cleanupMutation.mutate();
              }}
            >
              {cleanupMutation.isPending ? (
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
    </>
  );
}
