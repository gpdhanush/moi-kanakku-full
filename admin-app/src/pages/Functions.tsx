import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  PartyPopper,
  RefreshCw,
  Loader2,
  Search,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  ChevronLeft,
  ChevronRight,
  Users,
  MapPin,
  Image as ImageIcon,
} from "lucide-react";
import { PageTitle } from "@/components/ui/page-title";
import { StatCard, StatCardSkeleton } from "@/components/ui/stat-card";
import { Button } from "@/components/ui/button";
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
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { usePageMeta } from "@/hooks/usePageMeta";
import {
  transactionFunctionsApi,
  type TransactionFunctionItem,
} from "@/features/transaction-functions/api";
import { ImageThumb } from "@/components/ui/image-thumb";
import {
  formatDateOnly,
  formatDateTime,
  displayValue,
  resolveImageUrl,
} from "@/lib/formatters";
import { cn } from "@/lib/utils";

const PAGE_LIMITS = [10, 20, 50, 100] as const;

type SortKey =
  | "userName"
  | "functionName"
  | "functionDate"
  | "location"
  | "createdAt";

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

function DetailField({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-lg border border-border/60 bg-muted/20 p-3">
      <p className="text-[11px] font-semibold uppercase tracking-wide text-muted-foreground">
        {label}
      </p>
      <p className="mt-1 break-words text-sm font-semibold">{value}</p>
    </div>
  );
}

export default function Functions() {
  const [search, setSearch] = useState("");
  const [sortKey, setSortKey] = useState<SortKey>("functionDate");
  const [sortDir, setSortDir] = useState<SortDir>("desc");
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(10);
  const [viewItem, setViewItem] = useState<TransactionFunctionItem | null>(null);

  const metaElement = usePageMeta({
    title: "Functions",
    description: "Browse function records created by users",
  });

  const { data, isLoading, isFetching, isError, error, refetch } = useQuery({
    queryKey: ["admin", "transaction-functions"],
    queryFn: () => transactionFunctionsApi.list(),
    staleTime: 60_000,
    refetchOnWindowFocus: false,
  });

  const rows = data?.data ?? [];
  const functionImageUrl = resolveImageUrl(viewItem?.imageUrl);

  const summary = useMemo(() => {
    const withImage = rows.filter((item) => Boolean(item.imageUrl)).length;
    const withLocation = rows.filter((item) => Boolean(item.location)).length;
    const uniqueUsers = new Set(rows.map((item) => String(item.userId))).size;
    return {
      total: rows.length,
      uniqueUsers,
      withLocation,
      withImage,
    };
  }, [rows]);

  const filteredSorted = useMemo(() => {
    const q = search.trim().toLowerCase();
    let list = [...rows];

    if (q) {
      list = list.filter((item) => {
        const haystack = [
          item.userName,
          item.userEmail,
          item.userMobile,
          item.functionName,
          item.location,
          item.notes,
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
        case "functionName":
          return compareValues(
            (a.functionName || "").toLowerCase(),
            (b.functionName || "").toLowerCase(),
            sortDir
          );
        case "functionDate":
          return compareValues(toSortTime(a.functionDate), toSortTime(b.functionDate), sortDir);
        case "location":
          return compareValues(
            (a.location || "").toLowerCase(),
            (b.location || "").toLowerCase(),
            sortDir
          );
        case "createdAt":
          return compareValues(toSortTime(a.createdAt), toSortTime(b.createdAt), sortDir);
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

  const SortableHead = ({
    label,
    column,
    align = "left",
    className,
  }: {
    label: string;
    column: SortKey;
    align?: "left" | "center";
    className?: string;
  }) => (
    <TableHead
      className={cn(
        "text-slate-100",
        align === "center" ? "text-center" : "text-left",
        className
      )}
    >
      <button
        type="button"
        onClick={() => handleSort(column)}
        className={cn(
          "inline-flex items-center gap-1.5 font-medium text-inherit hover:text-white",
          align === "center" && "w-full justify-center"
        )}
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
          title="Functions"
          icon={PartyPopper}
          description="Function records created by app users"
        />

        <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
          {isLoading ? (
            Array.from({ length: 4 }).map((_, i) => (
              <StatCardSkeleton key={i} size="sm" />
            ))
          ) : (
            <>
              <StatCard
                size="sm"
                title="Total"
                value={summary.total}
                icon={PartyPopper}
                color="blue"
              />
              <StatCard
                size="sm"
                title="Users"
                value={summary.uniqueUsers}
                icon={Users}
                color="emerald"
              />
              <StatCard
                size="sm"
                title="With Location"
                value={summary.withLocation}
                icon={MapPin}
                color="teal"
              />
              <StatCard
                size="sm"
                title="With Image"
                value={summary.withImage}
                icon={ImageIcon}
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
                placeholder="Search functions..."
                className="pl-9"
              />
            </div>
            <div className="flex flex-wrap items-center justify-end gap-2">
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
              {(error as Error)?.message || "Failed to load functions."}
            </div>
          )}

          <div className="overflow-hidden rounded-xl border border-border/60">
            <Table>
              <TableHeader>
                <TableRow className="border-b border-slate-700/80 bg-slate-800 hover:bg-slate-800 dark:bg-slate-900 dark:hover:bg-slate-900">
                  <TableHead className="w-16 text-center text-slate-100">S.No</TableHead>
                  <TableHead className="w-16 text-center text-slate-100">Image</TableHead>
                  <SortableHead label="Name" column="userName" />
                  <SortableHead label="Function Name" column="functionName" />
                  <SortableHead label="Date" column="functionDate" />
                  <SortableHead label="Location" column="location" />
                  <SortableHead label="Created At" column="createdAt" />
                </TableRow>
              </TableHeader>
              <TableBody className="[&_td]:py-2">
                {isLoading ? (
                  <TableRow>
                    <TableCell colSpan={7} className="h-20 text-center text-muted-foreground">
                      <div className="inline-flex items-center gap-2">
                        <Loader2 className="h-4 w-4 animate-spin" />
                        Loading functions...
                      </div>
                    </TableCell>
                  </TableRow>
                ) : pageRows.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="h-20 text-center text-muted-foreground">
                      {search.trim()
                        ? "No functions match your search."
                        : "No functions found."}
                    </TableCell>
                  </TableRow>
                ) : (
                  pageRows.map((item, index) => {
                    const serialNo = (currentPage - 1) * limit + index + 1;
                    return (
                      <TableRow
                        key={item.id}
                        className={cn(index % 2 === 1 && "bg-muted/20")}
                      >
                        <TableCell className="text-center font-medium tabular-nums">
                          {serialNo}
                        </TableCell>
                        <TableCell className="text-center">
                          <div className="flex justify-center">
                            <ImageThumb
                              src={resolveImageUrl(item.imageUrl)}
                              alt={item.functionName || "Function image"}
                            />
                          </div>
                        </TableCell>
                        <TableCell className="text-left">
                          <button
                            type="button"
                            onClick={() => setViewItem(item)}
                            className="font-medium text-primary hover:underline"
                          >
                            {displayValue(item.userName)}
                          </button>
                        </TableCell>
                        <TableCell className="max-w-[220px] text-left">
                          <p className="line-clamp-1 font-medium">
                            {displayValue(item.functionName)}
                          </p>
                        </TableCell>
                        <TableCell className="whitespace-nowrap text-left text-muted-foreground">
                          {formatDateOnly(item.functionDate)}
                        </TableCell>
                        <TableCell className="text-left">
                          {displayValue(item.location)}
                        </TableCell>
                        <TableCell className="whitespace-nowrap text-left text-muted-foreground">
                          {formatDateTime(item.createdAt)}
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
              Showing {fromItem} to {toItem} of {totalItems} functions
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

      <Dialog open={!!viewItem} onOpenChange={(open) => !open && setViewItem(null)}>
        <DialogContent className="max-h-[92vh] w-[95vw] max-w-3xl overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Function Details</DialogTitle>
            <DialogDescription>Full details for this function</DialogDescription>
          </DialogHeader>

          {viewItem && (
            <div className="space-y-5">
              {functionImageUrl ? (
                <div className="overflow-hidden rounded-xl border border-border/60 bg-muted/20">
                  <img
                    src={functionImageUrl}
                    alt={viewItem.functionName || "Function"}
                    className="mx-auto max-h-[360px] w-full object-contain"
                  />
                </div>
              ) : null}

              <div className="grid gap-3 sm:grid-cols-2">
                <DetailField label="User Name" value={displayValue(viewItem.userName)} />
                <DetailField label="User Email" value={displayValue(viewItem.userEmail)} />
                <DetailField label="User Mobile" value={displayValue(viewItem.userMobile)} />
                <DetailField
                  label="Function Name"
                  value={displayValue(viewItem.functionName)}
                />
                <DetailField
                  label="Function Date"
                  value={formatDateOnly(viewItem.functionDate)}
                />
                <DetailField label="Location" value={displayValue(viewItem.location)} />
                <DetailField
                  label="Created At"
                  value={formatDateTime(viewItem.createdAt)}
                />
                <DetailField
                  label="Updated At"
                  value={formatDateTime(viewItem.updatedAt)}
                />
              </div>

              <div className="rounded-lg border border-border/60 bg-muted/20 p-3">
                <p className="text-[11px] font-semibold uppercase tracking-wide text-muted-foreground">
                  Notes
                </p>
                <p className="mt-1 whitespace-pre-wrap break-words text-sm font-semibold">
                  {displayValue(viewItem.notes)}
                </p>
              </div>
            </div>
          )}

          <DialogFooter>
            <Button variant="outline" onClick={() => setViewItem(null)}>
              Close
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
