import { useEffect, useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import QRCode from "qrcode";
import { ImageUp, Loader2, QrCode, Save, Settings2, Trash2 } from "lucide-react";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { toast } from "@/hooks/use-toast";
import { formatDateTime } from "@/lib/formatters";
import { exportPaymentsApi, type ExportPaymentSettings } from "./api";

const SETTINGS_KEY = ["admin", "export-payments", "settings"] as const;
const UPI_ID_PATTERN = /^[a-zA-Z0-9._-]{2,256}@[a-zA-Z][a-zA-Z0-9.-]{1,64}$/;
const ACCEPTED_TYPES = ["image/png", "image/jpeg", "image/webp"];
const MAX_QR_BYTES = 2 * 1024 * 1024;

/** Admin-editable UPI payee details and QR image for paid PDF export. */
export function PaymentSettingsCard() {
  const queryClient = useQueryClient();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [upiId, setUpiId] = useState("");
  const [payeeName, setPayeeName] = useState("");
  const [amount, setAmount] = useState("49");
  const [generatedQr, setGeneratedQr] = useState<string | null>(null);

  const { data, isLoading, isError, error } = useQuery({
    queryKey: SETTINGS_KEY,
    queryFn: exportPaymentsApi.getSettings,
    staleTime: 60_000,
  });

  useEffect(() => {
    if (!data) return;
    setUpiId(data.upiId);
    setPayeeName(data.payeeName);
    setAmount(String(data.amount ?? 49));
  }, [data]);

  // Preview of the QR the app generates from the saved UPI ID.
  useEffect(() => {
    let cancelled = false;
    if (!data?.upiUri) {
      setGeneratedQr(null);
      return;
    }
    QRCode.toDataURL(data.upiUri, { width: 220, margin: 1 })
      .then((url) => !cancelled && setGeneratedQr(url))
      .catch(() => !cancelled && setGeneratedQr(null));
    return () => {
      cancelled = true;
    };
  }, [data?.upiUri]);

  const onSaved = (settings: ExportPaymentSettings, title: string) => {
    queryClient.setQueryData(SETTINGS_KEY, settings);
    toast({ title });
  };
  const onFailed = (err: Error) =>
    toast({ title: "Not saved", description: err.message, variant: "destructive" });

  const saveMutation = useMutation({
    mutationFn: exportPaymentsApi.saveSettings,
    onSuccess: (s) => onSaved(s, "Payment settings saved"),
    onError: onFailed,
  });
  const uploadMutation = useMutation({
    mutationFn: exportPaymentsApi.uploadQr,
    onSuccess: (s) => onSaved(s, "QR image uploaded"),
    onError: onFailed,
  });
  const removeMutation = useMutation({
    mutationFn: exportPaymentsApi.removeQr,
    onSuccess: (s) => onSaved(s, "QR image removed"),
    onError: onFailed,
  });

  const trimmedUpi = upiId.trim();
  const amountValue = Number.parseFloat(amount);
  const upiInvalid = trimmedUpi.length > 0 && !UPI_ID_PATTERN.test(trimmedUpi);
  const nameMissing = trimmedUpi.length > 0 && payeeName.trim().length === 0;
  const amountInvalid = !Number.isFinite(amountValue) || amountValue < 1 || amountValue > 100000;
  const dirty =
    !!data &&
    (trimmedUpi !== data.upiId ||
      payeeName.trim() !== data.payeeName ||
      amountValue !== data.amount);
  const busy = saveMutation.isPending || uploadMutation.isPending || removeMutation.isPending;

  const onFileChosen = (file: File | undefined) => {
    if (fileInputRef.current) fileInputRef.current.value = "";
    if (!file) return;
    if (!ACCEPTED_TYPES.includes(file.type)) {
      onFailed(new Error("Upload a PNG, JPG or WEBP image."));
      return;
    }
    if (file.size > MAX_QR_BYTES) {
      onFailed(new Error("QR image must be 2 MB or smaller."));
      return;
    }
    uploadMutation.mutate(file);
  };

  return (
    <Card>
      <CardHeader className="pb-3">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <CardTitle className="flex items-center gap-2 text-base">
            <Settings2 className="h-4 w-4" />
            Payment settings
          </CardTitle>
          {data && (
            <Badge
              className={
                data.configured
                  ? "border-transparent bg-emerald-500/15 text-emerald-700 dark:text-emerald-300"
                  : "border-transparent bg-amber-500/15 text-amber-700 dark:text-amber-300"
              }
            >
              {data.configured ? "Payments on" : "Not set up — app shows payments unavailable"}
            </Badge>
          )}
        </div>
        <CardDescription>
          Users scan this QR in the app to pay before PDF export.
          {data?.updatedAt &&
            ` Last updated ${formatDateTime(data.updatedAt)}${
              data.updatedByName ? ` by ${data.updatedByName}` : ""
            }.`}
        </CardDescription>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="flex h-32 items-center justify-center text-sm text-muted-foreground">
            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            Loading settings...
          </div>
        ) : isError ? (
          <p className="text-sm text-destructive">
            {(error as Error)?.message || "Failed to load payment settings."}
          </p>
        ) : (
          <div className="grid gap-6 lg:grid-cols-[1fr,auto]">
            <form
              className="grid gap-4 sm:grid-cols-2"
              onSubmit={(event) => {
                event.preventDefault();
                if (upiInvalid || nameMissing || amountInvalid) return;
                saveMutation.mutate({
                  upiId: trimmedUpi,
                  payeeName: payeeName.trim(),
                  amount: amountValue,
                });
              }}
            >
              <div className="space-y-1.5">
                <Label htmlFor="export-upi-id">UPI ID</Label>
                <Input
                  id="export-upi-id"
                  value={upiId}
                  onChange={(e) => setUpiId(e.target.value)}
                  placeholder="yourname@okaxis"
                  autoComplete="off"
                  aria-invalid={upiInvalid}
                />
                {upiInvalid && (
                  <p className="text-xs text-destructive">Enter a valid UPI ID, e.g. name@okaxis.</p>
                )}
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="export-payee-name">Payee name</Label>
                <Input
                  id="export-payee-name"
                  value={payeeName}
                  maxLength={100}
                  onChange={(e) => setPayeeName(e.target.value)}
                  placeholder="Name shown in UPI apps"
                  aria-invalid={nameMissing}
                />
                {nameMissing && (
                  <p className="text-xs text-destructive">Payee name is required with a UPI ID.</p>
                )}
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="export-amount">Amount (₹)</Label>
                <Input
                  id="export-amount"
                  type="number"
                  inputMode="decimal"
                  min={1}
                  max={100000}
                  step="0.01"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  aria-invalid={amountInvalid}
                />
                {amountInvalid && (
                  <p className="text-xs text-destructive">Amount must be between ₹1 and ₹1,00,000.</p>
                )}
              </div>
              <div className="flex items-end">
                <Button
                  type="submit"
                  className="gap-2"
                  disabled={!dirty || busy || upiInvalid || nameMissing || amountInvalid}
                >
                  {saveMutation.isPending ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    <Save className="h-4 w-4" />
                  )}
                  Save details
                </Button>
              </div>
              <p className="text-xs text-muted-foreground sm:col-span-2">
                With a UPI ID, the app builds a QR for the exact amount and shows a "Pay with UPI app"
                button. An uploaded QR image is shown instead when one is set — make sure it pays the
                same account.
              </p>
            </form>

            <div className="flex flex-col items-center gap-3">
              <div className="flex h-[220px] w-[220px] items-center justify-center overflow-hidden rounded-lg border bg-white">
                {data?.qrImageUrl ? (
                  <img
                    src={data.qrImageUrl}
                    alt="Uploaded UPI QR code"
                    className="h-full w-full object-contain"
                  />
                ) : generatedQr ? (
                  <img src={generatedQr} alt="QR generated from the UPI ID" className="h-full w-full" />
                ) : (
                  <div className="flex flex-col items-center gap-2 px-4 text-center text-xs text-slate-500">
                    <QrCode className="h-8 w-8" />
                    Add a UPI ID or upload a QR image
                  </div>
                )}
              </div>
              <p className="text-xs text-muted-foreground">
                {data?.qrImageUrl ? "Uploaded QR (shown in app)" : generatedQr ? "Generated from UPI ID" : ""}
              </p>
              <input
                ref={fileInputRef}
                type="file"
                accept={ACCEPTED_TYPES.join(",")}
                className="hidden"
                onChange={(e) => onFileChosen(e.target.files?.[0])}
              />
              <div className="flex gap-2">
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  className="gap-2"
                  disabled={busy}
                  onClick={() => fileInputRef.current?.click()}
                >
                  {uploadMutation.isPending ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    <ImageUp className="h-4 w-4" />
                  )}
                  {data?.qrImageUrl ? "Replace QR" : "Upload QR"}
                </Button>
                {data?.qrImageUrl && (
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    className="gap-2 border-destructive/40 text-destructive hover:bg-destructive/10 hover:text-destructive"
                    disabled={busy}
                    onClick={() => removeMutation.mutate()}
                  >
                    {removeMutation.isPending ? (
                      <Loader2 className="h-4 w-4 animate-spin" />
                    ) : (
                      <Trash2 className="h-4 w-4" />
                    )}
                    Remove
                  </Button>
                )}
              </div>
              <p className="text-xs text-muted-foreground">PNG, JPG or WEBP, up to 2 MB</p>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
