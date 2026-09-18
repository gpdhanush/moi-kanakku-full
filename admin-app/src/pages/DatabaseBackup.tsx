import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Database,
  Download,
  RefreshCw,
  Loader2,
  Trash2,
  HardDrive,
  FileArchive,
  Clock3,
} from "lucide-react";
import { PageTitle } from "@/components/ui/page-title";
import { StatCard, StatCardSkeleton } from "@/components/ui/stat-card";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
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
import { backupApi, type BackupFile } from "@/features/backup/api";
import { formatDateOnly, formatDateTime } from "@/lib/formatters";
import { cn } from "@/lib/utils";

function formatBytes(bytes: number): string {
  if (!bytes) return "0 B";
  const units = ["B", "KB", "MB", "GB"];
  const index = Math.min(
    units.length - 1,
    Math.floor(Math.log(bytes) / Math.log(1024))
  );
  const value = bytes / 1024 ** index;
  return `${value.toFixed(value >= 10 || index === 0 ? 0 : 1)} ${units[index]}`;
}

function formatTime(value?: string | null): string {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  let hours = date.getHours();
  const minutes = String(date.getMinutes()).padStart(2, "0");
  const ampm = hours >= 12 ? "PM" : "AM";
  hours = hours % 12 || 12;
  return `${String(hours).padStart(2, "0")}:${minutes} ${ampm}`;
}

export default function DatabaseBackup() {
  const queryClient = useQueryClient();
  const [deleteTarget, setDeleteTarget] = useState<BackupFile | null>(null);
  const metaElement = usePageMeta({
    title: "Database Backup",
    description: "Create and download MySQL backups",
  });

  const { data, isLoading, isFetching, isError, error, refetch } = useQuery({
    queryKey: ["admin", "database-backups"],
    queryFn: () => backupApi.list(),
    staleTime: 15_000,
    refetchOnWindowFocus: false,
  });

  const files = data?.files ?? [];
  const latest = files[0];
  const totalSize = files.reduce((sum, file) => sum + (file.size || 0), 0);

  const createMutation = useMutation({
    mutationFn: () => backupApi.createAndDownload(),
    onSuccess: () => {
      toast({
        title: "Backup ready",
        description: "The database backup was created and downloaded.",
      });
      queryClient.invalidateQueries({ queryKey: ["admin", "database-backups"] });
    },
    onError: (err: Error) => {
      toast({
        title: "Backup failed",
        description: err.message || "Unable to create the database backup.",
        variant: "destructive",
      });
    },
  });

  const downloadMutation = useMutation({
    mutationFn: (filename: string) => backupApi.download(filename),
    onSuccess: () => {
      toast({
        title: "Download started",
        description: "The backup file is downloading.",
      });
    },
    onError: (err: Error) => {
      toast({
        title: "Download failed",
        description: err.message || "Unable to download this backup.",
        variant: "destructive",
      });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (filename: string) => backupApi.remove(filename),
    onSuccess: () => {
      toast({ title: "Backup deleted" });
      setDeleteTarget(null);
      queryClient.invalidateQueries({ queryKey: ["admin", "database-backups"] });
    },
    onError: (err: Error) => {
      toast({
        title: "Delete failed",
        description: err.message || "Unable to delete this backup.",
        variant: "destructive",
      });
    },
  });

  const busy =
    createMutation.isPending ||
    downloadMutation.isPending ||
    deleteMutation.isPending;

  return (
    <>
      {metaElement}
      <div className="space-y-6 animate-fade-in">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <PageTitle
            title="Database Backup"
            icon={Database}
            description={
              data?.database
                ? `MySQL dump of ${data.database}`
                : "Create a MySQL dump and download it from the admin panel"
            }
          />
          <div className="flex flex-wrap gap-2 self-start">
            <Button
              variant="outline"
              size="sm"
              className="gap-2"
              onClick={() => refetch()}
              disabled={isFetching || busy}
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
              className="gap-2"
              onClick={() => createMutation.mutate()}
              disabled={busy}
            >
              {createMutation.isPending ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <Download className="h-4 w-4" />
              )}
              {createMutation.isPending ? "Creating backup..." : "Backup & Download"}
            </Button>
          </div>
        </div>

        <div className="grid gap-4 sm:grid-cols-3">
          {isLoading ? (
            Array.from({ length: 3 }).map((_, i) => <StatCardSkeleton key={i} />)
          ) : (
            <>
              <StatCard
                title="Saved backups"
                value={files.length}
                icon={FileArchive}
                color="blue"
              />
              <StatCard
                title="Storage used"
                value={formatBytes(totalSize)}
                icon={HardDrive}
                color="emerald"
              />
              <StatCard
                title="Latest backup"
                value={latest ? formatDateOnly(latest.createdAt) : "None"}
                description={
                  latest ? formatTime(latest.createdAt) : "No backups yet"
                }
                icon={Clock3}
                color="amber"
              />
            </>
          )}
        </div>

        {createMutation.isPending && (
          <div className="rounded-xl border border-primary/20 bg-primary/5 px-4 py-3 text-sm text-primary">
            Creating a compressed SQL backup. This can take a minute on larger
            databases — keep this page open.
          </div>
        )}

        {isError && (
          <div className="rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3 text-sm text-destructive">
            {(error as Error)?.message || "Failed to load backup list."}
          </div>
        )}

        <div className="overflow-x-auto rounded-xl border border-border/60">
          <Table>
            <TableHeader>
              <TableRow className="border-b border-slate-700/80 bg-slate-800 hover:bg-slate-800 dark:bg-slate-900 dark:hover:bg-slate-900">
                <TableHead className="w-16 text-slate-100">S.No</TableHead>
                <TableHead className="text-slate-100">File</TableHead>
                <TableHead className="text-slate-100">Created</TableHead>
                <TableHead className="text-slate-100">Size</TableHead>
                <TableHead className="min-w-[200px] text-center text-slate-100">
                  Action
                </TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {isLoading ? (
                <TableRow>
                  <TableCell
                    colSpan={5}
                    className="h-28 text-center text-muted-foreground"
                  >
                    <div className="inline-flex items-center gap-2">
                      <Loader2 className="h-4 w-4 animate-spin" />
                      Loading backups...
                    </div>
                  </TableCell>
                </TableRow>
              ) : files.length === 0 ? (
                <TableRow>
                  <TableCell
                    colSpan={5}
                    className="h-28 text-center text-muted-foreground"
                  >
                    No backups yet. Use Backup & Download to create the first one.
                  </TableCell>
                </TableRow>
              ) : (
                files.map((file, index) => (
                  <TableRow
                    key={file.filename}
                    className={cn(index % 2 === 1 && "bg-muted/20")}
                  >
                    <TableCell className="font-medium tabular-nums">
                      {index + 1}
                    </TableCell>
                    <TableCell className="max-w-[320px] break-all font-medium">
                      {file.filename}
                    </TableCell>
                    <TableCell className="whitespace-nowrap text-muted-foreground">
                      {formatDateTime(file.createdAt)}
                    </TableCell>
                    <TableCell className="whitespace-nowrap tabular-nums">
                      {formatBytes(file.size)}
                    </TableCell>
                    <TableCell>
                      <div className="flex flex-nowrap justify-center gap-2">
                        <Button
                          variant="outline"
                          size="sm"
                          className="gap-1.5"
                          disabled={busy}
                          onClick={() => downloadMutation.mutate(file.filename)}
                        >
                          {downloadMutation.isPending &&
                          downloadMutation.variables === file.filename ? (
                            <Loader2 className="h-4 w-4 animate-spin" />
                          ) : (
                            <Download className="h-4 w-4" />
                          )}
                          Download
                        </Button>
                        <Button
                          variant="destructive"
                          size="sm"
                          className="gap-1.5"
                          disabled={busy}
                          onClick={() => setDeleteTarget(file)}
                        >
                          <Trash2 className="h-4 w-4" />
                          Delete
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </div>
      </div>

      <AlertDialog
        open={!!deleteTarget}
        onOpenChange={(open) => {
          if (!open) setDeleteTarget(null);
        }}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete this backup?</AlertDialogTitle>
            <AlertDialogDescription>
              <span className="font-medium text-foreground">
                {deleteTarget?.filename}
              </span>{" "}
              will be permanently removed from the server.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleteMutation.isPending}>
              Cancel
            </AlertDialogCancel>
            <AlertDialogAction
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              disabled={deleteMutation.isPending || !deleteTarget}
              onClick={(e) => {
                e.preventDefault();
                if (deleteTarget) deleteMutation.mutate(deleteTarget.filename);
              }}
            >
              {deleteMutation.isPending ? (
                <span className="inline-flex items-center gap-2">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Deleting...
                </span>
              ) : (
                "Delete"
              )}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
