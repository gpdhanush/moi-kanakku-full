import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  ArrowLeftRight,
  RefreshCw,
  Loader2,
  Search,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  Eye,
  ChevronLeft,
  ChevronRight,
  TrendingUp,
  Undo2,
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
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { usePageMeta } from "@/hooks/usePageMeta";
import {
  transactionsApi,
  type TransactionItem,
} from "@/features/transactions/api";
import { cn } from "@/lib/utils";

const PAGE_LIMITS = [10, 20, 50, 100] as const;

type SortKey =
  | "type"
  | "userName"
  | "transactionFunctionName"
  | "functionDate"
  | "amount";

type SortDir = "asc" | "desc";

function formatDateTime(value?: string | null): string {
  if (!value) return "N/A";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "N/A";

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

function formatDateOnly(value?: string | null): string {
  if (!value) return "N/A";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "N/A";

  const day = String(date.getDate()).padStart(2, "0");
  const months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
  ];
  return `${day}-${months[date.getMonth()]}-${date.getFullYear()}`;
}

function formatLabel(value?: string | null): string {
  if (!value) return "N/A";
  return value
    .toLowerCase()
    .split("_")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function displayValue(value?: string | number | boolean | null): string {
  if (value === null || value === undefined || value === "") return "N/A";
  if (typeof value === "boolean") return value ? "Yes" : "No";
  return String(value);
}

function formatAmount(value?: string | number | null): string {
  if (value === null || value === undefined || value === "") return "N/A";
  const num = typeof value === "number" ? value : Number(value);
  if (Number.isNaN(num)) return String(value);
  return num.toLocaleString("en-IN", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
}

function compareValues(a: string | number, b: string | number, dir: SortDir) {
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

function DetailField({
  label,
  value,
  tone = "default",
}: {
  label: string;
  value: string;
  tone?: "default" | "return" | "invest" | "amount";
}) {
  return (
    <div
      className={cn(
        "rounded-lg border p-3",
        tone === "return" &&
          "border-amber-400/40 bg-amber-500/10 text-amber-900 dark:text-amber-100",
        tone === "invest" &&
          "border-emerald-400/40 bg-emerald-500/10 text-emerald-900 dark:text-emerald-100",
        tone === "amount" &&
          "border-green-400/40 bg-green-500/15 text-green-900 dark:text-green-100",
        tone === "default" && "border-border/60 bg-muted/20"
      )}
    >
      <p
        className={cn(
          "text-[11px] font-semibold uppercase tracking-wide",
          tone === "default" ? "text-muted-foreground" : "opacity-80"
        )}
      >
        {label}
      </p>
      <p className="mt-1 break-words text-sm font-semibold">{value}</p>
    </div>
  );
}

export default function Transactions() {
  const [search, setSearch] = useState("");
  const [sortKey, setSortKey] = useState<SortKey>("functionDate");
  const [sortDir, setSortDir] = useState<SortDir>("desc");
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(10);
  const [viewItem, setViewItem] = useState<TransactionItem | null>(null);

  const metaElement = usePageMeta({
    title: "Transactions",
    description: "View invest and return transactions",
  });

  const { data, isLoading, isFetching, isError, error, refetch } = useQuery({
    queryKey: ["admin", "transactions"],
    queryFn: () => transactionsApi.list(),
    staleTime: 60_000,
    refetchOnWindowFocus: false,
  });

  const rows = data?.data ?? [];
  const totalCount = data?.count ?? rows.length;

  const summary = useMemo(() => {
    let investCount = 0;
    let returnCount = 0;
    let investAmount = 0;
    let returnAmount = 0;

    for (const item of rows) {
      const type = (item.type || "").toUpperCase();
      const amount = Number(item.amount) || 0;
      if (type === "INVEST") {
        investCount += 1;
        investAmount += amount;
      } else if (type === "RETURN") {
        returnCount += 1;
        returnAmount += amount;
      }
    }

    return {
      total: totalCount,
      investCount,
      returnCount,
      investAmount,
      returnAmount,
    };
  }, [rows, totalCount]);

  const filteredSorted = useMemo(() => {
    const q = search.trim().toLowerCase();
    let list = [...rows];

    if (q) {
      list = list.filter((item) => {
        const haystack = [
          item.userName,
          item.userEmail,
          item.userMobile,
          item.transactionFunctionName,
          item.type,
          item.amount,
          item.itemName,
          item.notes,
          item.person?.firstName,
          item.person?.city,
          item.function?.name,
          item.function?.location,
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
        case "transactionFunctionName":
          return compareValues(
            (a.transactionFunctionName || "").toLowerCase(),
            (b.transactionFunctionName || "").toLowerCase(),
            sortDir
          );
        case "functionDate":
          return compareValues(
            new Date(a.function?.date || a.transactionDate || 0).getTime(),
            new Date(b.function?.date || b.transactionDate || 0).getTime(),
            sortDir
          );
        case "type":
          return compareValues(
            (a.type || "").toLowerCase(),
            (b.type || "").toLowerCase(),
            sortDir
          );
        case "amount":
          return compareValues(Number(a.amount) || 0, Number(b.amount) || 0, sortDir);
        default:
          return compareValues(
            new Date(a.transactionDate || 0).getTime(),
            new Date(b.transactionDate || 0).getTime(),
            sortDir
          );
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
          title="Transactions"
          icon={ArrowLeftRight}
          description="Overview of all financial activities and transaction types"
        />

        <div className="grid grid-cols-2 gap-3 lg:grid-cols-5">
          {isLoading ? (
            Array.from({ length: 5 }).map((_, i) => (
              <StatCardSkeleton key={i} size="sm" />
            ))
          ) : (
            <>
              <StatCard
                size="sm"
                title="Total Transactions"
                value={summary.total}
                icon={ArrowLeftRight}
                color="blue"
              />
              <StatCard
                size="sm"
                title="Total Investments"
                value={summary.investCount}
                icon={TrendingUp}
                color="emerald"
              />
              <StatCard
                size="sm"
                title="Total Returns"
                value={summary.returnCount}
                icon={Undo2}
                color="orange"
              />
              <StatCard
                size="sm"
                title="Total Investments Amount"
                value={formatAmount(summary.investAmount)}
                icon={TrendingUp}
                color="teal"
              />
              <StatCard
                size="sm"
                title="Total Returns Amount"
                value={formatAmount(summary.returnAmount)}
                icon={Undo2}
                color="amber"
              />
            </>
          )}
        </div>

        <div className="glass-card p-4 sm:p-6">
          <div className="mb-4 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <h2 className="text-lg font-semibold">Transaction Management</h2>
              <p className="mt-1 text-sm text-muted-foreground">
                Browse all invest and return transaction records
              </p>
            </div>

            <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
              <div className="relative w-full sm:w-72">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <Input
                  value={search}
                  onChange={(e) => {
                    setSearch(e.target.value);
                    setPage(1);
                  }}
                  placeholder="Search transactions..."
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
              {(error as Error)?.message || "Failed to load transactions."}
            </div>
          )}

          <div className="overflow-hidden rounded-xl border border-border/60">
            <Table>
              <TableHeader>
                <TableRow className="border-b border-slate-700/80 bg-slate-800 hover:bg-slate-800 dark:bg-slate-900 dark:hover:bg-slate-900">
                  <TableHead className="w-16 text-slate-100">S.No</TableHead>
                  <SortableHead label="Category" column="type" className="text-slate-100" />
                  <SortableHead label="Name" column="userName" className="text-slate-100" />
                  <SortableHead
                    label="Function Name"
                    column="transactionFunctionName"
                    className="text-slate-100"
                  />
                  <SortableHead
                    label="Date"
                    column="functionDate"
                    className="text-slate-100"
                  />
                  <SortableHead label="Amount" column="amount" className="text-slate-100" />
                  <TableHead className="w-[80px] text-center text-slate-100">Action</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading ? (
                  <TableRow>
                    <TableCell colSpan={7} className="h-28 text-center text-muted-foreground">
                      <div className="inline-flex items-center gap-2">
                        <Loader2 className="h-4 w-4 animate-spin" />
                        Loading transactions...
                      </div>
                    </TableCell>
                  </TableRow>
                ) : pageRows.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="h-28 text-center text-muted-foreground">
                      {search.trim()
                        ? "No transactions match your search."
                        : "No transactions found."}
                    </TableCell>
                  </TableRow>
                ) : (
                  pageRows.map((item, index) => {
                    const serialNo = (currentPage - 1) * limit + index + 1;
                    const isReturn = (item.type || "").toUpperCase() === "RETURN";
                    return (
                      <TableRow
                        key={item.id}
                        className={cn(index % 2 === 1 && "bg-muted/20")}
                      >
                        <TableCell className="font-medium tabular-nums">
                          {serialNo}
                        </TableCell>
                        <TableCell>
                          <Badge
                            className={cn(
                              "border-transparent",
                              isReturn
                                ? "bg-amber-500/15 text-amber-700 hover:bg-amber-500/20 dark:text-amber-300"
                                : "bg-emerald-500/15 text-emerald-700 hover:bg-emerald-500/20 dark:text-emerald-300"
                            )}
                          >
                            {formatLabel(item.type)}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <p className="font-medium">{item.userName || "N/A"}</p>
                        </TableCell>
                        <TableCell className="max-w-[240px]">
                          <p className="line-clamp-2 text-sm font-medium">
                            {item.transactionFunctionName || "N/A"}
                          </p>
                        </TableCell>
                        <TableCell className="whitespace-nowrap text-muted-foreground">
                          {formatDateOnly(item.function?.date || item.transactionDate)}
                        </TableCell>
                        <TableCell className="font-semibold tabular-nums">
                          {formatAmount(item.amount)}
                        </TableCell>
                        <TableCell>
                          <div className="flex justify-center">
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
              Showing {fromItem} to {toItem} of {totalItems} transactions
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
        <DialogContent className="max-h-[92vh] w-[95vw] max-w-5xl overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Transaction Details</DialogTitle>
            <DialogDescription>
              Full transaction, person, and function information
            </DialogDescription>
          </DialogHeader>

          {viewItem && (
            <div className="space-y-5">
              <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                <DetailField label="User Name" value={displayValue(viewItem.userName)} />
                <DetailField label="User Email" value={displayValue(viewItem.userEmail)} />
                <DetailField label="User Mobile" value={displayValue(viewItem.userMobile)} />
                <DetailField
                  label="Transaction Function Name"
                  value={displayValue(viewItem.transactionFunctionName)}
                />
                <DetailField
                  label="Transaction Date"
                  value={formatDateTime(viewItem.transactionDate)}
                />
                <DetailField
                  label="Type"
                  value={formatLabel(viewItem.type)}
                  tone={
                    (viewItem.type || "").toUpperCase() === "RETURN"
                      ? "return"
                      : "invest"
                  }
                />
                <DetailField
                  label="Amount"
                  value={formatAmount(viewItem.amount)}
                  tone="amount"
                />
                <DetailField label="Item Name" value={displayValue(viewItem.itemName)} />
                <DetailField label="Notes" value={displayValue(viewItem.notes)} />
                <DetailField label="Is Custom" value={displayValue(viewItem.isCustom)} />
                <DetailField
                  label="Custom Function"
                  value={displayValue(viewItem.customFunction)}
                />
                <DetailField
                  label="Created At"
                  value={formatDateTime(viewItem.createdAt)}
                />
                <DetailField
                  label="Updated At"
                  value={formatDateTime(viewItem.updatedAt)}
                />
              </div>

              <div className="space-y-3 border-t border-border/60 pt-4">
                <h3 className="text-sm font-semibold">Person Details</h3>
                <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                  <DetailField
                    label="First Name"
                    value={displayValue(viewItem.person?.firstName)}
                  />
                  <DetailField
                    label="Last Name"
                    value={displayValue(viewItem.person?.lastName)}
                  />
                  <DetailField
                    label="Mobile"
                    value={displayValue(viewItem.person?.mobile)}
                  />
                  <DetailField
                    label="City"
                    value={displayValue(viewItem.person?.city)}
                  />
                  <DetailField
                    label="Occupation"
                    value={displayValue(viewItem.person?.occupation)}
                  />
                </div>
              </div>

              <div className="space-y-3 border-t border-border/60 pt-4">
                <h3 className="text-sm font-semibold">Function Details</h3>
                <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                  <DetailField
                    label="Function Name"
                    value={displayValue(viewItem.function?.name)}
                  />
                  <DetailField
                    label="Function Date"
                    value={formatDateTime(viewItem.function?.date)}
                  />
                  <DetailField
                    label="Location"
                    value={displayValue(viewItem.function?.location)}
                  />
                </div>
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
