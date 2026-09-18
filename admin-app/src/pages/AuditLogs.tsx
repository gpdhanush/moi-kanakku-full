import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Link, useSearchParams } from "react-router-dom";
import {
  ScrollText,
  RefreshCw,
  Loader2,
  Search,
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
import { usePageMeta } from "@/hooks/usePageMeta";
import {
  auditLogsApi,
  AUDIT_ACTIONS,
  type AuditActionFilter,
} from "@/features/audit-logs/api";
import { formatDateTime, displayValue, formatLabel } from "@/lib/formatters";
import { cn } from "@/lib/utils";

const PAGE_LIMITS = [5, 10, 20, 50] as const;

export default function AuditLogs() {
  const [searchParams] = useSearchParams();
  const userIdFilter = searchParams.get("userId")?.trim() || undefined;
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(10);
  const [search, setSearch] = useState("");
  const [actionFilter, setActionFilter] = useState<AuditActionFilter>("ALL");
  const [submittedSearch, setSubmittedSearch] = useState("");

  const metaElement = usePageMeta({
    title: "Audit Logs",
    description: "Browse mobile user activity",
  });

  const { data, isLoading, isFetching, isError, error, refetch } = useQuery({
    queryKey: [
      "admin",
      "audit-logs",
      page,
      limit,
      actionFilter,
      submittedSearch,
      userIdFilter,
    ],
    queryFn: () =>
      auditLogsApi.list({
        page,
        limit,
        userId: userIdFilter,
        action: actionFilter,
        q: submittedSearch || undefined,
      }),
    staleTime: 30_000,
    refetchOnWindowFocus: false,
    placeholderData: (prev) => prev,
  });

  const rows = data?.data ?? [];
  const pagination = data?.pagination;
  const totalPages = Math.max(1, pagination?.pages ?? 1);
  const totalItems = pagination?.total ?? 0;
  const fromItem = totalItems === 0 ? 0 : (page - 1) * limit + 1;
  const toItem = Math.min(page * limit, totalItems);

  const summary = useMemo(() => {
    const uniqueUsers = new Set(rows.map((row) => String(row.user_id))).size;
    const authCount = rows.filter((row) =>
      ["LOGIN", "LOGOUT", "SIGNUP", "PASSWORD_UPDATE", "PASSWORD_RESET"].includes(
        String(row.action || "").toUpperCase()
      )
    ).length;
    return {
      total: totalItems,
      onPage: rows.length,
      uniqueUsers,
      authCount,
    };
  }, [rows, totalItems]);

  return (
    <>
      {metaElement}
      <div className="space-y-6 animate-fade-in">
        <PageTitle
          title="Audit Logs"
          icon={ScrollText}
          description={
            userIdFilter
              ? `Filtered to user #${userIdFilter}`
              : "Mobile user write activity across the app"
          }
        />

        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {isLoading ? (
            Array.from({ length: 3 }).map((_, i) => (
              <StatCardSkeleton key={i} size="sm" />
            ))
          ) : (
            <>
              <StatCard
                size="sm"
                title="Total Events"
                value={summary.total}
                icon={ScrollText}
                color="blue"
              />
              <StatCard
                size="sm"
                title="Users on Page"
                value={summary.uniqueUsers}
                icon={ScrollText}
                color="emerald"
              />
              <StatCard
                size="sm"
                title="Auth Events on Page"
                value={summary.authCount}
                icon={ScrollText}
                color="amber"
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
                onChange={(e) => setSearch(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") {
                    setPage(1);
                    setSubmittedSearch(search.trim());
                  }
                }}
                placeholder="Search user, action, summary..."
                className="pl-9"
              />
            </div>
            <div className="flex flex-wrap items-center justify-end gap-2">
              <Select
                value={actionFilter}
                onValueChange={(value) => {
                  setActionFilter(value as AuditActionFilter);
                  setPage(1);
                }}
              >
                <SelectTrigger className="h-9 w-full sm:w-52">
                  <SelectValue placeholder="Action" />
                </SelectTrigger>
                <SelectContent>
                  {AUDIT_ACTIONS.map((action) => (
                    <SelectItem key={action} value={action}>
                      {action === "ALL" ? "All actions" : formatLabel(action)}
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
              {(error as Error)?.message || "Failed to load audit logs."}
            </div>
          )}

          <div className="overflow-hidden rounded-xl border border-border/60">
            <Table>
              <TableHeader>
                <TableRow className="border-b border-slate-700/80 bg-slate-800 hover:bg-slate-800">
                  <TableHead className="w-16 text-center text-slate-100">
                    S.No
                  </TableHead>
                  <TableHead className="text-slate-100">Time</TableHead>
                  <TableHead className="text-slate-100">User</TableHead>
                  <TableHead className="text-slate-100">Action</TableHead>
                  <TableHead className="text-slate-100">Summary</TableHead>
                  <TableHead className="text-slate-100">Entity</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading ? (
                  <TableRow>
                    <TableCell
                      colSpan={6}
                      className="h-28 text-center text-muted-foreground"
                    >
                      <div className="inline-flex items-center gap-2">
                        <Loader2 className="h-4 w-4 animate-spin" />
                        Loading audit logs...
                      </div>
                    </TableCell>
                  </TableRow>
                ) : rows.length === 0 ? (
                  <TableRow>
                    <TableCell
                      colSpan={6}
                      className="h-28 text-center text-muted-foreground"
                    >
                      No audit logs found.
                    </TableCell>
                  </TableRow>
                ) : (
                  rows.map((row, index) => {
                    const serialNo = (page - 1) * limit + index + 1;
                    return (
                      <TableRow
                        key={String(row.id)}
                        className={cn(index % 2 === 1 && "bg-muted/20")}
                      >
                        <TableCell className="text-center font-medium tabular-nums">
                          {serialNo}
                        </TableCell>
                        <TableCell className="whitespace-nowrap text-muted-foreground">
                          {formatDateTime(row.created_at)}
                        </TableCell>
                        <TableCell>
                          <Link
                            to={`/users/${row.user_id}`}
                            className="font-medium text-primary hover:underline"
                          >
                            {displayValue(row.name)}
                          </Link>
                          <p className="text-xs text-muted-foreground">
                            {displayValue(row.email || row.mobile)}
                          </p>
                        </TableCell>
                        <TableCell>
                          <Badge className="border-transparent bg-primary/10 text-primary">
                            {formatLabel(row.action)}
                          </Badge>
                        </TableCell>
                        <TableCell className="max-w-[280px]">
                          <p className="truncate text-sm">
                            {displayValue(row.summary)}
                          </p>
                        </TableCell>
                        <TableCell className="text-sm text-muted-foreground">
                          {row.entity_type
                            ? `${formatLabel(row.entity_type)}${
                                row.entity_id ? ` #${row.entity_id}` : ""
                              }`
                            : "—"}
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
                  disabled={page <= 1}
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
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
    </>
  );
}
