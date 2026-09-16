import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  FileText,
  Activity,
  Calendar,
  DollarSign,
  RefreshCw,
  Search,
  Users,
  ShieldAlert,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { franchiseApi } from "@/features/franchise/api";

export default function FranchiseReports() {
  const [activeTab, setActiveTab] = useState("reports");

  // Query Reports
  const { data: reportsData, isLoading: reportsLoading, refetch: refetchReports } = useQuery({
    queryKey: ["franchise-reports"],
    queryFn: () => franchiseApi.getReports(),
  });

  // Query Audit Logs
  const { data: auditData, isLoading: auditLoading, refetch: refetchAudit } = useQuery({
    queryKey: ["franchise-audit-logs"],
    queryFn: () => franchiseApi.getAuditLogs({ limit: 50 }),
  });

  return (
    <div className="space-y-6 p-6">
      {/* Header */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
            <FileText className="h-7 w-7 text-primary" />
            Branch Financial Reports & Audit Trail
          </h1>
          <p className="text-sm text-muted-foreground">
            Analyze collection statistics and inspect detailed security audit logs for this branch.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="icon"
            onClick={() => {
              refetchReports();
              refetchAudit();
            }}
          >
            <RefreshCw className="h-4 w-4" />
          </Button>
        </div>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-4">
        <TabsList>
          <TabsTrigger value="reports" className="gap-2">
            <FileText className="h-4 w-4" /> Financial Reports
          </TabsTrigger>
          <TabsTrigger value="audit" className="gap-2">
            <Activity className="h-4 w-4" /> Security Audit Logs
          </TabsTrigger>
        </TabsList>

        {/* Tab 1: Financial Reports */}
        <TabsContent value="reports" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-3">
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium">Total Functions Managed</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{reportsData?.summary?.total_functions || 0}</div>
              </CardContent>
            </Card>
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium">Total Persons / Guests</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{reportsData?.summary?.total_persons || 0}</div>
              </CardContent>
            </Card>
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium">Total Collections</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold text-emerald-600">
                  ₹{Number(reportsData?.summary?.total_amount || 0).toLocaleString("en-IN")}
                </div>
              </CardContent>
            </Card>
          </div>

          <Card>
            <CardHeader>
              <CardTitle>Function Collection Breakdown</CardTitle>
              <CardDescription>Consolidated gift collection reports across branch events.</CardDescription>
            </CardHeader>
            <CardContent>
              {reportsLoading ? (
                <div className="py-8 text-center text-sm text-muted-foreground">Loading reports data...</div>
              ) : !reportsData?.functions || reportsData.functions.length === 0 ? (
                <div className="py-8 text-center text-sm text-muted-foreground">No financial records found for this branch.</div>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Function Name</TableHead>
                      <TableHead>Date</TableHead>
                      <TableHead>Total Guests</TableHead>
                      <TableHead className="text-right">Total Gift Collection</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {reportsData.functions.map((f: any) => (
                      <TableRow key={f.id}>
                        <TableCell className="font-semibold">{f.name}</TableCell>
                        <TableCell className="text-xs">
                          {f.function_date ? new Date(f.function_date).toLocaleDateString("en-IN") : "—"}
                        </TableCell>
                        <TableCell>{f.total_persons || 0}</TableCell>
                        <TableCell className="text-right font-bold text-emerald-600">
                          ₹{Number(f.total_amount || 0).toLocaleString("en-IN")}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* Tab 2: Security Audit Logs */}
        <TabsContent value="audit">
          <Card>
            <CardHeader>
              <CardTitle>Security & Operations Audit Trail</CardTitle>
              <CardDescription>Log of all admin and staff operations performed in this branch.</CardDescription>
            </CardHeader>
            <CardContent>
              {auditLoading ? (
                <div className="py-8 text-center text-sm text-muted-foreground">Loading audit logs...</div>
              ) : !auditData?.logs || auditData.logs.length === 0 ? (
                <div className="py-8 text-center text-sm text-muted-foreground">No audit log entries recorded yet.</div>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Timestamp</TableHead>
                      <TableHead>Actor Type</TableHead>
                      <TableHead>Action</TableHead>
                      <TableHead>Details</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {auditData.logs.map((log) => (
                      <TableRow key={log.id}>
                        <TableCell className="text-xs font-mono">
                          {new Date(log.created_at).toLocaleString("en-IN")}
                        </TableCell>
                        <TableCell>
                          <Badge variant="outline" className="text-[10px]">
                            {log.actor_type} #{log.actor_id}
                          </Badge>
                        </TableCell>
                        <TableCell className="font-semibold text-xs">{log.action}</TableCell>
                        <TableCell className="text-xs font-mono text-muted-foreground max-w-md truncate">
                          {typeof log.details === "object" ? JSON.stringify(log.details) : String(log.details || "—")}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
