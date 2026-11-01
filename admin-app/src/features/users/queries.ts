import { useQuery } from "@tanstack/react-query";
import { usersApi } from "@/features/users/api";
import { personsApi } from "@/features/persons/api";
import { transactionFunctionsApi } from "@/features/transaction-functions/api";
import { transactionsApi } from "@/features/transactions/api";

// Shared by the user detail page and its record pages so navigating between
// them reuses the cached lists instead of refetching.

export function useUserQuery(userId: string) {
  return useQuery({
    queryKey: ["admin", "users", userId],
    queryFn: () => usersApi.getById(userId),
    enabled: !!userId,
    staleTime: 60_000,
  });
}

export function useUserPersonsQuery(userId: string) {
  return useQuery({
    queryKey: ["admin", "persons", userId],
    queryFn: () => personsApi.listByUser(userId),
    enabled: !!userId,
    staleTime: 60_000,
  });
}

export function useUserFunctionsQuery(userId: string) {
  return useQuery({
    queryKey: ["admin", "transaction-functions", userId],
    queryFn: () => transactionFunctionsApi.list(userId),
    enabled: !!userId,
    staleTime: 60_000,
  });
}

export function useUserTransactionsQuery(userId: string) {
  return useQuery({
    queryKey: ["admin", "transactions", "user", userId],
    queryFn: () => transactionsApi.list(userId),
    enabled: !!userId,
    staleTime: 60_000,
  });
}
