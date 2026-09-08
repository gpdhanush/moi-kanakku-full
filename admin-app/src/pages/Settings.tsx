import { useCallback, useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useMutation, useQuery } from "@tanstack/react-query";
import { useTheme } from "next-themes";
import {
  Settings as SettingsIcon,
  Palette,
  Shield,
  Timer,
  Clock,
  Lock,
  Key,
  User,
  Eye,
  EyeOff,
  CheckCircle2,
  XCircle,
  Loader2,
  AlertCircle,
} from "lucide-react";
import { PageTitle } from "@/components/ui/page-title";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { SecureInput } from "@/components/ui/secure-input";
import { Label } from "@/components/ui/label";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { toast } from "@/hooks/use-toast";
import { usePageMeta } from "@/hooks/usePageMeta";
import { authApi, mfaApi } from "@/features/auth/api";
import { getCurrentUser } from "@/lib/auth";
import {
  applyThemeColor,
  getSessionTimeout,
  getThemeColor,
  MAX_SESSION_TIMEOUT,
  MIN_SESSION_TIMEOUT,
  setSessionTimeout as saveSessionTimeout,
} from "@/lib/settingsPrefs";

const themeColors = [
  { name: "Blue", value: "217 91% 60%" },
  { name: "Green", value: "142 71% 45%" },
  { name: "Purple", value: "262 83% 58%" },
  { name: "Orange", value: "25 95% 53%" },
  { name: "Pink", value: "330 81% 60%" },
  { name: "Red", value: "0 72% 51%" },
  { name: "Teal", value: "173 80% 40%" },
  { name: "Indigo", value: "239 84% 67%" },
  { name: "Cyan", value: "188 78% 41%" },
  { name: "Amber", value: "43 96% 56%" },
  { name: "Lime", value: "75 80% 50%" },
  { name: "Emerald", value: "160 84% 39%" },
  { name: "Violet", value: "258 90% 66%" },
  { name: "Rose", value: "350 89% 60%" },
  { name: "Sky", value: "199 89% 48%" },
  { name: "Indigo Soft", value: "242 57% 58%" },
];

function formatInactivityLabel(minutes: number): string {
  if (minutes < 60) {
    return `${minutes} minute${minutes !== 1 ? "s" : ""} of inactivity`;
  }
  const hours = Math.floor(minutes / 60);
  const mins = minutes % 60;
  const hourPart = `${hours} hour${hours !== 1 ? "s" : ""}`;
  if (!mins) return `${hourPart} of inactivity`;
  return `${hourPart} ${mins} minute${mins !== 1 ? "s" : ""} of inactivity`;
}

export default function Settings() {
  const navigate = useNavigate();
  const metaElement = usePageMeta({
    title: "Settings",
    description: "Manage system configuration and preferences",
  });
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [selectedColor, setSelectedColor] = useState(getThemeColor);
  const [sessionTimeout, setSessionTimeout] = useState(getSessionTimeout);
  const [isSavingTimeout, setIsSavingTimeout] = useState(false);
  const [userTick, setUserTick] = useState(0);
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [mobile, setMobile] = useState("");
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showCurrentPassword, setShowCurrentPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const currentUser = getCurrentUser();
  const userRole = currentUser?.role || currentUser?.status || "Admin";

  useEffect(() => {
    const user = getCurrentUser();
    setFullName(user?.name || "");
    setEmail(user?.email || "");
    setMobile(user?.mobile || "");
  }, [userTick]);

  useEffect(() => {
    const onUserUpdated = () => setUserTick((value) => value + 1);
    window.addEventListener("moi-admin-user-updated", onUserUpdated);
    return () =>
      window.removeEventListener("moi-admin-user-updated", onUserUpdated);
  }, []);

  const {
    data: mfaStatus,
    isLoading: isLoadingMfa,
    isError: isMfaStatusError,
    refetch: refetchMfa,
  } = useQuery({
    queryKey: ["mfa-status"],
    queryFn: () => mfaApi.getStatus(),
    staleTime: 60_000,
    refetchOnWindowFocus: false,
    retry: false,
  });

  const mfaEnabled = Boolean(mfaStatus?.mfaEnabled);
  const mfaRequired = Boolean(mfaStatus?.mfaRequired);

  const updateProfileMutation = useMutation({
    mutationFn: () =>
      authApi.updateProfile({
        full_name: fullName,
        email,
        mobile,
      }),
    onSuccess: (user) => {
      setFullName(user.name || "");
      setEmail(user.email || "");
      setMobile(user.mobile || "");
      setUserTick((value) => value + 1);
      toast({
        title: "Profile updated",
        description: "Your admin profile has been saved.",
      });
    },
    onError: (error: Error) => {
      toast({
        title: "Update failed",
        description: error.message || "Unable to update profile.",
        variant: "destructive",
      });
    },
  });

  const changePasswordMutation = useMutation({
    mutationFn: () =>
      authApi.changePassword({
        current_password: currentPassword,
        new_password: newPassword,
      }),
    onSuccess: (result) => {
      setCurrentPassword("");
      setNewPassword("");
      setConfirmPassword("");
      toast({
        title: "Password changed",
        description: result.message || "Your password was updated successfully.",
      });
    },
    onError: (error: Error) => {
      toast({
        title: "Password change failed",
        description: error.message || "Unable to change password.",
        variant: "destructive",
      });
    },
  });

  const disableMfaMutation = useMutation({
    mutationFn: () => mfaApi.disable(),
    onSuccess: (result) => {
      refetchMfa();
      toast({
        title: "MFA disabled",
        description: result?.message || "MFA has been disabled successfully.",
      });
    },
    onError: (error: Error) => {
      toast({
        title: "Unable to disable MFA",
        description: error.message || "Failed to disable MFA.",
        variant: "destructive",
      });
    },
  });

  const regenerateBackupCodesMutation = useMutation({
    mutationFn: () => mfaApi.regenerateBackupCodes(),
    onSuccess: (data) => {
      const codesText = (data.backupCodes || []).join("\n");
      toast({
        title: "Backup codes regenerated",
        description: "Save the new codes in a safe place.",
      });
      if (codesText) {
        window.alert(
          `Your new backup codes:\n\n${codesText}\n\nSave these codes securely.`
        );
      }
    },
    onError: (error: Error) => {
      toast({
        title: "Unable to regenerate codes",
        description: error.message || "Failed to regenerate backup codes.",
        variant: "destructive",
      });
    },
  });

  useEffect(() => {
    setMounted(true);
    const color = getThemeColor();
    applyThemeColor(color);
    setSelectedColor(color);
    setSessionTimeout(getSessionTimeout());
  }, []);

  const handleColorChange = useCallback((colorValue: string) => {
    setSelectedColor(colorValue);
    applyThemeColor(colorValue);
    toast({
      title: "Theme updated",
      description: "Primary color applied across the dashboard.",
    });
  }, []);

  const handleSaveSessionTimeout = useCallback(() => {
    const timeout = Number(sessionTimeout);
    if (
      !Number.isFinite(timeout) ||
      timeout < MIN_SESSION_TIMEOUT ||
      timeout > MAX_SESSION_TIMEOUT
    ) {
      toast({
        title: "Invalid timeout",
        description: `Enter a value between ${MIN_SESSION_TIMEOUT} and ${MAX_SESSION_TIMEOUT} minutes.`,
        variant: "destructive",
      });
      return;
    }

    setIsSavingTimeout(true);
    const saved = saveSessionTimeout(timeout);
    setSessionTimeout(saved);
    setIsSavingTimeout(false);
    toast({
      title: "Session timeout saved",
      description: `You will be logged out after ${formatInactivityLabel(saved)}.`,
    });
  }, [sessionTimeout]);

  const inactivityLabel = useMemo(
    () => formatInactivityLabel(Number(sessionTimeout) || 0),
    [sessionTimeout]
  );

  const handleSaveProfile = (e: React.FormEvent) => {
    e.preventDefault();
    if (!fullName.trim() || !email.trim() || !mobile.trim()) {
      toast({
        title: "Missing details",
        description: "Full name, email, and mobile are required.",
        variant: "destructive",
      });
      return;
    }
    updateProfileMutation.mutate();
  };

  const handleChangePassword = (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentPassword || !newPassword) {
      toast({
        title: "Missing password",
        description: "Enter your current and new password.",
        variant: "destructive",
      });
      return;
    }
    if (newPassword.length < 8) {
      toast({
        title: "Weak password",
        description: "New password must be at least 8 characters.",
        variant: "destructive",
      });
      return;
    }
    if (newPassword !== confirmPassword) {
      toast({
        title: "Passwords do not match",
        description: "Confirm password must match the new password.",
        variant: "destructive",
      });
      return;
    }
    changePasswordMutation.mutate();
  };

  return (
    <div className="space-y-6 animate-fade-in">
      {metaElement}
      <PageTitle
        title="Settings"
        description="Manage system configuration and preferences"
        icon={SettingsIcon}
      />

      <div className="grid gap-6 xl:grid-cols-2">
        <div className="space-y-6">
          <Card className="glass-card border-2">
            <CardHeader className="pb-4">
              <div className="flex items-center gap-3">
                <div className="rounded-lg bg-primary/10 p-2">
                  <User className="h-5 w-5 text-primary" />
                </div>
                <div>
                  <CardTitle>Admin Profile</CardTitle>
                  <CardDescription>
                    Update your name, email, and mobile number
                  </CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSaveProfile} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="full_name">Full Name</Label>
                  <Input
                    id="full_name"
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    placeholder="Your full name"
                    disabled={updateProfileMutation.isPending}
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="email">Email</Label>
                  <Input
                    id="email"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="admin@example.com"
                    disabled={updateProfileMutation.isPending}
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="mobile">Mobile</Label>
                  <Input
                    id="mobile"
                    value={mobile}
                    onChange={(e) => setMobile(e.target.value)}
                    placeholder="Mobile number"
                    disabled={updateProfileMutation.isPending}
                    required
                  />
                </div>
                <Button
                  type="submit"
                  className="w-full"
                  disabled={updateProfileMutation.isPending}
                >
                  {updateProfileMutation.isPending ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      Saving...
                    </>
                  ) : (
                    <>
                      <CheckCircle2 className="mr-2 h-4 w-4" />
                      Save Profile
                    </>
                  )}
                </Button>
              </form>
            </CardContent>
          </Card>

          <Card className="glass-card border-2">
            <CardHeader className="pb-4">
              <div className="flex items-center gap-3">
                <div className="rounded-lg bg-primary/10 p-2">
                  <Palette className="h-5 w-5 text-primary" />
                </div>
                <div>
                  <CardTitle>Appearance</CardTitle>
                  <CardDescription>
                    Customize how the admin dashboard looks
                  </CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between gap-4">
                <div className="space-y-0.5">
                  <Label>Theme Mode</Label>
                  <p className="text-xs text-muted-foreground">
                    Choose between light and dark mode
                  </p>
                </div>
                {mounted && (
                  <Select value={theme} onValueChange={setTheme}>
                    <SelectTrigger className="w-40">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="light">Light</SelectItem>
                      <SelectItem value="dark">Dark</SelectItem>
                      <SelectItem value="system">System</SelectItem>
                    </SelectContent>
                  </Select>
                )}
              </div>

              <Separator />

              <div className="space-y-3">
                <div>
                  <Label>Theme Color</Label>
                  <p className="mb-4 text-xs text-muted-foreground">
                    Select a primary color for your dashboard
                  </p>
                  <div className="grid grid-cols-4 gap-3 rounded-lg border-2 border-border/50 bg-muted/30 p-4">
                    {themeColors.map((color) => (
                      <button
                        key={color.value}
                        type="button"
                        title={color.name}
                        onClick={() => handleColorChange(color.value)}
                        className={`relative h-12 w-full rounded-lg border-2 transition-all hover:scale-105 hover:shadow-md ${
                          selectedColor === color.value
                            ? "scale-105 border-foreground/40 ring-4 ring-primary/30 shadow-lg"
                            : "border-border/40"
                        }`}
                        style={{ backgroundColor: `hsl(${color.value})` }}
                      >
                        {selectedColor === color.value && (
                          <span className="absolute inset-0 flex items-center justify-center">
                            <span className="flex h-6 w-6 items-center justify-center rounded-full bg-white/95 shadow">
                              <CheckCircle2 className="h-4 w-4 text-primary" />
                            </span>
                          </span>
                        )}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="glass-card border-2">
            <CardHeader className="pb-4">
              <div className="flex items-center gap-3">
                <div className="rounded-lg bg-primary/10 p-2">
                  <Timer className="h-5 w-5 text-primary" />
                </div>
                <div>
                  <CardTitle>Session Timeout</CardTitle>
                  <CardDescription>
                    Configure automatic logout after inactivity
                  </CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-4 rounded-lg border-2 border-border/50 bg-muted/40 p-4">
                <div className="flex items-center justify-center">
                  <div className="relative">
                    <Input
                      type="number"
                      min={MIN_SESSION_TIMEOUT}
                      max={MAX_SESSION_TIMEOUT}
                      value={sessionTimeout}
                      onChange={(e) =>
                        setSessionTimeout(Number(e.target.value) || 0)
                      }
                      className="w-32 pr-12 text-center text-lg font-semibold"
                    />
                    <span className="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-muted-foreground">
                      min
                    </span>
                  </div>
                </div>
                <div className="flex items-center justify-center gap-2 text-xs text-muted-foreground">
                  <Clock className="h-3 w-3" />
                  <span>{inactivityLabel}</span>
                </div>
                <div className="flex items-center justify-center gap-2 text-xs text-muted-foreground">
                  <Lock className="h-3 w-3" />
                  <span>
                    Range: {MIN_SESSION_TIMEOUT} - {MAX_SESSION_TIMEOUT} minutes
                    (1 day)
                  </span>
                </div>
              </div>

              <Button
                onClick={handleSaveSessionTimeout}
                disabled={isSavingTimeout}
                className="w-full"
              >
                {isSavingTimeout ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    Saving...
                  </>
                ) : (
                  <>
                    <CheckCircle2 className="mr-2 h-4 w-4" />
                    Save Session Timeout
                  </>
                )}
              </Button>
            </CardContent>
          </Card>
        </div>

        <div className="space-y-6">
          <Card className="glass-card border-2">
            <CardHeader className="pb-4">
              <div className="flex items-center gap-3">
                <div className="rounded-lg bg-primary/10 p-2">
                  <Lock className="h-5 w-5 text-primary" />
                </div>
                <div>
                  <CardTitle>Change Password</CardTitle>
                  <CardDescription>
                    Verify your current password before setting a new one
                  </CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleChangePassword} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="current_password">Current Password</Label>
                  <div className="relative">
                    <SecureInput
                      id="current_password"
                      fieldName="Current Password"
                      type={showCurrentPassword ? "text" : "password"}
                      className="pr-10"
                      value={currentPassword}
                      onChange={(e) => setCurrentPassword(e.target.value)}
                      disabled={changePasswordMutation.isPending}
                      required
                    />
                    <button
                      type="button"
                      className="no-hover-lift absolute inset-y-0 right-0 flex items-center px-3 text-muted-foreground hover:text-foreground"
                      onClick={() => setShowCurrentPassword((v) => !v)}
                      aria-label={
                        showCurrentPassword
                          ? "Hide current password"
                          : "Show current password"
                      }
                    >
                      {showCurrentPassword ? (
                        <EyeOff className="h-4 w-4" />
                      ) : (
                        <Eye className="h-4 w-4" />
                      )}
                    </button>
                  </div>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="new_password">New Password</Label>
                  <div className="relative">
                    <SecureInput
                      id="new_password"
                      fieldName="New Password"
                      type={showNewPassword ? "text" : "password"}
                      className="pr-10"
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                      disabled={changePasswordMutation.isPending}
                      required
                      minLength={8}
                    />
                    <button
                      type="button"
                      className="no-hover-lift absolute inset-y-0 right-0 flex items-center px-3 text-muted-foreground hover:text-foreground"
                      onClick={() => setShowNewPassword((v) => !v)}
                      aria-label={
                        showNewPassword
                          ? "Hide new password"
                          : "Show new password"
                      }
                    >
                      {showNewPassword ? (
                        <EyeOff className="h-4 w-4" />
                      ) : (
                        <Eye className="h-4 w-4" />
                      )}
                    </button>
                  </div>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="confirm_password">Confirm New Password</Label>
                  <div className="relative">
                    <SecureInput
                      id="confirm_password"
                      fieldName="Confirm New Password"
                      type={showConfirmPassword ? "text" : "password"}
                      className="pr-10"
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                      disabled={changePasswordMutation.isPending}
                      required
                      minLength={8}
                    />
                    <button
                      type="button"
                      className="no-hover-lift absolute inset-y-0 right-0 flex items-center px-3 text-muted-foreground hover:text-foreground"
                      onClick={() => setShowConfirmPassword((v) => !v)}
                      aria-label={
                        showConfirmPassword
                          ? "Hide confirm password"
                          : "Show confirm password"
                      }
                    >
                      {showConfirmPassword ? (
                        <EyeOff className="h-4 w-4" />
                      ) : (
                        <Eye className="h-4 w-4" />
                      )}
                    </button>
                  </div>
                </div>

                <Button
                  type="submit"
                  className="w-full"
                  disabled={changePasswordMutation.isPending}
                >
                  {changePasswordMutation.isPending ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      Updating...
                    </>
                  ) : (
                    <>
                      <Key className="mr-2 h-4 w-4" />
                      Update Password
                    </>
                  )}
                </Button>
              </form>
            </CardContent>
          </Card>

          <Card className="glass-card h-fit border-2">
            <CardHeader className="pb-4">
              <div className="flex items-center justify-between gap-3">
                <div className="flex items-center gap-3">
                  <div className="rounded-lg bg-primary/10 p-2">
                    <Shield className="h-5 w-5 text-primary" />
                  </div>
                  <div>
                    <CardTitle>Security</CardTitle>
                    <CardDescription>
                      Protect your account with advanced security
                    </CardDescription>
                  </div>
                </div>
                {!isLoadingMfa && (
                  <Badge
                    variant={mfaEnabled ? "default" : "secondary"}
                    className={
                      mfaEnabled
                        ? "border-transparent bg-emerald-500/15 px-3 py-1 text-emerald-700 dark:text-emerald-300"
                        : "px-3 py-1"
                    }
                  >
                    {mfaEnabled ? (
                      <>
                        <CheckCircle2 className="mr-1 h-3 w-3" />
                        Enabled
                      </>
                    ) : (
                      <>
                        <XCircle className="mr-1 h-3 w-3" />
                        Disabled
                      </>
                    )}
                  </Badge>
                )}
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              {isLoadingMfa ? (
                <div className="flex items-center justify-center py-8">
                  <Loader2 className="h-5 w-5 animate-spin text-primary" />
                </div>
              ) : (
                <>
                  {isMfaStatusError && (
                    <Alert className="border-amber-200 bg-amber-50 dark:border-amber-800 dark:bg-amber-950/20">
                      <AlertCircle className="h-4 w-4 text-amber-600 dark:text-amber-400" />
                      <AlertDescription className="text-amber-800 dark:text-amber-200">
                        Could not load MFA status from the API. You can still try
                        setup if MFA endpoints are available.
                      </AlertDescription>
                    </Alert>
                  )}

                  {mfaRequired && (
                    <Alert className="border-amber-200 bg-amber-50 dark:border-amber-800 dark:bg-amber-950/20">
                      <AlertCircle className="h-4 w-4 text-amber-600 dark:text-amber-400" />
                      <AlertDescription className="text-amber-800 dark:text-amber-200">
                        MFA is required for your role ({userRole}) and cannot be
                        disabled.
                      </AlertDescription>
                    </Alert>
                  )}

                  {mfaEnabled ? (
                    <div className="space-y-3">
                      <div className="rounded-lg border border-emerald-200 bg-emerald-50/80 p-4 dark:border-emerald-900 dark:bg-emerald-950/30">
                        <div className="mb-2 flex items-center justify-between">
                          <span className="text-sm font-medium">Status</span>
                          <Badge className="border-transparent bg-emerald-500/15 text-emerald-700 dark:text-emerald-300">
                            <CheckCircle2 className="mr-1 h-3 w-3" />
                            Active
                          </Badge>
                        </div>
                        <p className="text-sm text-muted-foreground">
                          MFA is active on your account. You&apos;ll need your
                          authenticator app when signing in.
                        </p>
                        {typeof mfaStatus?.backupCodesCount === "number" && (
                          <p className="mt-2 text-xs text-muted-foreground">
                            Backup codes remaining: {mfaStatus.backupCodesCount}
                          </p>
                        )}
                        {mfaStatus?.mfaVerifiedAt && (
                          <p className="mt-1 text-xs text-muted-foreground">
                            Last verified:{" "}
                            {new Date(
                              mfaStatus.mfaVerifiedAt
                            ).toLocaleDateString()}
                          </p>
                        )}
                      </div>

                      <Button
                        variant="outline"
                        onClick={() => navigate("/mfa/setup")}
                        className="w-full"
                      >
                        <Shield className="mr-2 h-4 w-4" />
                        Reconfigure MFA
                      </Button>
                      <Button
                        variant="outline"
                        onClick={() => regenerateBackupCodesMutation.mutate()}
                        disabled={regenerateBackupCodesMutation.isPending}
                        className="w-full"
                      >
                        {regenerateBackupCodesMutation.isPending ? (
                          <>
                            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                            Regenerating...
                          </>
                        ) : (
                          <>
                            <Key className="mr-2 h-4 w-4" />
                            Regenerate Backup Codes
                          </>
                        )}
                      </Button>

                      {!mfaRequired && (
                        <Button
                          variant="destructive"
                          onClick={() => {
                            if (
                              window.confirm(
                                "Are you sure you want to disable MFA? This will make your account less secure."
                              )
                            ) {
                              disableMfaMutation.mutate();
                            }
                          }}
                          disabled={disableMfaMutation.isPending}
                          className="w-full"
                        >
                          {disableMfaMutation.isPending ? (
                            <>
                              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                              Disabling...
                            </>
                          ) : (
                            <>
                              <XCircle className="mr-2 h-4 w-4" />
                              Disable MFA
                            </>
                          )}
                        </Button>
                      )}
                    </div>
                  ) : (
                    <div className="rounded-lg border-2 border-primary/20 bg-gradient-to-br from-primary/5 via-primary/10 to-primary/5 p-6 shadow-sm dark:from-primary/10 dark:via-primary/20 dark:to-primary/10">
                      <div className="flex flex-col items-center space-y-4 text-center">
                        <div className="rounded-full bg-primary/20 p-3 dark:bg-primary/30">
                          <Shield className="h-6 w-6 text-primary" />
                        </div>
                        <div className="space-y-2">
                          <h3 className="text-base font-semibold">
                            Enable Multi-Factor Authentication
                          </h3>
                          <p className="max-w-sm text-sm text-muted-foreground">
                            Protect your account with two-factor authentication.
                            You&apos;ll need an authenticator app like Google
                            Authenticator or Authy.
                          </p>
                        </div>
                        <Button
                          className="mt-2 w-full"
                          size="lg"
                          onClick={() => navigate("/mfa/setup")}
                        >
                          <Shield className="mr-2 h-4 w-4" />
                          Set Up MFA
                        </Button>
                      </div>
                    </div>
                  )}
                </>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
