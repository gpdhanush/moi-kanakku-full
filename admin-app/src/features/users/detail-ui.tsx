import { Fragment, useMemo, type ReactNode } from "react";
import { Link, useNavigate } from "react-router-dom";
import { ArrowLeft, ArrowLeftRight, Eye, TrendingDown, TrendingUp } from "lucide-react";
import { StatCard, StatCardSkeleton } from "@/components/ui/stat-card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { DataSection } from "@/components/ui/data-section";
import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbPage,
  BreadcrumbSeparator,
} from "@/components/ui/breadcrumb";
import type { TransactionItem } from "@/features/transactions/api";
import {
  displayValue,
  formatAmount,
  formatDateOnly,
  formatLabel,
} from "@/lib/formatters";
import { cn } from "@/lib/utils";
import {
  isReturnType,
  personPath,
  transactionPath,
  transactionPersonName,
} from "@/features/users/detail-utils";


export function Field({ label, value }: { label: string; value: ReactNode }) {
  return (
    <div className="min-w-0 space-y-1">
      <p className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
        {label}
      </p>
      <div className="break-words text-sm font-medium text-foreground">
        {value}
      </div>
    </div>
  );
}

export function SectionCard({
  title,
  icon,
  action,
  children,
}: {
  title: string;
  icon: ReactNode;
  action?: ReactNode;
  children: ReactNode;
}) {
  return (
    <div className="min-w-0 rounded-2xl border border-border/60 bg-card p-5 shadow-sm">
      <div className="mb-4 flex items-center gap-2.5">
        <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary/10 text-primary">
          {icon}
        </div>
        <h3 className="flex-1 text-sm font-semibold tracking-tight">{title}</h3>
        {action}
      </div>
      {children}
    </div>
  );
}

export function TransactionTypeBadge({ type }: { type?: string | null }) {
  return (
    <Badge
      className={cn(
        "border-transparent",
        isReturnType(type)
          ? "bg-amber-500/15 text-amber-700"
          : "bg-emerald-500/15 text-emerald-700",
      )}
    >
      {formatLabel(type)}
    </Badge>
  );
}

export interface Crumb {
  label: string;
  href?: string;
}

/** Back button + breadcrumb trail shown at the top of user record pages. */
export function RecordPageNav({
  backHref,
  backLabel,
  crumbs,
}: {
  backHref: string;
  backLabel: string;
  crumbs: Crumb[];
}) {
  const navigate = useNavigate();
  return (
    <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      <Button
        size="sm"
        variant="outline"
        className="h-9 gap-2 self-start"
        onClick={() => navigate(backHref)}
      >
        <ArrowLeft className="h-4 w-4" />
        {backLabel}
      </Button>
      <Breadcrumb>
        <BreadcrumbList>
          {crumbs.map((crumb, index) => (
            <Fragment key={`${crumb.label}-${index}`}>
              {index > 0 && <BreadcrumbSeparator />}
              <BreadcrumbItem>
                {crumb.href ? (
                  <BreadcrumbLink asChild>
                    <Link to={crumb.href}>{crumb.label}</Link>
                  </BreadcrumbLink>
                ) : (
                  <BreadcrumbPage>{crumb.label}</BreadcrumbPage>
                )}
              </BreadcrumbItem>
            </Fragment>
          ))}
        </BreadcrumbList>
      </Breadcrumb>
    </div>
  );
}

/** Coloured top bar + icon + title block used as the hero of record pages. */
export function RecordHero({
  isLoading,
  media,
  title,
  badges,
  children,
}: {
  isLoading?: boolean;
  media: ReactNode;
  title: ReactNode;
  badges?: ReactNode;
  children?: ReactNode;
}) {
  return (
    <div className="overflow-hidden rounded-2xl border border-border/60 bg-card shadow-sm">
      <div className="h-1.5 bg-primary" />
      {isLoading ? (
        <div className="flex items-center gap-4 p-6">
          <div className="h-20 w-20 animate-pulse rounded-2xl bg-muted" />
          <div className="flex-1 space-y-3">
            <div className="h-6 w-48 animate-pulse rounded bg-muted" />
            <div className="h-4 w-72 animate-pulse rounded bg-muted" />
          </div>
        </div>
      ) : (
        <div className="flex flex-col gap-5 p-5 sm:flex-row sm:items-start sm:p-6">
          {media}
          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-2">
              <h2 className="text-xl font-semibold tracking-tight">{title}</h2>
              {badges}
            </div>
            {children && (
              <div className="mt-3 grid gap-2 text-sm text-muted-foreground sm:grid-cols-2 xl:grid-cols-3">
                {children}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

export function HeroMeta({ icon, children }: { icon: ReactNode; children: ReactNode }) {
  return (
    <div className="flex items-center gap-2 [&>svg]:h-4 [&>svg]:w-4 [&>svg]:shrink-0 [&>svg]:text-primary">
      {icon}
      <span className="truncate">{children}</span>
    </div>
  );
}

export function NotFoundNotice({ message }: { message: string }) {
  return (
    <div className="rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3 text-sm text-destructive">
      {message}
    </div>
  );
}

/** Invest / Return totals plus a searchable list of transactions. */
export function TransactionGroup({
  userId,
  rows,
  isLoading,
  error,
  emptyMessage,
  groupBy,
}: {
  userId: string;
  rows: TransactionItem[];
  isLoading: boolean;
  error: Error | null;
  emptyMessage: string;
  /** The column shown for the "other side" of each transaction. */
  groupBy: "person" | "function";
}) {
  const summary = useMemo(() => {
    let investAmount = 0;
    let returnAmount = 0;
    let investCount = 0;
    let returnCount = 0;
    for (const row of rows) {
      const amount = Number(row.amount) || 0;
      if (isReturnType(row.type)) {
        returnCount += 1;
        returnAmount += amount;
      } else {
        investCount += 1;
        investAmount += amount;
      }
    }
    return { investAmount, returnAmount, investCount, returnCount };
  }, [rows]);

  return (
    <>
      <div className="grid gap-4 sm:grid-cols-3">
        {isLoading ? (
          Array.from({ length: 3 }).map((_, i) => <StatCardSkeleton key={i} />)
        ) : (
          <>
            <StatCard
              title="Transactions"
              value={rows.length}
              icon={ArrowLeftRight}
              color="blue"
            />
            <StatCard
              title={`Invest (${summary.investCount})`}
              value={formatAmount(summary.investAmount)}
              icon={TrendingUp}
              color="emerald"
            />
            <StatCard
              title={`Return (${summary.returnCount})`}
              value={formatAmount(summary.returnAmount)}
              icon={TrendingDown}
              color="amber"
            />
          </>
        )}
      </div>

      {error ? (
        <NotFoundNotice
          message={error.message || "Failed to load transactions."}
        />
      ) : (
        <DataSection<TransactionItem>
          title="Transactions"
          totalLabel={String(rows.length)}
          icon={<ArrowLeftRight className="h-4 w-4" />}
          accentClassName="bg-primary"
          rows={rows}
          isLoading={isLoading}
          emptyMessage={emptyMessage}
          getRowKey={(row) => row.id}
          columns={[
            {
              key: "sno",
              header: "S.No",
              className: "w-16",
              render: (_row, index) => index + 1,
              searchValue: () => "",
            },
            groupBy === "person"
              ? {
                  key: "transactionFunction",
                  header: "Function",
                  render: (row) => displayValue(row.transactionFunctionName),
                  searchValue: (row) => row.transactionFunctionName || "",
                }
              : {
                  key: "person",
                  header: "Person",
                  render: (row) =>
                    row.personId ? (
                      <Link
                        to={personPath(userId, row.personId)}
                        className="font-medium text-primary hover:underline"
                      >
                        {transactionPersonName(row)}
                      </Link>
                    ) : (
                      transactionPersonName(row)
                    ),
                  searchValue: (row) => transactionPersonName(row),
                },
            {
              key: "transactionDate",
              header: "Date",
              className: "whitespace-nowrap",
              render: (row) => formatDateOnly(row.transactionDate),
              searchValue: (row) => row.transactionDate || "",
            },
            {
              key: "type",
              header: "Type",
              render: (row) => <TransactionTypeBadge type={row.type} />,
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
              key: "itemName",
              header: "Item",
              render: (row) => displayValue(row.itemName),
              searchValue: (row) => row.itemName || "",
            },
            {
              key: "actions",
              header: "Actions",
              className: "w-20 text-right",
              render: (row) => <ViewTransactionButton userId={userId} row={row} />,
              searchValue: () => "",
            },
          ]}
        />
      )}
    </>
  );
}

export function ViewTransactionButton({
  userId,
  row,
}: {
  userId: string;
  row: TransactionItem;
}) {
  return (
    <Button
      asChild
      size="icon"
      variant="ghost"
      className="h-8 w-8"
      title="View transaction details"
    >
      <Link
        to={transactionPath(userId, row.id)}
        aria-label="View transaction details"
      >
        <Eye className="h-4 w-4" />
      </Link>
    </Button>
  );
}
