import { useMemo } from "react";
import { useParams } from "react-router-dom";
import { CalendarDays, MapPin, PartyPopper, StickyNote } from "lucide-react";
import { usePageMeta } from "@/hooks/usePageMeta";
import { ImageThumb } from "@/components/ui/image-thumb";
import {
  useUserFunctionsQuery,
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
  TransactionGroup,
} from "@/features/users/detail-ui";
import {
  userPath,
} from "@/features/users/detail-utils";
import {
  displayValue,
  formatDateOnly,
  formatDateTime,
  resolveImageUrl,
} from "@/lib/formatters";

export default function FunctionDetail() {
  const { userId = "", functionId = "" } = useParams();

  const userQuery = useUserQuery(userId);
  const functionsQuery = useUserFunctionsQuery(userId);
  const transactionsQuery = useUserTransactionsQuery(userId);

  const fn = functionsQuery.data?.data.find(
    (row) => String(row.id) === functionId,
  );
  const imageUrl = resolveImageUrl(fn?.imageUrl || null);

  const transactions = useMemo(
    () =>
      (transactionsQuery.data?.data ?? []).filter(
        (row) => String(row.transactionFunctionId) === functionId,
      ),
    [transactionsQuery.data, functionId],
  );

  const metaElement = usePageMeta({
    title: fn?.functionName ? `Function: ${fn.functionName}` : "Function Details",
    description: "Function details and transactions",
  });

  const userName = userQuery.data?.name || "User";

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
            { label: "Functions" },
            { label: fn?.functionName || "Function" },
          ]}
        />

        {functionsQuery.isError ? (
          <NotFoundNotice
            message={
              (functionsQuery.error as Error)?.message ||
              "Failed to load function details."
            }
          />
        ) : !functionsQuery.isLoading && !fn ? (
          <NotFoundNotice message="This function was not found for this user. It may have been deleted." />
        ) : (
          <>
            <RecordHero
              isLoading={functionsQuery.isLoading}
              media={
                imageUrl ? (
                  <ImageThumb
                    src={imageUrl}
                    alt={fn?.functionName || "Function image"}
                    className="h-20 w-20 rounded-2xl"
                  />
                ) : (
                  <div className="flex h-20 w-20 shrink-0 items-center justify-center rounded-2xl bg-primary/10 text-primary ring-4 ring-primary/10">
                    <PartyPopper className="h-8 w-8" />
                  </div>
                )
              }
              title={displayValue(fn?.functionName)}
            >
              <HeroMeta icon={<CalendarDays />}>
                {formatDateOnly(fn?.functionDate)}
              </HeroMeta>
              <HeroMeta icon={<MapPin />}>{displayValue(fn?.location)}</HeroMeta>
              <HeroMeta icon={<StickyNote />}>{displayValue(fn?.notes)}</HeroMeta>
            </RecordHero>

            <TransactionGroup
              userId={userId}
              rows={transactions}
              isLoading={transactionsQuery.isLoading}
              error={transactionsQuery.error as Error | null}
              emptyMessage="No transactions recorded in this function."
              groupBy="function"
            />

            <SectionCard
              title="Function Information"
              icon={<PartyPopper className="h-4 w-4" />}
            >
              <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                <Field label="Function Name" value={displayValue(fn?.functionName)} />
                <Field label="Function Date" value={formatDateOnly(fn?.functionDate)} />
                <Field label="Location" value={displayValue(fn?.location)} />
                <Field label="Notes" value={displayValue(fn?.notes)} />
                <Field label="Function ID" value={displayValue(fn?.id)} />
                <Field label="Owner" value={userName} />
                <Field label="Created At" value={formatDateTime(fn?.createdAt)} />
                <Field label="Updated At" value={formatDateTime(fn?.updatedAt)} />
              </div>
            </SectionCard>
          </>
        )}
      </div>
    </>
  );
}
