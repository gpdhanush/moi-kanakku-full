import { useMemo, useState } from "react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { Eye, EyeOff, Lock, Shield, Loader2, CheckCircle2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { SecureInput } from "@/components/ui/secure-input";
import { Label } from "@/components/ui/label";
import { authApi } from "@/features/auth/api";
import { toast } from "@/hooks/use-toast";
import { ENV_CONFIG } from "@/lib/config";

export default function ResetPassword() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const token = useMemo(() => searchParams.get("token")?.trim() || "", [searchParams]);

  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!token) {
      setError("Reset token is missing or invalid.");
      return;
    }
    if (password.length < 8) {
      setError("Password must be at least 8 characters.");
      return;
    }
    if (password !== confirmPassword) {
      setError("Passwords do not match.");
      return;
    }

    setIsLoading(true);
    try {
      const result = await authApi.resetPassword(token, password);
      const message = result.message || "Password changed successfully.";
      setSuccess(message);
      toast({
        title: "Password updated",
        description: message,
      });
      window.setTimeout(() => navigate("/login", { replace: true }), 1500);
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Failed to reset password."
      );
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
            Reset your
            <br />
            <span className="text-primary">admin password</span>
          </h2>
          <p className="max-w-md text-lg text-muted-foreground">
            Choose a strong new password to secure your administrator account.
          </p>
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <Shield className="h-4 w-4 text-status-success" />
            <span>Reset links expire in one hour</span>
          </div>
        </div>

        <div className="absolute -bottom-32 -left-32 h-96 w-96 rounded-full bg-primary/10 blur-3xl" />
        <div className="absolute -top-32 -right-32 h-96 w-96 rounded-full bg-primary/5 blur-3xl" />
      </div>

      <div className="flex w-full items-center justify-center p-8 lg:w-1/2">
        <div className="w-full max-w-md animate-fade-in space-y-8">
          <div className="mb-2 flex flex-col items-center justify-center gap-3 lg:hidden">
            <img
              src="/logo-new.png"
              alt="Moi Kanakku"
              className="h-24 w-auto max-w-[200px] object-contain"
            />
          </div>

          <div className="space-y-2 text-center lg:text-left">
            <h1 className="text-3xl font-bold">Set new password</h1>
            <p className="text-muted-foreground">
              Enter and confirm your new admin password
            </p>
          </div>

          {!token && (
            <div className="rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3 text-sm text-destructive">
              This reset link is missing a token. Request a new password reset
              from the login page.
            </div>
          )}

          {success ? (
            <div className="space-y-4 rounded-lg border border-emerald-500/30 bg-emerald-500/10 p-4">
              <div className="flex items-start gap-3">
                <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-emerald-600" />
                <div>
                  <p className="text-sm font-semibold text-emerald-800 dark:text-emerald-200">
                    {success}
                  </p>
                  <p className="mt-1 text-xs text-muted-foreground">
                    Redirecting you to login...
                  </p>
                </div>
              </div>
              <Button asChild className="w-full">
                <Link to="/login">Go to Login</Link>
              </Button>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-5">
              <div className="space-y-2">
                <Label htmlFor="password">New Password</Label>
                <div className="relative">
                  <Lock className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                  <SecureInput
                    id="password"
                    fieldName="New Password"
                    type={showPassword ? "text" : "password"}
                    placeholder="••••••••"
                    className="pl-10 pr-10"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    disabled={isLoading || !token}
                    required
                    minLength={8}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword((p) => !p)}
                    className="no-hover-lift absolute inset-y-0 right-0 flex items-center px-3 text-muted-foreground transition-colors hover:text-foreground"
                    aria-label={showPassword ? "Hide password" : "Show password"}
                  >
                    {showPassword ? (
                      <EyeOff className="h-4 w-4" />
                    ) : (
                      <Eye className="h-4 w-4" />
                    )}
                  </button>
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="confirmPassword">Confirm Password</Label>
                <div className="relative">
                  <Lock className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                  <SecureInput
                    id="confirmPassword"
                    fieldName="Confirm Password"
                    type={showConfirm ? "text" : "password"}
                    placeholder="••••••••"
                    className="pl-10 pr-10"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    disabled={isLoading || !token}
                    required
                    minLength={8}
                  />
                  <button
                    type="button"
                    onClick={() => setShowConfirm((p) => !p)}
                    className="no-hover-lift absolute inset-y-0 right-0 flex items-center px-3 text-muted-foreground transition-colors hover:text-foreground"
                    aria-label={
                      showConfirm ? "Hide confirm password" : "Show confirm password"
                    }
                  >
                    {showConfirm ? (
                      <EyeOff className="h-4 w-4" />
                    ) : (
                      <Eye className="h-4 w-4" />
                    )}
                  </button>
                </div>
              </div>

              {error && (
                <div className="rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3 text-sm text-destructive">
                  {error}
                </div>
              )}

              <Button
                type="submit"
                className="w-full"
                size="lg"
                disabled={isLoading || !token}
              >
                {isLoading ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    Updating...
                  </>
                ) : (
                  "Update password"
                )}
              </Button>

              <p className="text-center text-sm text-muted-foreground">
                Remembered your password?{" "}
                <Link to="/login" className="font-medium text-primary hover:underline">
                  Back to login
                </Link>
              </p>
            </form>
          )}

          <p className="text-center text-xs text-muted-foreground">
            © {new Date().getFullYear()} {ENV_CONFIG.COMPANY_NAME} · v
            {ENV_CONFIG.APP_VERSION}
          </p>
        </div>
      </div>
    </div>
  );
}
