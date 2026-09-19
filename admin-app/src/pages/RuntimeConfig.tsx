import { useEffect, useState } from 'react';
import { useMutation, useQuery } from '@tanstack/react-query';
import { CheckCircle2, Loader2, Settings2 } from 'lucide-react';
import { PageTitle } from '@/components/ui/page-title';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Button } from '@/components/ui/button';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { toast } from '@/hooks/use-toast';
import { usePageMeta } from '@/hooks/usePageMeta';
import { runtimeConfigApi, type RuntimeConfig } from '@/features/runtimeConfig/api';

const emptyConfig: RuntimeConfig = {
  liveURL: '',
  imageUrl: '',
  maintenanceMode: false,
  minAppVersion: '',
};

export default function RuntimeConfigPage() {
  usePageMeta({
    title: 'App Configuration',
    description: 'Manage public mobile runtime configuration',
  });

  const [form, setForm] = useState<RuntimeConfig>(emptyConfig);
  const configQuery = useQuery({
    queryKey: ['runtime-config'],
    queryFn: runtimeConfigApi.get,
    refetchOnWindowFocus: false,
  });

  useEffect(() => {
    if (configQuery.data) setForm(configQuery.data);
  }, [configQuery.data]);

  const saveMutation = useMutation({
    mutationFn: () => runtimeConfigApi.update(form),
    onSuccess: (saved) => {
      setForm(saved);
      toast({
        title: 'Configuration saved',
        description: 'New values will be used by the next mobile startup check.',
      });
      void configQuery.refetch();
    },
    onError: (error: Error) => {
      toast({
        title: 'Unable to save configuration',
        description: error.message,
        variant: 'destructive',
      });
    },
  });

  const update = (key: keyof RuntimeConfig, value: string | boolean) => {
    setForm((current) => ({ ...current, [key]: value }));
  };

  return (
    <div className="space-y-6 animate-fade-in">
      <PageTitle
        title="App Configuration"
        description="Control the public runtime settings used by the mobile app"
        icon={Settings2}
      />

      <Card className="glass-card max-w-3xl border-2">
        <CardHeader>
          <CardTitle>Mobile Runtime</CardTitle>
          <CardDescription>
            The public endpoint exposes only these non-sensitive values. API secrets remain on the server.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-5">
          {configQuery.isError && (
            <Alert variant="destructive">
              <AlertDescription>
                Unable to load configuration. Check that the app_runtime_config table has been installed.
              </AlertDescription>
            </Alert>
          )}

          <div className="space-y-2">
            <Label htmlFor="liveURL">API base URL</Label>
            <Input
              id="liveURL"
              value={form.liveURL}
              onChange={(event) => update('liveURL', event.target.value)}
              placeholder="https://example.com/apis"
              disabled={configQuery.isLoading || saveMutation.isPending}
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="imageUrl">Image base URL</Label>
            <Input
              id="imageUrl"
              value={form.imageUrl}
              onChange={(event) => update('imageUrl', event.target.value)}
              placeholder="https://example.com"
              disabled={configQuery.isLoading || saveMutation.isPending}
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="minAppVersion">Minimum app version</Label>
            <Input
              id="minAppVersion"
              value={form.minAppVersion}
              onChange={(event) => update('minAppVersion', event.target.value)}
              placeholder="5.0.0"
              disabled={configQuery.isLoading || saveMutation.isPending}
            />
          </div>
          <div className="flex items-center justify-between rounded-lg border border-border/60 bg-muted/30 p-4">
            <div>
              <Label htmlFor="maintenanceMode">Maintenance mode</Label>
              <p className="text-sm text-muted-foreground">
                Send mobile users to the maintenance screen.
              </p>
            </div>
            <Switch
              id="maintenanceMode"
              checked={form.maintenanceMode}
              onCheckedChange={(value) => update('maintenanceMode', value)}
              disabled={configQuery.isLoading || saveMutation.isPending}
            />
          </div>

          <div className="flex items-center justify-between gap-4 pt-2">
            <p className="text-xs text-muted-foreground">
              {form.updatedAt ? `Last updated ${new Date(form.updatedAt).toLocaleString()}` : 'Not saved yet'}
            </p>
            <Button onClick={() => saveMutation.mutate()} disabled={configQuery.isLoading || saveMutation.isPending}>
              {saveMutation.isPending ? (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              ) : (
                <CheckCircle2 className="mr-2 h-4 w-4" />
              )}
              Save configuration
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
