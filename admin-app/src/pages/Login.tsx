import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  Eye,
  EyeOff,
  Lock,
  Mail,
  Phone,
  Shield,
  X,
  AlertTriangle,
  Headphones,
  Loader2,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { SecureInput } from "@/components/ui/secure-input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { authApi, AuthLoginError } from "@/features/auth/api";
import { toast } from "@/hooks/use-toast";
import {
  secureStorageWithCache,
  initializeSecureStorage,
} from "@/lib/secureStorage";
import {
  getAuthTokenAsync,
  getCurrentUserAsync,
  setMfaPendingLogin,
  clearMfaPendingLogin,
} from "@/lib/auth";
import { ENV_CONFIG } from "@/lib/config";
import { cn } from "@/lib/utils";

const MAX_ATTEMPTS = 3;
const BLOCK_STORAGE_KEY = "admin_login_blocked_until";
const SUPPORT_EMAIL = "support@moikanakku.com";

function looksLikeEmail(value: string): boolean {
  return value.includes("@");
}

function formatCountdown(ms: number): string {
  const totalSeconds = Math.max(0, Math.ceil(ms / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
}

function readStoredBlockUntil(): string | null {
  try {
    return sessionStorage.getItem(BLOCK_STORAGE_KEY);
  } catch {
    return null;
  }
}

function storeBlockUntil(value: string | null) {
  try {
    if (!value) sessionStorage.removeItem(BLOCK_STORAGE_KEY);
    else sessionStorage.setItem(BLOCK_STORAGE_KEY, value);
  } catch {
    // ignore storage failures
  }
}

export default function Login() {
  const navigate = useNavigate();
  const [showPassword, setShowPassword] = useState(false);
  const [identifier, setIdentifier] = useState("");
  const [password, setPassword] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [errorKind, setErrorKind] = useState<
    "auth" | "forbidden" | "locked" | null
  >(null);
  const [attemptsRemaining, setAttemptsRemaining] = useState<number | null>(
    null
  );
  const [blockedUntil, setBlockedUntil] = useState<string | null>(() =>
    readStoredBlockUntil()
  );
  const [nowMs, setNowMs] = useState(() => Date.now());
  const [forgotOpen, setForgotOpen] = useState(false);
  const [forgotIdentifier, setForgotIdentifier] = useState("");
  const [isForgotLoading, setIsForgotLoading] = useState(false);
  const [forgotError, setForgotError] = useState<string | null>(null);
  const [forgotSuccess, setForgotSuccess] = useState<string | null>(null);

  useEffect(() => {
    const redirectIfAuthed = async () => {
      await initializeSecureStorage();
      const token = await getAuthTokenAsync();
      const user = await getCurrentUserAsync();
      if (token && user) {
        navigate("/dashboard", { replace: true });
      }
    };
    redirectIfAuthed();
  }, [navigate]);

  useEffect(() => {
    if (!blockedUntil) return;
    const end = new Date(blockedUntil).getTime();
    if (Number.isNaN(end)) {
      setBlockedUntil(null);
      storeBlockUntil(null);
      return;
    }

    const tick = () => {
      const current = Date.now();
      setNowMs(current);
      if (current >= end) {
        setBlockedUntil(null);
        storeBlockUntil(null);
        setErrorMessage(null);
        setErrorKind(null);
        setAttemptsRemaining(null);
      }
    };

    tick();
    const timer = window.setInterval(tick, 250);
    return () => window.clearInterval(timer);
  }, [blockedUntil]);

  const blockRemainingMs = useMemo(() => {
    if (!blockedUntil) return 0;
    const end = new Date(blockedUntil).getTime();
    if (Number.isNaN(end)) return 0;
    return Math.max(0, end - nowMs);
  }, [blockedUntil, nowMs]);

  const isLocked = blockRemainingMs > 0;
  const attemptNumber =
    attemptsRemaining === null
      ? null
      : Math.min(MAX_ATTEMPTS, Math.max(0, MAX_ATTEMPTS - attemptsRemaining));

  const IdentifierIcon = looksLikeEmail(identifier.trim()) ? Mail : Phone;
  const ForgotIcon = looksLikeEmail(forgotIdentifier.trim()) ? Mail : Phone;

  const applyLock = (until: string | null | undefined, message?: string) => {
    if (!until) return;
    setBlockedUntil(until);
    storeBlockUntil(until);
    setAttemptsRemaining(0);
    setErrorKind("locked");
    if (message) setErrorMessage(message);
  };

  const openForgotDialog = () => {
    setForgotIdentifier(identifier.trim());
    setForgotError(null);
    setForgotSuccess(null);
    setForgotOpen(true);
  };

  const handleForgotPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    const value = forgotIdentifier.trim();
    if (!value) {
      setForgotError("Email or mobile number is required.");
      return;
    }

    setIsForgotLoading(true);
    setForgotError(null);
    setForgotSuccess(null);

    try {
      const result = await authApi.forgotPassword(value);
      setForgotSuccess(
        result.message || "Password reset details were sent to your email."
      );
      toast({
        title: "Reset email sent",
        description:
          result.message || "Check your inbox for the password reset link.",
      });
    } catch (error) {
      setForgotError(
        error instanceof Error ? error.message : "Failed to send reset email."
      );
    } finally {
      setIsForgotLoading(false);
    }
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (isLocked || isLoading) return;

    const trimmed = identifier.trim();
    if (!trimmed || !password) {
      setErrorKind("auth");
      setErrorMessage("Please enter identifier and password.");
      return;
    }

    setIsLoading(true);
    setErrorMessage(null);
    setErrorKind(null);

    try {
      const result = await authApi.login(trimmed, password);
      clearMfaPendingLogin();

      if ("token" in result) {
        await secureStorageWithCache.setItem("auth_token", result.token);
        await secureStorageWithCache.setItem(
          "user",
          JSON.stringify(result.user)
        );
        storeBlockUntil(null);
        setBlockedUntil(null);
        setAttemptsRemaining(null);

        toast({
          title: "Login successful",
          description: `Welcome back, ${result.user.name}!`,
        });

        navigate("/dashboard", { replace: true });
        return;
      }

      setMfaPendingLogin({
        userId: result.userId,
        accountType: result.accountType,
      });
      toast({
        title: "MFA required",
        description:
          result.message ||
          "Enter the code from your authenticator app to continue.",
      });
      navigate("/mfa/verify", {
        replace: true,
        state: {
          userId: result.userId,
          accountType: result.accountType,
        },
      });
    } catch (error: unknown) {
      if (error instanceof AuthLoginError) {
        if (typeof error.attemptsRemaining === "number") {
          setAttemptsRemaining(error.attemptsRemaining);
        }

        if (error.status === 429) {
          applyLock(
            error.blockedUntil ||
              new Date(Date.now() + 15 * 60 * 1000).toISOString(),
            error.message
          );
        } else if (error.status === 403) {
          setErrorKind("forbidden");
          setErrorMessage(error.message);
        } else {
          setErrorKind("auth");
          setErrorMessage(error.message);
        }
      } else {
        setErrorKind("auth");
        setErrorMessage(
          error instanceof Error
            ? error.message
            : "Invalid identifier or password"
        );
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen">
      <div className="relative hidden overflow-hidden bg-gradient-to-br from-primary/20 via-background to-background p-12 lg:flex lg:w-1/2 lg:flex-col lg:justify-between">
        <div className="relative z-10">
          <div className="flex flex-col items-center gap-4">
            <img
              src="/logo-new.png"
              alt="Moi Kanakku"
              className="h-36 w-auto max-w-[280px] object-contain"
            />
            <p className="text-lg text-muted-foreground">Admin control panel</p>
          </div>
        </div>

        <div className="relative z-10 space-y-6">
          <h2 className="text-4xl font-bold leading-tight">
            Manage users, transactions
            <br />
            <span className="text-primary">&amp; moi functions</span>
          </h2>
          <p className="max-w-md text-lg text-muted-foreground">
            Secure admin access for Moi Kanakku — users, transactions, feedback,
            and device activity in one place.
          </p>
          <div className="flex items-center gap-4 text-sm text-muted-foreground">
            <div className="flex items-center gap-2">
              <Shield className="h-4 w-4 text-status-success" />
              <span>Encrypted session</span>
            </div>
            <div className="flex items-center gap-2">
              <Lock className="h-4 w-4 text-status-info" />
              <span>Token-secured APIs</span>
            </div>
          </div>
        </div>

        <div className="relative z-10 border-t border-border/50 pt-6">
          <p className="text-sm text-muted-foreground/80">
            Best viewed on desktop. Compatible with modern browsers.
          </p>
        </div>

        <div className="absolute -bottom-32 -left-32 h-96 w-96 rounded-full bg-primary/10 blur-3xl" />
        <div className="absolute -top-32 -right-32 h-96 w-96 rounded-full bg-primary/5 blur-3xl" />
      </div>

      <div className="flex w-full items-center justify-center p-8 lg:w-1/2">
        <div className="w-full max-w-md animate-fade-in space-y-8">
          <div className="mb-8 flex flex-col items-center justify-center gap-3 lg:hidden">
            <img
              src="/logo-new.png"
              alt="Moi Kanakku"
              className="h-28 w-auto max-w-[220px] object-contain"
            />
            <p className="text-sm text-muted-foreground">Admin control panel</p>
          </div>

          <div className="space-y-2 text-center lg:text-left">
            <h1 className="text-3xl font-bold">Welcome back</h1>
            <p className="text-muted-foreground">
              Sign in to your admin account to continue
            </p>
          </div>

          {isLocked && (
            <div className="rounded-lg border border-amber-500/30 bg-amber-500/10 px-4 py-3">
              <div className="flex items-start gap-3">
                <Lock className="mt-0.5 h-5 w-5 shrink-0 text-amber-600" />
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-semibold text-amber-800 dark:text-amber-200">
                    Account temporarily locked
                  </p>
                  <p className="mt-1 text-xs text-amber-700/80 dark:text-amber-200/80">
                    Too many failed attempts. Try again after the timer ends.
                  </p>
                  <div className="mt-2 flex flex-wrap items-center gap-2">
                    <span className="rounded-md bg-background/80 px-2.5 py-1 font-mono text-sm font-semibold tabular-nums">
                      {formatCountdown(blockRemainingMs)}
                    </span>
                    <span className="text-xs text-muted-foreground">
                      Retry at{" "}
                      {blockedUntil
                        ? new Date(blockedUntil).toLocaleTimeString([], {
                            hour: "2-digit",
                            minute: "2-digit",
                          })
                        : "—"}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          )}

          {errorMessage && !isLocked && (
            <div
              className={cn(
                "rounded-lg border px-4 py-3",
                errorKind === "forbidden"
                  ? "border-sky-500/30 bg-sky-500/10"
                  : "border-destructive/30 bg-destructive/5"
              )}
            >
              <div className="flex items-start gap-3">
                {errorKind === "forbidden" ? (
                  <Headphones className="mt-0.5 h-5 w-5 shrink-0 text-sky-600" />
                ) : (
                  <AlertTriangle className="mt-0.5 h-5 w-5 shrink-0 text-destructive" />
                )}
                <div className="min-w-0 flex-1">
                  <p
                    className={cn(
                      "text-sm font-medium",
                      errorKind === "forbidden"
                        ? "text-sky-800 dark:text-sky-200"
                        : "text-destructive"
                    )}
                  >
                    {errorMessage}
                  </p>
                  {errorKind === "auth" && attemptNumber !== null && (
                    <p className="mt-1.5 text-xs text-muted-foreground">
                      Attempt {attemptNumber} / {MAX_ATTEMPTS}
                      {attemptsRemaining !== null
                        ? ` · ${attemptsRemaining} remaining`
                        : ""}
                    </p>
                  )}
                  {errorKind === "forbidden" && (
                    <a
                      href={`mailto:${SUPPORT_EMAIL}`}
                      className="mt-2 inline-flex text-xs font-medium text-sky-700 hover:underline dark:text-sky-300"
                    >
                      Contact support — {SUPPORT_EMAIL}
                    </a>
                  )}
                </div>
              </div>
            </div>
          )}

          <form onSubmit={handleLogin} className="space-y-6">
            <div className="space-y-2">
              <Label htmlFor="identifier">Email or Mobile</Label>
              <div className="relative">
                <IdentifierIcon className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <SecureInput
                  id="identifier"
                  fieldName="Identifier"
                  type="text"
                  placeholder="admin@example.com or mobile"
                  className="pl-10 pr-10"
                  value={identifier}
                  onChange={(e) => setIdentifier(e.target.value)}
                  disabled={isLocked || isLoading}
                  required
                />
                {identifier && !isLocked && (
                  <button
                    type="button"
                    onClick={() => setIdentifier("")}
                    className="no-hover-lift absolute inset-y-0 right-0 flex items-center px-3 text-muted-foreground transition-colors hover:text-foreground"
                    aria-label="Clear identifier"
                  >
                    <X className="h-4 w-4" />
                  </button>
                )}
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <div className="relative">
                <Lock className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <SecureInput
                  id="password"
                  fieldName="Password"
                  type={showPassword ? "text" : "password"}
                  placeholder="••••••••"
                  className="pl-10 pr-10"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  disabled={isLocked || isLoading}
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="no-hover-lift absolute inset-y-0 right-0 flex items-center px-3 text-muted-foreground transition-colors hover:text-foreground"
                  aria-label={showPassword ? "Hide password" : "Show password"}
                  disabled={isLocked}
                >
                  {showPassword ? (
                    <EyeOff className="h-4 w-4" />
                  ) : (
                    <Eye className="h-4 w-4" />
                  )}
                </button>
              </div>
            </div>

            <div className="flex justify-end">
              <button
                type="button"
                className="text-sm font-medium text-primary hover:underline"
                onClick={openForgotDialog}
              >
                Forgot Password?
              </button>
            </div>

            <Button
              type="submit"
              className="w-full"
              size="lg"
              disabled={isLoading || isLocked}
            >
              {isLoading
                ? "Signing in..."
                : isLocked
                  ? `Locked — ${formatCountdown(blockRemainingMs)}`
                  : "Sign in"}
            </Button>
          </form>

          <div className="space-y-1 text-center text-sm text-muted-foreground">
            <p>
              © {new Date().getFullYear()} {ENV_CONFIG.COMPANY_NAME}. All rights
              reserved.
            </p>
            <p>
              Created by <span className="font-semibold">gpdhanush</span>
            </p>
            <p className="text-xs font-bold opacity-70">
              Version: {ENV_CONFIG.APP_VERSION}
            </p>
          </div>
        </div>
      </div>

      <Dialog open={forgotOpen} onOpenChange={setForgotOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Forgot password</DialogTitle>
            <DialogDescription>
              Enter your admin email or mobile number. We&apos;ll send a reset
              link to the registered email.
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleForgotPassword} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="forgot-identifier">Email or Mobile</Label>
              <div className="relative">
                <ForgotIcon className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <SecureInput
                  id="forgot-identifier"
                  fieldName="Forgot Identifier"
                  type="text"
                  placeholder="admin@example.com or mobile"
                  className="pl-10"
                  value={forgotIdentifier}
                  onChange={(e) => {
                    setForgotIdentifier(e.target.value);
                    setForgotError(null);
                    setForgotSuccess(null);
                  }}
                  disabled={isForgotLoading}
                  required
                />
              </div>
            </div>

            {forgotError && (
              <div className="rounded-lg border border-destructive/30 bg-destructive/5 px-3 py-2 text-sm text-destructive">
                {forgotError}
              </div>
            )}

            {forgotSuccess && (
              <div className="rounded-lg border border-emerald-500/30 bg-emerald-500/10 px-3 py-2 text-sm text-emerald-700 dark:text-emerald-300">
                {forgotSuccess}
              </div>
            )}

            <DialogFooter className="gap-2 sm:gap-2">
              <Button
                type="button"
                variant="outline"
                onClick={() => setForgotOpen(false)}
                disabled={isForgotLoading}
              >
                Close
              </Button>
              <Button type="submit" disabled={isForgotLoading}>
                {isForgotLoading ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    Sending...
                  </>
                ) : (
                  "Send reset link"
                )}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
