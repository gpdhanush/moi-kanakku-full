import { useEffect, useMemo, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useQueries, useQuery } from "@tanstack/react-query";
import {
  ArrowLeft,
  User,
  Phone,
  MapPin,
  ShieldCheck,
  Smartphone,
  Users,
  PartyPopper,
  ArrowLeftRight,
  Bell,
  IdCard,
  Clock3,
} from "lucide-react";
import { PageTitle } from "@/components/ui/page-title";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { DataSection } from "@/components/ui/data-section";
import { usePageMeta } from "@/hooks/usePageMeta";
import { usersApi } from "@/features/users/api";
import { personsApi, type PersonItem } from "@/features/persons/api";
import {
  transactionFunctionsApi,
  type TransactionFunctionItem,
} from "@/features/transaction-functions/api";
import { transactionsApi, type TransactionItem } from "@/features/transactions/api";
import {
  notificationsApi,
  type NotificationItem,
} from "@/features/notifications/api";
import {
  displayValue,
  formatAmount,
  formatDateOnly,
  formatDateTime,
  formatLabel,
  resolveImageUrl,
} from "@/lib/formatters";
import { cn } from "@/lib/utils";

function InfoCard({
  title,
  icon,
  accentClassName,
  children,
}: {
  title: string;
  icon: React.ReactNode;
  accentClassName: string;
  children: React.ReactNode;
}) {
  return (
    <div className="glass-card overflow-hidden">
      <div className={cn("flex items-center gap-2 px-4 py-3 text-white", accentClassName)}>
        {icon}
        <h3 className="text-sm font-semibold tracking-wide">{title}</h3>
      </div>
      <div className="grid gap-3 p-4 sm:grid-cols-2">{children}</div>
    </div>
  );
}

function InfoField({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-lg border border-border/60 bg-muted/20 p-3">
      <p className="text-[11px] font-semibold uppercase tracking-wide text-muted-foreground">
        {label}
      </p>
      <p className="mt-1 break-words text-sm font-medium">{value}</p>
    </div>
  );
}

export default function UserDetail() {
  const { userId = "" } = useParams();
  const navigate = useNavigate();
  const [notificationsPage, setNotificationsPage] = useState(1);
  const [notificationsLimit, setNotificationsLimit] = useState(10);

  const userQuery = useQuery({
    queryKey: ["admin", "users", userId],
    queryFn: () => usersApi.getById(userId),
    enabled: !!userId,
    staleTime: 60_000,
  });

  const relatedQueries = useQueries({
    queries: [
      {
        queryKey: ["admin", "persons", userId],
        queryFn: () => personsApi.listByUser(userId),
        enabled: !!userId,
        staleTime: 60_000,
      },
      {
        queryKey: ["admin", "transaction-functions", userId],
        queryFn: () => transactionFunctionsApi.list(userId),
        enabled: !!userId,
        staleTime: 60_000,
      },
      {
        queryKey: ["admin", "transactions", "user", userId],
        queryFn: () => transactionsApi.list(userId),
        enabled: !!userId,
        staleTime: 60_000,
      },
    ],
  });

  const [personsQuery, functionsQuery, transactionsQuery] = relatedQueries;

  const notificationsQuery = useQuery({
    queryKey: [
      "admin",
      "notifications",
      userId,
      notificationsPage,
      notificationsLimit,
    ],
    queryFn: () =>
      notificationsApi.listByUser(userId, {
        page: notificationsPage,
        limit: notificationsLimit,
      }),
    enabled: !!userId,
    staleTime: 60_000,
    placeholderData: (previous) => previous,
  });

  const notificationsUnread = notificationsQuery.data?.unreadCount ?? 0;
  const notificationsRows = notificationsQuery.data?.data ?? [];
  const notificationsTotal = notificationsQuery.data?.totalCount ?? 0;

  useEffect(() => {
    if (
      notificationsQuery.isSuccess &&
      notificationsPage > 1 &&
      notificationsRows.length === 0
    ) {
      setNotificationsPage((p) => Math.max(1, p - 1));
    }
  }, [
    notificationsQuery.isSuccess,
    notificationsPage,
    notificationsRows.length,
  ]);

  const user = userQuery.data;
  const metaElement = usePageMeta({
    title: user?.name ? `User: ${user.name}` : "User Details",
    description: "User profile and related records",
  });

  const initials = useMemo(
    () =>
      (user?.name || "U")
        .split(" ")
        .map((n) => n[0])
        .join("")
        .slice(0, 2)
        .toUpperCase(),
    [user?.name]
  );

  const isActive = (user?.status || "").toUpperCase() === "ACTIVE";
  const isVerified = Boolean(Number(user?.is_verified));
  const profileImage = resolveImageUrl(
    user?.profile?.profile_image_url || null
  );

  if (!userId) {
    return (
      <div className="rounded-lg border border-destructive/30 bg-destructive/5 p-4 text-sm text-destructive">
        Invalid user id.
      </div>
    );
  }

  return (
    <>
      {metaElement}
      <div className="space-y-6 animate-fade-in">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <PageTitle
            title={user?.name || "User Details"}
            icon={User}
            description="Profile, persons, functions, transactions and notifications"
          />
          <Button
            variant="outline"
            className="gap-2 self-start"
            onClick={() => navigate("/users")}
          >
            <ArrowLeft className="h-4 w-4" />
            Back to Users
          </Button>
        </div>

        {userQuery.isError && (
          <div className="rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3 text-sm text-destructive">
            {(userQuery.error as Error)?.message || "Failed to load user details."}
          </div>
        )}

        <div className="grid gap-4 xl:grid-cols-[320px_1fr] xl:items-start">
          <div className="glass-card flex h-fit flex-col p-5">
            <div className="flex flex-col items-center text-center">
              <Avatar className="h-24 w-24 ring-4 ring-primary/15">
                <AvatarImage src={profileImage} />
                <AvatarFallback className="bg-primary/10 text-2xl font-semibold text-primary">
                  {initials}
                </AvatarFallback>
              </Avatar>
              <h2 className="mt-4 text-xl font-semibold">{user?.name || "—"}</h2>
              <p className="mt-1 text-sm text-muted-foreground">
                {user?.email || "No email"}
              </p>
              <div className="mt-3 flex flex-wrap justify-center gap-2">
                <Badge
                  className={cn(
                    "border-transparent",
                    isActive
                      ? "bg-emerald-500/15 text-emerald-700"
                      : "bg-rose-500/15 text-rose-700"
                  )}
                >
                  {formatLabel(user?.status) || "Unknown"}
                </Badge>
                <Badge
                  className={cn(
                    "border-transparent",
                    isVerified
                      ? "bg-sky-500/15 text-sky-700"
                      : "bg-amber-500/15 text-amber-700"
                  )}
                >
                  {isVerified ? "Verified" : "Unverified"}
                </Badge>
              </div>
            </div>

            <div className="mt-5 space-y-3 border-t border-border/50 pt-4 text-sm">
              <div className="flex items-center gap-2 text-muted-foreground">
                <Phone className="h-4 w-4 shrink-0 text-primary" />
                <span className="break-all">{displayValue(user?.mobile)}</span>
              </div>
              <div className="flex items-center gap-2 text-muted-foreground">
                <IdCard className="h-4 w-4 shrink-0 text-primary" />
                <span>Referral: {displayValue(user?.referral_code)}</span>
              </div>
              <div className="flex items-center gap-2 text-muted-foreground">
                <Users className="h-4 w-4 shrink-0 text-primary" />
                <span>Referred: {displayValue(user?.referred_count ?? 0)}</span>
              </div>
              <div className="flex items-center gap-2 text-muted-foreground">
                <MapPin className="h-4 w-4 shrink-0 text-primary" />
                <span>
                  {[user?.profile?.city, user?.profile?.state]
                    .filter(Boolean)
                    .join(", ") || "N/A"}
                </span>
              </div>
              <div className="flex items-center gap-2 text-muted-foreground">
                <Smartphone className="h-4 w-4 shrink-0 text-primary" />
                <span className="break-all">
                  {displayValue(user?.device?.device_name)}
                </span>
              </div>
              <div className="flex items-center gap-2 text-muted-foreground">
                <Clock3 className="h-4 w-4 shrink-0 text-primary" />
                <span>Last login: {formatDateTime(user?.last_login)}</span>
              </div>
            </div>

            <div className="mt-5 border-t border-border/50 pt-4">
              <p className="mb-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                Quick Overview
              </p>
              <div className="grid grid-cols-2 gap-2">
                <div className="rounded-xl border border-orange-400/30 bg-orange-500/10 p-3">
                  <div className="flex items-center gap-1.5 text-orange-700 dark:text-orange-300">
                    <Users className="h-3.5 w-3.5" />
                    <span className="text-[11px] font-medium">Persons</span>
                  </div>
                  <p className="mt-1 text-xl font-bold tabular-nums text-orange-900 dark:text-orange-50">
                    {personsQuery.data?.count ?? personsQuery.data?.data.length ?? 0}
                  </p>
                </div>
                <div className="rounded-xl border border-emerald-400/30 bg-emerald-500/10 p-3">
                  <div className="flex items-center gap-1.5 text-emerald-700 dark:text-emerald-300">
                    <PartyPopper className="h-3.5 w-3.5" />
                    <span className="text-[11px] font-medium">Functions</span>
                  </div>
                  <p className="mt-1 text-xl font-bold tabular-nums text-emerald-900 dark:text-emerald-50">
                    {functionsQuery.data?.count ??
                      functionsQuery.data?.data.length ??
                      0}
                  </p>
                </div>
                <div className="rounded-xl border border-rose-400/30 bg-rose-500/10 p-3">
                  <div className="flex items-center gap-1.5 text-rose-700 dark:text-rose-300">
                    <ArrowLeftRight className="h-3.5 w-3.5" />
                    <span className="text-[11px] font-medium">Txns</span>
                  </div>
                  <p className="mt-1 text-xl font-bold tabular-nums text-rose-900 dark:text-rose-50">
                    {transactionsQuery.data?.count ??
                      transactionsQuery.data?.data.length ??
                      0}
                  </p>
                </div>
                <div className="rounded-xl border border-violet-400/30 bg-violet-500/10 p-3">
                  <div className="flex items-center gap-1.5 text-violet-700 dark:text-violet-300">
                    <Bell className="h-3.5 w-3.5" />
                    <span className="text-[11px] font-medium">Unread</span>
                  </div>
                  <p className="mt-1 text-xl font-bold tabular-nums text-violet-900 dark:text-violet-50">
                    {notificationsUnread}
                  </p>
                </div>
              </div>
            </div>

            <div className="mt-4 rounded-xl border border-border/60 bg-muted/30 p-3 text-xs text-muted-foreground">
              <p className="font-semibold text-foreground">Member since</p>
              <p className="mt-1">{formatDateTime(user?.create_date)}</p>
              <p className="mt-3 font-semibold text-foreground">Device last used</p>
              <p className="mt-1">{formatDateTime(user?.device?.last_used_at)}</p>
            </div>
          </div>

          <div className="space-y-4">
            <InfoCard
              title="Personal Information"
              icon={<User className="h-4 w-4" />}
              accentClassName="bg-sky-600"
            >
              <InfoField label="Full Name" value={displayValue(user?.name)} />
              <InfoField label="Email" value={displayValue(user?.email)} />
              <InfoField label="Mobile" value={displayValue(user?.mobile)} />
              <InfoField
                label="Gender"
                value={displayValue(user?.profile?.gender)}
              />
              <InfoField
                label="Date of Birth"
                value={formatDateOnly(user?.profile?.date_of_birth)}
              />
              <InfoField label="User ID" value={displayValue(user?.id)} />
            </InfoCard>

            <div className="grid gap-4 lg:grid-cols-2">
              <InfoCard
                title="Account Summary"
                icon={<ShieldCheck className="h-4 w-4" />}
                accentClassName="bg-rose-600"
              >
                <InfoField
                  label="Created At"
                  value={formatDateTime(user?.create_date)}
                />
                <InfoField
                  label="Updated At"
                  value={formatDateTime(user?.update_date)}
                />
                <InfoField
                  label="Email Verified At"
                  value={formatDateTime(user?.email_verified_at)}
                />
                <InfoField
                  label="Referrer ID"
                  value={displayValue(user?.referrer_id)}
                />
              </InfoCard>

              <InfoCard
                title="Address"
                icon={<MapPin className="h-4 w-4" />}
                accentClassName="bg-cyan-600"
              >
                <InfoField
                  label="Address Line 1"
                  value={displayValue(user?.profile?.address_line1)}
                />
                <InfoField
                  label="Address Line 2"
                  value={displayValue(user?.profile?.address_line2)}
                />
                <InfoField label="City" value={displayValue(user?.profile?.city)} />
                <InfoField label="State" value={displayValue(user?.profile?.state)} />
                <InfoField
                  label="Country"
                  value={displayValue(user?.profile?.country)}
                />
                <InfoField
                  label="Postal Code"
                  value={displayValue(user?.profile?.postal_code)}
                />
              </InfoCard>
            </div>

            <InfoCard
              title="Device Information"
              icon={<Smartphone className="h-4 w-4" />}
              accentClassName="bg-emerald-600"
            >
              <InfoField
                label="Device Name"
                value={displayValue(user?.device?.device_name)}
              />
              <InfoField
                label="Device ID"
                value={displayValue(user?.device?.device_id)}
              />
              <InfoField
                label="Manufacturer"
                value={displayValue(user?.device?.manufacturer)}
              />
              <InfoField
                label="Brand | Model"
                value={`${displayValue(user?.device?.brand)} | ${displayValue(user?.device?.model)}`}
              />
              <InfoField
                label="Android Version"
                value={displayValue(user?.device?.androidVersion)}
              />
              <InfoField
                label="RAM Size"
                value={displayValue(user?.device?.ram_size)}
              />
              <InfoField
                label="Last Used"
                value={formatDateTime(user?.device?.last_used_at)}
              />
              <InfoField
                label="Active"
                value={
                  Number(user?.device?.is_active) === 1 || user?.device?.is_active === true
                    ? "Yes"
                    : "No"
                }
              />
            </InfoCard>
          </div>
        </div>

        <DataSection<PersonItem>
          title="Person Details"
          totalLabel={String(personsQuery.data?.count ?? personsQuery.data?.data.length ?? 0)}
          icon={<Users className="h-4 w-4" />}
          accentClassName="bg-orange-500"
          rows={personsQuery.data?.data ?? []}
          isLoading={personsQuery.isLoading}
          getRowKey={(row) => row.id}
          columns={[
            {
              key: "sno",
              header: "S.No",
              className: "w-16",
              render: (_row, index) => index + 1,
              searchValue: () => "",
            },
            {
              key: "firstName",
              header: "First Name",
              render: (row) => displayValue(row.firstName),
              searchValue: (row) => row.firstName || "",
            },
            {
              key: "secondName",
              header: "Second Name",
              render: (row) => displayValue(row.secondName),
              searchValue: (row) => row.secondName || "",
            },
            {
              key: "business",
              header: "Business",
              render: (row) => displayValue(row.business),
              searchValue: (row) => row.business || "",
            },
            {
              key: "city",
              header: "City",
              render: (row) => displayValue(row.city),
              searchValue: (row) => row.city || "",
            },
            {
              key: "mobile",
              header: "Mobile",
              render: (row) => displayValue(row.mobile),
              searchValue: (row) => row.mobile || "",
            },
          ]}
        />

        <DataSection<TransactionFunctionItem>
          title="Functions Details"
          totalLabel={String(
            functionsQuery.data?.count ?? functionsQuery.data?.data.length ?? 0
          )}
          icon={<PartyPopper className="h-4 w-4" />}
          accentClassName="bg-emerald-600"
          rows={functionsQuery.data?.data ?? []}
          isLoading={functionsQuery.isLoading}
          getRowKey={(row) => row.id}
          columns={[
            {
              key: "sno",
              header: "S.No",
              className: "w-16",
              render: (_row, index) => index + 1,
              searchValue: () => "",
            },
            {
              key: "functionName",
              header: "Function Name",
              render: (row) => displayValue(row.functionName),
              searchValue: (row) => row.functionName || "",
            },
            {
              key: "functionDate",
              header: "Function Date",
              render: (row) => formatDateOnly(row.functionDate),
              searchValue: (row) => row.functionDate || "",
            },
            {
              key: "location",
              header: "Location",
              render: (row) => displayValue(row.location),
              searchValue: (row) => row.location || "",
            },
            {
              key: "notes",
              header: "Notes",
              render: (row) => displayValue(row.notes),
              searchValue: (row) => row.notes || "",
            },
          ]}
        />

        <DataSection<TransactionItem>
          title="Transactions Details"
          totalLabel={String(
            transactionsQuery.data?.count ??
              transactionsQuery.data?.data.length ??
              0
          )}
          icon={<ArrowLeftRight className="h-4 w-4" />}
          accentClassName="bg-rose-600"
          rows={transactionsQuery.data?.data ?? []}
          isLoading={transactionsQuery.isLoading}
          getRowKey={(row) => row.id}
          columns={[
            {
              key: "sno",
              header: "S.No",
              className: "w-16",
              render: (_row, index) => index + 1,
              searchValue: () => "",
            },
            {
              key: "transactionFunction",
              header: "Transaction Function",
              render: (row) => displayValue(row.transactionFunctionName),
              searchValue: (row) => row.transactionFunctionName || "",
            },
            {
              key: "transactionDate",
              header: "Transaction Date",
              render: (row) => formatDateOnly(row.transactionDate),
              searchValue: (row) => row.transactionDate || "",
            },
            {
              key: "type",
              header: "Type",
              render: (row) => (
                <Badge
                  className={cn(
                    "border-transparent",
                    (row.type || "").toUpperCase() === "RETURN"
                      ? "bg-amber-500/15 text-amber-700"
                      : "bg-emerald-500/15 text-emerald-700"
                  )}
                >
                  {formatLabel(row.type)}
                </Badge>
              ),
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
              key: "functionName",
              header: "Function Name",
              render: (row) => displayValue(row.function?.name),
              searchValue: (row) => row.function?.name || "",
            },
          ]}
        />

        <DataSection<NotificationItem>
          title="Notifications"
          totalLabel={`${notificationsTotal} · Unread ${notificationsUnread}`}
          icon={<Bell className="h-4 w-4" />}
          accentClassName="bg-violet-600"
          rows={notificationsRows}
          isLoading={notificationsQuery.isLoading || notificationsQuery.isFetching}
          getRowKey={(row) => row.id}
          serverPagination
          page={notificationsPage}
          limit={notificationsLimit}
          totalCount={notificationsTotal}
          onPageChange={setNotificationsPage}
          onLimitChange={(nextLimit) => {
            setNotificationsLimit(nextLimit);
            setNotificationsPage(1);
          }}
          columns={[
            {
              key: "sno",
              header: "S.No",
              className: "w-16",
              render: (_row, index) => index + 1,
              searchValue: () => "",
            },
            {
              key: "title",
              header: "Title",
              render: (row) => (
                <div>
                  <p className="font-medium">{row.title}</p>
                  <p className="text-xs text-muted-foreground line-clamp-2">
                    {row.body}
                  </p>
                </div>
              ),
              searchValue: (row) => `${row.title} ${row.body}`,
            },
            {
              key: "type",
              header: "Type",
              render: (row) => formatLabel(row.type),
              searchValue: (row) => row.type || "",
            },
            {
              key: "status",
              header: "Status",
              render: (row) => (
                <Badge
                  className={cn(
                    "border-transparent",
                    row.isRead
                      ? "bg-emerald-500/15 text-emerald-700"
                      : "bg-amber-500/15 text-amber-700"
                  )}
                >
                  {row.isRead ? "Read" : "Unread"}
                </Badge>
              ),
              searchValue: (row) => (row.isRead ? "read" : "unread"),
            },
            {
              key: "createdAt",
              header: "Created At",
              render: (row) => formatDateTime(row.createdAt),
              searchValue: (row) => row.createdAt || "",
            },
          ]}
        />
      </div>
    </>
  );
}
