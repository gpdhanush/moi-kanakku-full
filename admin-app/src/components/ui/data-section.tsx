import { useMemo, useState, type ReactNode } from "react";
import {
  Search,
  ChevronLeft,
  ChevronRight,
  Loader2,
} from "lucide-react";
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
import { cn } from "@/lib/utils";

const PAGE_LIMITS = [5, 10, 20, 50] as const;

export interface DataSectionColumn<T> {
  key: string;
  header: string;
  className?: string;
  render: (row: T, index: number) => ReactNode;
  searchValue?: (row: T) => string;
}

interface DataSectionProps<T> {
  title: string;
  icon?: ReactNode;
  accentClassName?: string;
  rows: T[];
  columns: DataSectionColumn<T>[];
  isLoading?: boolean;
  emptyMessage?: string;
  getRowKey: (row: T, index: number) => string | number;
  totalLabel?: string;
  /** When true, `rows` are treated as the current server page. */
  serverPagination?: boolean;
  page?: number;
  limit?: number;
  totalCount?: number;
  onPageChange?: (page: number) => void;
  onLimitChange?: (limit: number) => void;
}

export function DataSection<T>({
  title,
  icon,
  accentClassName = "bg-slate-800",
  rows,
  columns,
  isLoading = false,
  emptyMessage = "No records found.",
  getRowKey,
  totalLabel,
  serverPagination = false,
  page: controlledPage,
  limit: controlledLimit,
  totalCount,
  onPageChange,
  onLimitChange,
}: DataSectionProps<T>) {
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(5);

  const currentLimit = controlledLimit ?? limit;
  const currentPageState = controlledPage ?? page;

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return rows;
    return rows.filter((row) => {
      const haystack = columns
        .map((col) =>
          col.searchValue
            ? col.searchValue(row)
            : String(col.render(row, 0) ?? "")
        )
        .join(" ")
        .toLowerCase();
      return haystack.includes(q);
    });
  }, [rows, search, columns]);

  const totalItems = serverPagination
    ? (search.trim() ? filtered.length : (totalCount ?? rows.length))
    : filtered.length;
  const totalPages = Math.max(1, Math.ceil(totalItems / currentLimit));
  const currentPage = Math.min(currentPageState, totalPages);
  const pageRows = serverPagination
    ? (search.trim() ? filtered : filtered.slice(0, currentLimit))
    : filtered.slice((currentPage - 1) * currentLimit, currentPage * currentLimit);
  const fromItem =
    totalItems === 0
      ? 0
      : serverPagination && search.trim()
        ? 1
        : (currentPage - 1) * currentLimit + 1;
  const toItem = serverPagination
    ? search.trim()
      ? filtered.length
      : Math.min(currentPage * currentLimit, totalItems)
    : Math.min(currentPage * currentLimit, totalItems);

  const handlePageChange = (next: number) => {
    if (onPageChange) onPageChange(next);
    else setPage(next);
  };

  const handleLimitChange = (next: number) => {
    if (onLimitChange) onLimitChange(next);
    else {
      setLimit(next);
      setPage(1);
    }
  };

  return (
    <div className="glass-card overflow-hidden">
      <div
        className={cn(
          "flex items-center gap-2 px-4 py-3 text-white",
          accentClassName
        )}
      >
        {icon}
        <h3 className="text-sm font-semibold tracking-wide">
          {title}
          {typeof totalLabel !== "undefined" && (
            <span className="ml-1 font-normal opacity-90">({totalLabel})</span>
          )}
        </h3>
      </div>

      <div className="space-y-4 p-4">
        <div className="relative max-w-sm">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              if (!serverPagination) setPage(1);
            }}
            placeholder="Search..."
            className="pl-9"
          />
        </div>

        <div className="overflow-hidden rounded-xl border border-border/60">
          <Table>
            <TableHeader>
              <TableRow className="border-b border-slate-700/80 bg-slate-800 hover:bg-slate-800">
                {columns.map((col) => (
                  <TableHead key={col.key} className={cn("text-slate-100", col.className)}>
                    {col.header}
                  </TableHead>
                ))}
              </TableRow>
            </TableHeader>
            <TableBody>
              {isLoading ? (
                <TableRow>
                  <TableCell
                    colSpan={columns.length}
                    className="h-24 text-center text-muted-foreground"
                  >
                    <div className="inline-flex items-center gap-2">
                      <Loader2 className="h-4 w-4 animate-spin" />
                      Loading...
                    </div>
                  </TableCell>
                </TableRow>
              ) : pageRows.length === 0 ? (
                <TableRow>
                  <TableCell
                    colSpan={columns.length}
                    className="h-24 text-center text-muted-foreground"
                  >
                    {search.trim() ? "No records match your search." : emptyMessage}
                  </TableCell>
                </TableRow>
              ) : (
                pageRows.map((row, index) => (
                  <TableRow
                    key={getRowKey(row, index)}
                    className={cn(index % 2 === 1 && "bg-muted/20")}
                  >
                    {columns.map((col) => (
                      <TableCell key={col.key} className={col.className}>
                        {col.render(row, (currentPage - 1) * currentLimit + index)}
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </div>

        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-sm text-muted-foreground">
            Showing {fromItem} to {toItem} of {totalItems}
          </p>
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
            <div className="flex items-center gap-2">
              <span className="whitespace-nowrap text-sm text-muted-foreground">
                Rows per page
              </span>
              <Select
                value={String(currentLimit)}
                onValueChange={(value) => handleLimitChange(Number(value))}
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
                disabled={currentPage <= 1 || (serverPagination && !!search.trim())}
                onClick={() => handlePageChange(Math.max(1, currentPage - 1))}
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
                disabled={
                  currentPage >= totalPages ||
                  (serverPagination && !!search.trim())
                }
                onClick={() =>
                  handlePageChange(Math.min(totalPages, currentPage + 1))
                }
              >
                Next
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
