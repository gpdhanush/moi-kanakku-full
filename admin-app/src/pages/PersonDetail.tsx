import { useMemo } from "react";
import { useParams } from "react-router-dom";
import { Briefcase, MapPin, Phone, User } from "lucide-react";
import { usePageMeta } from "@/hooks/usePageMeta";
import {
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
  TransactionGroup,
} from "@/features/users/detail-ui";
import {
  personFullName,
  userPath,
} from "@/features/users/detail-utils";
import { displayValue, formatDateTime } from "@/lib/formatters";

export default function PersonDetail() {
  const { userId = "", personId = "" } = useParams();

  const userQuery = useUserQuery(userId);
  const personsQuery = useUserPersonsQuery(userId);
  const transactionsQuery = useUserTransactionsQuery(userId);

  const person = personsQuery.data?.data.find(
    (row) => String(row.id) === personId,
  );
  const name = personFullName(person);

  const transactions = useMemo(
    () =>
      (transactionsQuery.data?.data ?? []).filter(
        (row) => String(row.personId) === personId,
      ),
    [transactionsQuery.data, personId],
  );

  const metaElement = usePageMeta({
    title: person ? `Person: ${name}` : "Person Details",
    description: "Person details and transactions",
  });

  const userName = userQuery.data?.name || "User";
  const initials = name === "N/A" ? "P" : name.slice(0, 2).toUpperCase();

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
            { label: "Persons" },
            { label: person ? name : "Person" },
          ]}
        />

        {personsQuery.isError ? (
          <NotFoundNotice
            message={
              (personsQuery.error as Error)?.message ||
              "Failed to load person details."
            }
          />
        ) : !personsQuery.isLoading && !person ? (
          <NotFoundNotice message="This person was not found for this user. It may have been deleted." />
        ) : (
          <>
            <RecordHero
              isLoading={personsQuery.isLoading}
              media={
                <div className="flex h-20 w-20 shrink-0 items-center justify-center rounded-full bg-primary/10 text-2xl font-semibold text-primary ring-4 ring-primary/10">
                  {initials}
                </div>
              }
              title={name}
            >
              <HeroMeta icon={<Phone />}>{displayValue(person?.mobile)}</HeroMeta>
              <HeroMeta icon={<MapPin />}>{displayValue(person?.city)}</HeroMeta>
              <HeroMeta icon={<Briefcase />}>
                {displayValue(person?.business)}
              </HeroMeta>
            </RecordHero>

            <TransactionGroup
              userId={userId}
              rows={transactions}
              isLoading={transactionsQuery.isLoading}
              error={transactionsQuery.error as Error | null}
              emptyMessage="No transactions recorded with this person."
              groupBy="person"
            />

            <SectionCard
              title="Person Information"
              icon={<User className="h-4 w-4" />}
            >
              <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                <Field label="First Name" value={displayValue(person?.firstName)} />
                <Field label="Second Name" value={displayValue(person?.secondName)} />
                <Field label="Business" value={displayValue(person?.business)} />
                <Field label="City" value={displayValue(person?.city)} />
                <Field label="Mobile" value={displayValue(person?.mobile)} />
                <Field label="Person ID" value={displayValue(person?.id)} />
                <Field label="Created At" value={formatDateTime(person?.createdAt)} />
                <Field label="Updated At" value={formatDateTime(person?.updatedAt)} />
                <Field label="Owner" value={userName} />
              </div>
            </SectionCard>
          </>
        )}
      </div>
    </>
  );
}
