import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useQueryClient } from "@tanstack/react-query";
import QRCode from "qrcode";
import { Shield, Copy, CheckCircle2, AlertCircle, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { mfaApi } from "@/features/auth/api";
import { getCurrentUser } from "@/lib/auth";
import { ENV_CONFIG } from "@/lib/config";
import { toast } from "@/hooks/use-toast";

async function buildAccountQrCode(secret: string, email: string): Promise<string> {
  const issuer = ENV_CONFIG.COMPANY_NAME || "Moi Kanakku";
  const account = (email || "admin").trim();
  // Keep secret as returned by backend (base32). Do not alter casing/encoding.
  const cleanSecret = secret.replace(/\s+/g, "");
  const label = encodeURIComponent(`${issuer}:${account}`);
  const otpauth = `otpauth://totp/${label}?secret=${cleanSecret}&issuer=${encodeURIComponent(issuer)}`;
  return QRCode.toDataURL(otpauth, {
    width: 256,
    margin: 2,
    errorCorrectionLevel: "M",
  });
}

export default function MFASetup() {
  const [step, setStep] = useState<"qr" | "verify">("qr");
  const [qrCode, setQrCode] = useState<string>("");
  const [secret, setSecret] = useState<string>("");
  const [accountEmail, setAccountEmail] = useState<string>("");
  const [backupCodes, setBackupCodes] = useState<string[]>([]);
  const [verificationCode, setVerificationCode] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [isSettingUp, setIsSettingUp] = useState(true);
  const [setupError, setSetupError] = useState<string | null>(null);
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  useEffect(() => {
    loadMFASetup();
  }, []);

  const loadMFASetup = async () => {
    try {
      setIsSettingUp(true);
      setSetupError(null);
      const response = await mfaApi.setup();
      const user = getCurrentUser();
      const email = String(user?.email || "").trim();
      setAccountEmail(email);
      setSecret(response.secret);
      setBackupCodes(response.backupCodes);

      // Rebuild QR with the logged-in admin email so authenticator apps
      // don't show a stale/wrong label from the backend QR payload.
      if (email) {
        setQrCode(await buildAccountQrCode(response.secret, email));
      } else {
        setQrCode(response.qrCode);
      }
    } catch (error: any) {
      const message = error.message || "Failed to load MFA setup";
      setSetupError(message);
      toast({
        title: "Error",
        description: message,
        variant: "destructive",
      });
    } finally {
      setIsSettingUp(false);
    }
  };

  const handleVerify = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      await mfaApi.verifySetup(verificationCode, secret);
      await queryClient.invalidateQueries({ queryKey: ["mfa-status"] });

      toast({
        title: "Success",
        description: "MFA has been enabled successfully",
      });

      navigate("/settings");
    } catch (error: any) {
      toast({
        title: "Verification failed",
        description: error.message || "Invalid verification code",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
    toast({
      title: "Copied",
      description: "Copied to clipboard",
    });
  };

  if (isSettingUp) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <div className="space-y-4 text-center">
          <Loader2 className="mx-auto h-8 w-8 animate-spin text-primary" />
          <p className="text-muted-foreground">Setting up MFA...</p>
        </div>
      </div>
    );
  }

  if (setupError) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center p-4">
        <Card className="w-full max-w-lg">
          <CardHeader>
            <div className="flex items-center gap-2">
              <Shield className="h-6 w-6 text-primary" />
              <CardTitle>MFA Setup Unavailable</CardTitle>
            </div>
            <CardDescription>{setupError}</CardDescription>
          </CardHeader>
          <CardContent className="flex gap-2">
            <Button variant="outline" onClick={() => navigate("/settings")} className="flex-1">
              Back to Settings
            </Button>
            <Button onClick={loadMFASetup} className="flex-1">
              Try Again
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen items-center justify-center p-4 bg-gradient-to-br from-primary/5 via-background to-background">
      <Card className="w-full max-w-2xl">
        <CardHeader>
          <div className="flex items-center gap-2">
            <Shield className="h-6 w-6 text-primary" />
            <CardTitle>Set Up Multi-Factor Authentication</CardTitle>
          </div>
          <CardDescription>
            Secure your account with two-factor authentication
          </CardDescription>
        </CardHeader>
        <CardContent>
          {step === "qr" && (
            <div className="space-y-6">
              <Alert>
                <AlertCircle className="h-4 w-4" />
                <AlertDescription>
                  Scan the QR code with an authenticator app like Google Authenticator, Authy, or Microsoft Authenticator.
                  {accountEmail ? (
                    <>
                      {" "}
                      This account will appear as{" "}
                      <span className="font-medium text-foreground">{accountEmail}</span>.
                    </>
                  ) : null}
                </AlertDescription>
              </Alert>

              <div className="flex flex-col items-center space-y-4">
                <div className="p-4 bg-white rounded-lg border-2 border-primary/20">
                  <img src={qrCode} alt="QR Code" className="w-64 h-64" />
                </div>

                <div className="w-full space-y-2">
                  <Label>Manual Entry Key</Label>
                  <div className="flex gap-2">
                    <Input
                      value={secret}
                      readOnly
                      className="font-mono text-sm"
                    />
                    <Button
                      type="button"
                      variant="outline"
                      size="icon"
                      onClick={() => copyToClipboard(secret)}
                    >
                      <Copy className="h-4 w-4" />
                    </Button>
                  </div>
                  <p className="text-xs text-muted-foreground">
                    Use this key if you cannot scan the QR code
                  </p>
                </div>
              </div>

              <div className="space-y-4">
                <div>
                  <Label className="text-base font-semibold">Backup Codes</Label>
                  <p className="text-sm text-muted-foreground mb-2">
                    Save these codes in a safe place. You can use them to access your account if you lose your device.
                  </p>
                  <div className="grid grid-cols-2 gap-2 p-4 bg-muted rounded-lg">
                    {backupCodes.map((code, index) => (
                      <div
                        key={index}
                        className="flex items-center justify-between p-2 bg-background rounded border"
                      >
                        <code className="text-sm font-mono">{code}</code>
                        <Button
                          type="button"
                          variant="ghost"
                          size="icon"
                          className="h-6 w-6"
                          onClick={() => copyToClipboard(code)}
                        >
                          <Copy className="h-3 w-3" />
                        </Button>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              <div className="flex gap-2">
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => navigate("/settings")}
                  className="flex-1"
                >
                  Cancel
                </Button>
                <Button
                  onClick={() => setStep("verify")}
                  className="flex-1"
                  size="lg"
                >
                  I've scanned the QR code
                </Button>
              </div>
            </div>
          )}

          {step === "verify" && (
            <form onSubmit={handleVerify} className="space-y-6">
              <Alert>
                <AlertCircle className="h-4 w-4" />
                <AlertDescription>
                  Enter the 6-digit code from your authenticator app to verify and enable MFA.
                </AlertDescription>
              </Alert>

              <div className="space-y-2">
                <Label htmlFor="code">Verification Code</Label>
                <Input
                  id="code"
                  type="text"
                  placeholder="000000"
                  maxLength={6}
                  value={verificationCode}
                  onChange={(e) => setVerificationCode(e.target.value.replace(/\D/g, ""))}
                  className="text-center text-2xl font-mono tracking-widest"
                  required
                  autoFocus
                />
                <p className="text-xs text-muted-foreground">
                  Enter the 6-digit code from your authenticator app
                </p>
              </div>

              <div className="flex gap-2">
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => setStep("qr")}
                  className="flex-1"
                >
                  Back
                </Button>
                <Button
                  type="submit"
                  className="flex-1"
                  size="lg"
                  disabled={verificationCode.length !== 6 || isLoading}
                >
                  {isLoading ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      Verifying...
                    </>
                  ) : (
                    <>
                      <CheckCircle2 className="mr-2 h-4 w-4" />
                      Verify & Enable
                    </>
                  )}
                </Button>
              </div>
            </form>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
