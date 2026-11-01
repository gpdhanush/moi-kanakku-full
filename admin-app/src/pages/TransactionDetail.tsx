import { Link, useParams } from "react-router-dom";
import {
  ArrowLeftRight,
  CalendarDays,
  ChevronRight,
  Package,
  PartyPopper,
  StickyNote,
  User,
} from "lucide-react";
import { usePageMeta } from "@/hooks/usePageMeta";
import { Button } from "@/components/ui/button";
import {
  useUserFunctionsQuery,
  useUserPersonsQuery,
  useUserQuery,
  useUserTransactionsQuery,
} from "@/features/users/queries";
import {
  Field,
  HeroMeta,
  NotFoundNotice,
  RecordHero,
  RecordPageNav,
  SectionCard,
  TransactionTypeBadge,
} from "@/features/users/detail-ui";
import {
  functionPath,
  isReturnType,
  personPath,
  transactionPersonName,
  userPath,
} from "@/features/users/detail-utils";
import {
  displayValue,
  formatAmount,
  formatDateOnly,
  formatDateTime,
  formatLabel,
} from "@/lib/formatters";
import { cn } from "@/lib/utils";

function OpenLink({ to, label }: { to: string; label: string }) {
  return (
    <Button asChild size="sm" variant="outline" className="h-8 gap-1">
      <Link to={to}>
        {label}
        <ChevronRight className="h-4 w-4" />
      </Link>
    </Button>
  );
}

export default function TransactionDetail() {
  const { userId = "", transactionId = "" } = useParams();

  const userQuery = useUserQuery(userId);
  const transactionsQuery = useUserTransactionsQuery(userId);
  const personsQuery = useUserPersonsQuery(userId);
  const functionsQuery = useUserFunctionsQuery(userId);

  const tx = transactionsQuery.data?.data.find(
    (row) => String(row.id) === transactionId,
  );

  // Only link to records that belong to this user; default functions have no page.
  const hasPersonPage =
    !!tx?.personId &&
    !!personsQuery.data?.data.some((p) => String(p.id) === String(tx.personId));
  const hasFunctionPage =
    !!tx?.transactionFunctionId &&
    !!functionsQuery.data?.data.some(
      (f) => String(f.id) === String(tx.transactionFunctionId),
    );

  const metaElement = usePageMeta({
    title: "Transaction Details",
    description: "Transaction, person, and function information",
  });

  const userName = userQuery.data?.name || "User";
  const isReturn = isReturnType(tx?.type);

  return (
    <>
      {metaElement}
      <div className="space-y-6 animate-fade-in">
        <RecordPageNav
          backHref={userPath(userId)}
          backLabel={`Back to ${userName}`}
          crumbs={[
            { label: "Users", href: "/users" },
            { label: userName, href: userPath(userId) },
            { label: "Transactions" },
            { label: tx ? formatDateOnly(tx.transactionDate) : "Transaction" },
          ]}
        />

        {transactionsQuery.isError ? (
          <NotFoundNotice
            message={
              (transactionsQuery.error as Error)?.message ||
              "Failed to load transaction details."
            }
          />
        ) : !transactionsQuery.isLoading && !tx ? (
          <NotFoundNotice message="This transaction was not found for this user. It may have been deleted." />
        ) : (
          <>
            <RecordHero
              isLoading={transactionsQuery.isLoading}
              media={
                <div
                  className={cn(
                    "flex h-20 w-20 shrink-0 items-center justify-center rounded-2xl ring-4",
                    isReturn
                      ? "bg-amber-500/15 text-amber-700 ring-amber-500/10"
                      : "bg-emerald-500/15 text-emerald-700 ring-emerald-500/10",
                  )}
                >
                  <ArrowLeftRight className="h-8 w-8" />
                </div>
              }
              title={
                <span className="tabular-nums">{formatAmount(tx?.amount)}</span>
              }
              badges={<TransactionTypeBadge type={tx?.type} />}
            >
              <HeroMeta icon={<CalendarDays />}>
                {formatDateOnly(tx?.transactionDate)}
              </HeroMeta>
              <HeroMeta icon={<User />}>
                {tx ? transactionPersonName(tx) : "N/A"}
              </HeroMeta>
              <HeroMeta icon={<PartyPopper />}>
                {displayValue(tx?.transactionFunctionName)}
              </HeroMeta>
              <HeroMeta icon={<Package />}>{displayValue(tx?.itemName)}</HeroMeta>
              <HeroMeta icon={<StickyNote />}>{displayValue(tx?.notes)}</HeroMeta>
            </RecordHero>

            <SectionCard
              title="Transaction"
              icon={<ArrowLeftRight className="h-4 w-4" />}
            >
              <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                <Field label="Transaction ID" value={displayValue(tx?.id)} />
                <Field
                  label="Transaction Function"
                  value={displayValue(tx?.transactionFunctionName)}
                />
                <Field
                  label="Transaction Date"
                  value={formatDateTime(tx?.transactionDate)}
                />
                <Field label="Type" value={formatLabel(tx?.type)} />
                <Field label="Amount" value={formatAmount(tx?.amount)} />
                <Field label="Item Name" value={displayValue(tx?.itemName)} />
                <Field label="Notes" value={displayValue(tx?.notes)} />
                <Field label="Is Custom" value={tx?.isCustom ? "Yes" : "No"} />
                <Field
                  label="Custom Function"
                  value={displayValue(tx?.customFunction)}
                />
                <Field label="Created At" value={formatDateTime(tx?.createdAt)} />
                <Field label="Updated At" value={formatDateTime(tx?.updatedAt)} />
              </div>
            </SectionCard>

            <div className="grid min-w-0 gap-4 lg:grid-cols-2">
              <SectionCard
                title="Person"
                icon={<User className="h-4 w-4" />}
                action={
                  hasPersonPage && tx ? (
                    <OpenLink to={personPath(userId, tx.personId)} label="View person" />
                  ) : null
                }
              >
                <div className="grid gap-4 sm:grid-cols-2">
                  <Field label="Name" value={tx ? transactionPersonName(tx) : "N/A"} />
                  <Field label="Mobile" value={displayValue(tx?.person?.mobile)} />
                  <Field label="City" value={displayValue(tx?.person?.city)} />
                  <Field
                    label="Occupation"
                    value={displayValue(tx?.person?.occupation)}
                  />
                </div>
              </SectionCard>

              <SectionCard
                title="Function"
                icon={<PartyPopper className="h-4 w-4" />}
                action={
                  hasFunctionPage && tx ? (
                    <OpenLink
                      to={functionPath(userId, tx.transactionFunctionId)}
                      label="View function"
                    />
                  ) : null
                }
              >
                <div className="grid gap-4 sm:grid-cols-2">
                  <Field
                    label="Function Name"
                    value={displayValue(tx?.function?.name)}
                  />
                  <Field
                    label="Function Date"
                    value={formatDateOnly(tx?.function?.date)}
                  />
                  <Field
                    label="Location"
                    value={displayValue(tx?.function?.location)}
                  />
                </div>
              </SectionCard>
            </div>
          </>
        )}
      </div>
    </>
  );
}
