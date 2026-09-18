import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Megaphone,
  Plus,
  RefreshCw,
  Loader2,
  Trash2,
  Power,
  PowerOff,
  ExternalLink,
  Image as ImageIcon,
  Video,
} from "lucide-react";
import { PageTitle } from "@/components/ui/page-title";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { usePageMeta } from "@/hooks/usePageMeta";
import { toast } from "@/hooks/use-toast";
import {
  appAlertsApi,
  type AppAlertItem,
  type CreateAppAlertPayload,
} from "@/features/appAlerts/api";
import { formatDateTime } from "@/lib/formatters";
import { cn } from "@/lib/utils";

const EMPTY_FORM: CreateAppAlertPayload = {
  title: "",
  content: "",
  imageUrl: "",
  videoUrl: "",
  ctaLabel: "",
  ctaUrl: "",
  isActive: true,
};

export default function AppAlerts() {
  const queryClient = useQueryClient();
  const metaElement = usePageMeta({
    title: "App Alerts",
    description: "Create in-app popup alerts shown after splash on mobile.",
  });
  const [createOpen, setCreateOpen] = useState(false);
  const [form, setForm] = useState<CreateAppAlertPayload>(EMPTY_FORM);
  const [deleteId, setDeleteId] = useState<string | null>(null);

  const { data, isLoading, isFetching, isError, error, refetch } = useQuery({
    queryKey: ["app-alerts"],
    queryFn: () => appAlertsApi.list({ page: 1, limit: 50 }),
  });

  const alerts = useMemo(() => data?.data ?? [], [data]);

  const createMutation = useMutation({
    mutationFn: () =>
      appAlertsApi.create({
        title: form.title.trim(),
        content: form.content.trim(),
        imageUrl: form.imageUrl?.trim() || undefined,
        videoUrl: form.videoUrl?.trim() || undefined,
        ctaLabel: form.ctaLabel?.trim() || undefined,
        ctaUrl: form.ctaUrl?.trim() || undefined,
        isActive: form.isActive !== false,
      }),
    onSuccess: () => {
      toast({
        title: "Alert published",
        description: "Logged-in users will see this popup after splash.",
      });
      setCreateOpen(false);
      setForm(EMPTY_FORM);
      queryClient.invalidateQueries({ queryKey: ["app-alerts"] });
    },
    onError: (err: Error) => {
      toast({
        title: "Failed to create alert",
        description: err.message,
        variant: "destructive",
      });
    },
  });

  const toggleMutation = useMutation({
    mutationFn: ({ id, isActive }: { id: string; isActive: boolean }) =>
      appAlertsApi.update(id, { isActive }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["app-alerts"] });
      toast({ title: "Alert updated" });
    },
    onError: (err: Error) => {
      toast({
        title: "Failed to update alert",
        description: err.message,
        variant: "destructive",
      });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => appAlertsApi.remove(id),
    onSuccess: () => {
      setDeleteId(null);
      queryClient.invalidateQueries({ queryKey: ["app-alerts"] });
      toast({ title: "Alert deleted" });
    },
    onError: (err: Error) => {
      toast({
        title: "Failed to delete alert",
        description: err.message,
        variant: "destructive",
      });
    },
  });

  const canSubmit =
    form.title.trim().length > 0 &&
    form.content.trim().length > 0 &&
    !createMutation.isPending;

  return (
    <div className="space-y-6">
      {metaElement}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <PageTitle
          title="App Alerts"
          icon={Megaphone}
          description="In-app popups after splash (title, content, image, video link). New alerts show again; dismissed ones stay hidden per user."
        />
        <div className="flex gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => refetch()}
            disabled={isFetching}
          >
            {isFetching ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <RefreshCw className="h-4 w-4" />
            )}
            Refresh
          </Button>
          <Button
            size="sm"
            onClick={() => {
              setForm(EMPTY_FORM);
              setCreateOpen(true);
            }}
          >
            <Plus className="h-4 w-4" />
            Create Alert
          </Button>
        </div>
      </div>

      {isError && (
        <div className="rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3 text-sm text-destructive">
          {(error as Error)?.message || "Failed to load app alerts."}
        </div>
      )}

      <div className="overflow-hidden rounded-xl border border-border/60">
        <Table>
          <TableHeader>
            <TableRow className="border-b border-slate-700/80 bg-slate-800 hover:bg-slate-800">
              <TableHead className="text-slate-100">Title</TableHead>
              <TableHead className="text-slate-100">Media</TableHead>
              <TableHead className="text-slate-100">Status</TableHead>
              <TableHead className="text-slate-100">Created</TableHead>
              <TableHead className="w-36 text-right text-slate-100">
                Actions
              </TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              <TableRow>
                <TableCell colSpan={5} className="py-10 text-center text-muted-foreground">
                  <Loader2 className="mx-auto h-5 w-5 animate-spin" />
                </TableCell>
              </TableRow>
            ) : alerts.length === 0 ? (
              <TableRow>
                <TableCell colSpan={5} className="py-12 text-center">
                  <Megaphone className="mx-auto mb-2 h-8 w-8 text-muted-foreground/60" />
                  <p className="text-sm text-muted-foreground">
                    No app alerts yet. Create one to show a popup on mobile.
                  </p>
                </TableCell>
              </TableRow>
            ) : (
              alerts.map((alert: AppAlertItem) => (
                <TableRow key={alert.id}>
                  <TableCell>
                    <div className="max-w-md">
                      <p className="font-medium text-foreground">{alert.title}</p>
                      <p className="mt-0.5 line-clamp-2 text-xs text-muted-foreground">
                        {alert.content}
                      </p>
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="flex gap-2">
                      {alert.imageUrl ? (
                        <Badge variant="secondary" className="gap-1">
                          <ImageIcon className="h-3 w-3" />
                          Image
                        </Badge>
                      ) : null}
                      {alert.videoUrl ? (
                        <Badge variant="secondary" className="gap-1">
                          <Video className="h-3 w-3" />
                          Video
                        </Badge>
                      ) : null}
                      {!alert.imageUrl && !alert.videoUrl ? (
                        <span className="text-xs text-muted-foreground">—</span>
                      ) : null}
                    </div>
                  </TableCell>
                  <TableCell>
                    <Badge
                      className={cn(
                        alert.isActive
                          ? "bg-emerald-500/15 text-emerald-700 hover:bg-emerald-500/15"
                          : "bg-slate-500/15 text-slate-600 hover:bg-slate-500/15"
                      )}
                    >
                      {alert.isActive ? "Active" : "Inactive"}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-sm text-muted-foreground">
                    {formatDateTime(alert.createdAt)}
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex justify-end gap-1">
                      {alert.ctaUrl ? (
                        <Button variant="ghost" size="icon" asChild>
                          <a
                            href={alert.ctaUrl}
                            target="_blank"
                            rel="noreferrer"
                            aria-label="Open link"
                          >
                            <ExternalLink className="h-4 w-4" />
                          </a>
                        </Button>
                      ) : null}
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() =>
                          toggleMutation.mutate({
                            id: alert.id,
                            isActive: !alert.isActive,
                          })
                        }
                        aria-label={alert.isActive ? "Deactivate" : "Activate"}
                      >
                        {alert.isActive ? (
                          <PowerOff className="h-4 w-4" />
                        ) : (
                          <Power className="h-4 w-4" />
                        )}
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => setDeleteId(alert.id)}
                        aria-label="Delete alert"
                      >
                        <Trash2 className="h-4 w-4 text-destructive" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>

      <Dialog open={createOpen} onOpenChange={setCreateOpen}>
        <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>Create App Alert</DialogTitle>
            <DialogDescription>
              Users see this once after splash. Closing hides it for that alert.
              Creating a new alert shows a new popup.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-2">
            <div className="space-y-2">
              <Label htmlFor="alert-title">Title</Label>
              <Input
                id="alert-title"
                value={form.title}
                onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))}
                placeholder="What's new"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="alert-content">Content</Label>
              <Textarea
                id="alert-content"
                value={form.content}
                onChange={(e) =>
                  setForm((f) => ({ ...f, content: e.target.value }))
                }
                placeholder="Describe the update or announcement…"
                rows={4}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="alert-image">Image URL (optional)</Label>
              <Input
                id="alert-image"
                value={form.imageUrl}
                onChange={(e) =>
                  setForm((f) => ({ ...f, imageUrl: e.target.value }))
                }
                placeholder="https://…"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="alert-video">Video link (optional)</Label>
              <Input
                id="alert-video"
                value={form.videoUrl}
                onChange={(e) =>
                  setForm((f) => ({ ...f, videoUrl: e.target.value }))
                }
                placeholder="https://youtube.com/… or direct video URL"
              />
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="alert-cta-label">Button label (optional)</Label>
                <Input
                  id="alert-cta-label"
                  value={form.ctaLabel}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, ctaLabel: e.target.value }))
                  }
                  placeholder="Learn more"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="alert-cta-url">Button URL (optional)</Label>
                <Input
                  id="alert-cta-url"
                  value={form.ctaUrl}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, ctaUrl: e.target.value }))
                  }
                  placeholder="https://…"
                />
              </div>
            </div>
            <div className="flex items-center justify-between rounded-lg border px-3 py-2">
              <div>
                <p className="text-sm font-medium">Active</p>
                <p className="text-xs text-muted-foreground">
                  Inactive alerts are not shown on mobile.
                </p>
              </div>
              <Switch
                checked={form.isActive !== false}
                onCheckedChange={(checked) =>
                  setForm((f) => ({ ...f, isActive: checked }))
                }
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setCreateOpen(false)}>
              Cancel
            </Button>
            <Button
              disabled={!canSubmit}
              onClick={() => createMutation.mutate()}
            >
              {createMutation.isPending ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : null}
              Publish Alert
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <AlertDialog
        open={deleteId != null}
        onOpenChange={(open) => !open && setDeleteId(null)}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete this alert?</AlertDialogTitle>
            <AlertDialogDescription>
              It will stop showing on mobile. User dismiss history for this alert
              will also be removed.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              onClick={() => deleteId && deleteMutation.mutate(deleteId)}
            >
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
