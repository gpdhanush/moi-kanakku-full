import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClientProvider } from "@tanstack/react-query";
import { ThemeProvider } from "next-themes";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { HelmetProvider } from "react-helmet-async";
import { AdminLayout } from "./components/layout/AdminLayout";
import { LoadingProvider, useLoading } from "./contexts/LoadingContext";
import ErrorBoundary from "./components/ErrorBoundary";
import { logger } from "./lib/logger";
import { queryClient } from "./lib/queryClient";
import { useEffect, lazy } from "react";
import { initializeSecureStorage } from "@/lib/secureStorage";
import { registerLoadingCallback } from "@/lib/apiLoading";
import { LazyRoute } from "./components/LazyRoute";
import { ENV_CONFIG } from "./lib/config";
import { applyThemeColor, getThemeColor } from "./lib/settingsPrefs";

import { ProtectedRoute } from "./components/ProtectedRoute";

const Login = lazy(() => import("./pages/Login"));
const ResetPassword = lazy(() => import("./pages/ResetPassword"));
const Dashboard = lazy(() => import("./pages/Dashboard"));
const Franchises = lazy(() => import("./pages/Franchises"));
const FranchiseCustomers = lazy(() => import("./pages/FranchiseCustomers"));
const FranchiseStaff = lazy(() => import("./pages/FranchiseStaff"));
const FranchiseFunctions = lazy(() => import("./pages/FranchiseFunctions"));
const FranchiseReports = lazy(() => import("./pages/FranchiseReports"));
const UsersMaster = lazy(() => import("./pages/UsersMaster"));
const UserDetail = lazy(() => import("./pages/UserDetail"));
const Transactions = lazy(() => import("./pages/Transactions"));
const Feedback = lazy(() => import("./pages/Feedback"));
const Notifications = lazy(() => import("./pages/Notifications"));
const UserOtps = lazy(() => import("./pages/UserOtps"));
const Settings = lazy(() => import("./pages/Settings"));
const MFASetup = lazy(() => import("./pages/MFASetup"));
const MFAVerify = lazy(() => import("./pages/MFAVerify"));
const NotFound = lazy(() => import("./pages/NotFound"));

const AppContent = () => {
  const { setLoading } = useLoading();

  useEffect(() => {
    initializeSecureStorage().catch((error) => {
      logger.error("Failed to initialize secure storage:", error);
    });
  }, []);

  useEffect(() => {
    return registerLoadingCallback(setLoading);
  }, [setLoading]);

  return (
    <BrowserRouter
      future={{
        v7_startTransition: true,
        v7_relativeSplatPath: true,
      }}
    >
      <Routes>
        <Route path="/" element={<Navigate to="/login" replace />} />
        <Route path="/login" element={<LazyRoute><Login /></LazyRoute>} />
        <Route path="/reset-password" element={<LazyRoute><ResetPassword /></LazyRoute>} />
        <Route
          path="/admin/reset-password"
          element={<LazyRoute><ResetPassword /></LazyRoute>}
        />
        <Route path="/mfa/verify" element={<LazyRoute><MFAVerify /></LazyRoute>} />
        <Route element={<AdminLayout />}>
          <Route
            path="/dashboard"
            element={
              <ProtectedRoute allowedRoles={["SUPER_ADMIN", "FRANCHISE_ADMIN", "FRANCHISE_STAFF"]}>
                <LazyRoute><Dashboard /></LazyRoute>
              </ProtectedRoute>
            }
          />
          <Route
            path="/franchises"
            element={
              <ProtectedRoute allowedRoles={["SUPER_ADMIN", "FRANCHISE_ADMIN"]}>
                <LazyRoute><Franchises /></LazyRoute>
              </ProtectedRoute>
            }
          />
          <Route
            path="/franchise/customers"
            element={
              <ProtectedRoute allowedRoles={["FRANCHISE_ADMIN"]}>
                <LazyRoute><FranchiseCustomers /></LazyRoute>
              </ProtectedRoute>
            }
          />
          <Route
            path="/franchise/staff"
            element={
              <ProtectedRoute allowedRoles={["FRANCHISE_ADMIN"]}>
                <LazyRoute><FranchiseStaff /></LazyRoute>
              </ProtectedRoute>
            }
          />
          <Route
            path="/franchise/functions"
            element={
              <ProtectedRoute allowedRoles={["FRANCHISE_ADMIN", "FRANCHISE_STAFF"]}>
                <LazyRoute><FranchiseFunctions /></LazyRoute>
              </ProtectedRoute>
            }
          />
          <Route
            path="/franchise/reports"
            element={
              <ProtectedRoute allowedRoles={["FRANCHISE_ADMIN"]}>
                <LazyRoute><FranchiseReports /></LazyRoute>
              </ProtectedRoute>
            }
          />
          <Route
            path="/users"
            element={
              <ProtectedRoute allowedRoles={["SUPER_ADMIN"]}>
                <LazyRoute><UsersMaster /></LazyRoute>
              </ProtectedRoute>
            }
          />
          <Route
            path="/users/:userId"
            element={
              <ProtectedRoute allowedRoles={["SUPER_ADMIN"]}>
                <LazyRoute><UserDetail /></LazyRoute>
              </ProtectedRoute>
            }
          />
          <Route
            path="/transactions"
            element={
              <ProtectedRoute allowedRoles={["SUPER_ADMIN"]}>
                <LazyRoute><Transactions /></LazyRoute>
              </ProtectedRoute>
            }
          />
          <Route
            path="/feedback"
            element={
              <ProtectedRoute allowedRoles={["SUPER_ADMIN"]}>
                <LazyRoute><Feedback /></LazyRoute>
              </ProtectedRoute>
            }
          />
          <Route
            path="/notifications"
            element={
              <ProtectedRoute allowedRoles={["SUPER_ADMIN"]}>
                <LazyRoute><Notifications /></LazyRoute>
              </ProtectedRoute>
            }
          />
          <Route
            path="/user-otps"
            element={
              <ProtectedRoute allowedRoles={["SUPER_ADMIN"]}>
                <LazyRoute><UserOtps /></LazyRoute>
              </ProtectedRoute>
            }
          />
          <Route
            path="/settings"
            element={
              <ProtectedRoute allowedRoles={["SUPER_ADMIN", "FRANCHISE_ADMIN", "FRANCHISE_STAFF"]}>
                <LazyRoute><Settings /></LazyRoute>
              </ProtectedRoute>
            }
          />
          <Route
            path="/mfa/setup"
            element={
              <ProtectedRoute allowedRoles={["SUPER_ADMIN", "FRANCHISE_ADMIN", "FRANCHISE_STAFF"]}>
                <LazyRoute><MFASetup /></LazyRoute>
              </ProtectedRoute>
            }
          />
        </Route>
        <Route path="*" element={<LazyRoute><NotFound /></LazyRoute>} />
      </Routes>
    </BrowserRouter>
  );
};

const App = () => {
  useEffect(() => {
    document.title = ENV_CONFIG.COMPANY_NAME;
    applyThemeColor(getThemeColor());
  }, []);

  return (
    <HelmetProvider>
      <ErrorBoundary>
        <ThemeProvider attribute="class" defaultTheme="light" enableSystem>
          <QueryClientProvider client={queryClient}>
            <LoadingProvider>
              <TooltipProvider>
                <Toaster />
                <Sonner />
                <AppContent />
              </TooltipProvider>
            </LoadingProvider>
          </QueryClientProvider>
        </ThemeProvider>
      </ErrorBoundary>
    </HelmetProvider>
  );
};

export default App;
