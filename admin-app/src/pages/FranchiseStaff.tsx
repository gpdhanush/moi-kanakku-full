import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  UserCog,
  UserPlus,
  ShieldCheck,
  RefreshCw,
  Phone,
  Mail,
  Key,
  CheckCircle2,
  Lock,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
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
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { toast } from "sonner";
import { franchiseApi, FranchiseStaff as StaffType, FranchiseFunction } from "@/features/franchise/api";

export default function FranchiseStaff() {
  const queryClient = useQueryClient();
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [permModalOpen, setPermModalOpen] = useState(false);
  const [selectedStaff, setSelectedStaff] = useState<StaffType | null>(null);

  // New staff form
  const [newStaff, setNewStaff] = useState({
    full_name: "",
    mobile: "",
    email: "",
    password: "",
  });

  // Function Permission Editor State
  const [selectedFunctionId, setSelectedFunctionId] = useState<string>("");
  const [permissions, setPermissions] = useState({
    canView: true,
    canAddCustomer: true,
    canAddTransaction: true,
    canEditTransaction: false,
    canDeleteTransaction: false,
    canViewReport: true,
  });

  // Query Staff List
  const { data: staffData, isLoading, refetch } = useQuery({
    queryKey: ["franchise-staff"],
    queryFn: franchiseApi.listStaff,
  });

  // Query Functions List for Permission Assignment
  const { data: functionData } = useQuery({
    queryKey: ["franchise-functions"],
    queryFn: franchiseApi.listFunctions,
  });

  // Create Staff Mutation
  const createMutation = useMutation({
    mutationFn: franchiseApi.createStaffAccount,
    onSuccess: () => {
      toast.success("New staff account created successfully");
      setCreateModalOpen(false);
      setNewStaff({ full_name: "", mobile: "", email: "", password: "" });
      queryClient.invalidateQueries({ queryKey: ["franchise-staff"] });
    },
    onError: (err: any) => {
      toast.error(err?.response?.data?.responseValue?.message || "Failed to create staff account");
    },
  });

  // Toggle Staff Status
  const statusMutation = useMutation({
    mutationFn: ({ userId, status }: { userId: number; status: "ACTIVE" | "INACTIVE" }) =>
      franchiseApi.updateStaffStatus(userId, status),
    onSuccess: () => {
      toast.success("Staff status updated");
      queryClient.invalidateQueries({ queryKey: ["franchise-staff"] });
    },
    onError: (err: any) => {
      toast.error(err?.response?.data?.responseValue?.message || "Failed to update status");
    },
  });

  // Set Function Permissions Mutation
  const setPermMutation = useMutation({
    mutationFn: franchiseApi.setStaffPermissions,
    onSuccess: () => {
      toast.success("Staff function permissions saved");
      setPermModalOpen(false);
      queryClient.invalidateQueries({ queryKey: ["franchise-staff"] });
    },
    onError: (err: any) => {
      toast.error(err?.response?.data?.responseValue?.message || "Failed to set permissions");
    },
  });

  // Revoke Function Permissions Mutation
  const revokePermMutation = useMutation({
    mutationFn: ({ staffUserId, functionId }: { staffUserId: number; functionId: number }) =>
      franchiseApi.revokeStaffPermissions(staffUserId, functionId),
    onSuccess: () => {
      toast.success("Access revoked for this function");
      queryClient.invalidateQueries({ queryKey: ["franchise-staff"] });
    },
    onError: (err: any) => {
      toast.error(err?.response?.data?.responseValue?.message || "Failed to revoke access");
    },
  });

  const handleSavePermissions = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedStaff || !selectedFunctionId) {
      toast.error("Please select a target function");
      return;
    }
    setPermMutation.mutate({
      staffUserId: selectedStaff.user_id,
      functionId: Number(selectedFunctionId),
      ...permissions,
    });
  };

  return (
    <div className="space-y-6 p-6">
      {/* Header */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
            <UserCog className="h-7 w-7 text-primary" />
            Branch Staff & Access Permissions
          </h1>
          <p className="text-sm text-muted-foreground">
            Manage branch staff accounts and configure function-level access permissions.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button onClick={() => setCreateModalOpen(true)} className="gap-2">
            <UserPlus className="h-4 w-4" /> Create Staff Account
          </Button>
          <Button variant="outline" size="icon" onClick={() => refetch()}>
            <RefreshCw className="h-4 w-4" />
          </Button>
        </div>
      </div>

      {/* Staff Directory Card */}
      <Card>
        <CardHeader>
          <CardTitle>Branch Staff Members ({staffData?.staff?.length || 0})</CardTitle>
          <CardDescription>
            Staff members handle live function/event counters and record customer transactions.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="py-8 text-center text-sm text-muted-foreground">Loading branch staff...</div>
          ) : staffData?.staff?.length === 0 ? (
            <div className="py-8 text-center text-sm text-muted-foreground">No staff accounts registered for this branch.</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Staff Name</TableHead>
                  <TableHead>Contact Info</TableHead>
                  <TableHead>Assigned Function Permissions</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {staffData?.staff?.map((s) => (
                  <TableRow key={s.id}>
                    <TableCell className="font-semibold">{s.full_name || `User #${s.user_id}`}</TableCell>
                    <TableCell className="text-xs">
                      {s.mobile && <div className="flex items-center gap-1"><Phone className="h-3 w-3 text-muted-foreground" /> {s.mobile}</div>}
                      {s.email && <div className="flex items-center gap-1 text-muted-foreground"><Mail className="h-3 w-3" /> {s.email}</div>}
                    </TableCell>
                    <TableCell>
                      {s.permissions && s.permissions.length > 0 ? (
                        <div className="flex flex-wrap gap-1">
                          {s.permissions.map((p) => (
                            <Badge key={p.function_id} variant="outline" className="text-[10px]">
                              {p.function_name || `Func #${p.function_id}`}
                            </Badge>
                          ))}
                        </div>
                      ) : (
                        <span className="text-xs text-muted-foreground italic">No functions assigned</span>
                      )}
                    </TableCell>
                    <TableCell>
                      {s.status === "ACTIVE" ? (
                        <Badge className="bg-emerald-500/10 text-emerald-600 border-emerald-200">Active</Badge>
                      ) : (
                        <Badge variant="secondary">Inactive</Badge>
                      )}
                    </TableCell>
                    <TableCell className="text-right space-x-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => {
                          setSelectedStaff(s);
                          setPermModalOpen(true);
                        }}
                      >
                        <ShieldCheck className="h-3.5 w-3.5 mr-1 text-primary" /> Permissions
                      </Button>
                      <Button
                        variant={s.status === "ACTIVE" ? "outline" : "default"}
                        size="sm"
                        onClick={() =>
                          statusMutation.mutate({
                            userId: s.user_id,
                            status: s.status === "ACTIVE" ? "INACTIVE" : "ACTIVE",
                          })
                        }
                      >
                        {s.status === "ACTIVE" ? "Deactivate" : "Activate"}
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Modal: Create Staff Account */}
      <Dialog open={createModalOpen} onOpenChange={setCreateModalOpen}>
        <DialogContent className="sm:max-w-[450px]">
          <DialogHeader>
            <DialogTitle>Create Staff Account</DialogTitle>
            <DialogDescription>
              Create a new staff login account for branch operations.
            </DialogDescription>
          </DialogHeader>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              if (!newStaff.full_name || !newStaff.mobile) {
                toast.error("Staff name and mobile are required");
                return;
              }
              createMutation.mutate(newStaff);
            }}
            className="space-y-4 py-2"
          >
            <div className="space-y-2">
              <Label htmlFor="staffName">Staff Full Name *</Label>
              <Input
                id="staffName"
                placeholder="e.g. Suresh Kumar"
                value={newStaff.full_name}
                onChange={(e) => setNewStaff({ ...newStaff, full_name: e.target.value })}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="staffMobile">Mobile Number *</Label>
              <Input
                id="staffMobile"
                placeholder="10-digit mobile number"
                value={newStaff.mobile}
                onChange={(e) => setNewStaff({ ...newStaff, mobile: e.target.value })}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="staffEmail">Email Address (Optional)</Label>
              <Input
                id="staffEmail"
                type="email"
                placeholder="staff@example.com"
                value={newStaff.email}
                onChange={(e) => setNewStaff({ ...newStaff, email: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="staffPass">Password (Optional)</Label>
              <Input
                id="staffPass"
                type="password"
                placeholder="Leave blank for auto-generated"
                value={newStaff.password}
                onChange={(e) => setNewStaff({ ...newStaff, password: e.target.value })}
              />
            </div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setCreateModalOpen(false)}>
                Cancel
              </Button>
              <Button type="submit" disabled={createMutation.isPending}>
                {createMutation.isPending ? "Creating..." : "Create Account"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Modal: Manage Function Permissions */}
      <Dialog open={permModalOpen} onOpenChange={setPermModalOpen}>
        <DialogContent className="sm:max-w-[500px]">
          <DialogHeader>
            <DialogTitle>Configure Function Access Permissions</DialogTitle>
            <DialogDescription>
              Assign or update function-level operational permissions for: <strong>{selectedStaff?.full_name}</strong>
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleSavePermissions} className="space-y-4 py-2">
            <div className="space-y-2">
              <Label>Select Target Function / Event</Label>
              <Select value={selectedFunctionId} onValueChange={setSelectedFunctionId}>
                <SelectTrigger>
                  <SelectValue placeholder="Choose function..." />
                </SelectTrigger>
                <SelectContent>
                  {functionData?.functions?.map((f: FranchiseFunction) => (
                    <SelectItem key={f.id} value={String(f.id)}>
                      {f.name} ({f.function_date ? new Date(f.function_date).toLocaleDateString() : 'N/A'})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-3 rounded-md border p-3 bg-muted/30">
              <h4 className="text-xs font-semibold uppercase text-muted-foreground tracking-wider mb-2">
                Function Operational Rights
              </h4>
              <div className="flex items-center justify-between">
                <Label htmlFor="canView" className="text-xs cursor-pointer">Can View Function Details</Label>
                <Switch
                  id="canView"
                  checked={permissions.canView}
                  onCheckedChange={(v) => setPermissions({ ...permissions, canView: v })}
                />
              </div>
              <div className="flex items-center justify-between">
                <Label htmlFor="canAddCustomer" className="text-xs cursor-pointer">Can Add/Register Persons</Label>
                <Switch
                  id="canAddCustomer"
                  checked={permissions.canAddCustomer}
                  onCheckedChange={(v) => setPermissions({ ...permissions, canAddCustomer: v })}
                />
              </div>
              <div className="flex items-center justify-between">
                <Label htmlFor="canAddTx" className="text-xs cursor-pointer">Can Add Gift Transactions</Label>
                <Switch
                  id="canAddTx"
                  checked={permissions.canAddTransaction}
                  onCheckedChange={(v) => setPermissions({ ...permissions, canAddTransaction: v })}
                />
              </div>
              <div className="flex items-center justify-between">
                <Label htmlFor="canEditTx" className="text-xs cursor-pointer">Can Edit Transactions</Label>
                <Switch
                  id="canEditTx"
                  checked={permissions.canEditTransaction}
                  onCheckedChange={(v) => setPermissions({ ...permissions, canEditTransaction: v })}
                />
              </div>
              <div className="flex items-center justify-between">
                <Label htmlFor="canDeleteTx" className="text-xs cursor-pointer">Can Delete Transactions</Label>
                <Switch
                  id="canDeleteTx"
                  checked={permissions.canDeleteTransaction}
                  onCheckedChange={(v) => setPermissions({ ...permissions, canDeleteTransaction: v })}
                />
              </div>
              <div className="flex items-center justify-between">
                <Label htmlFor="canViewRep" className="text-xs cursor-pointer">Can View Reports</Label>
                <Switch
                  id="canViewRep"
                  checked={permissions.canViewReport}
                  onCheckedChange={(v) => setPermissions({ ...permissions, canViewReport: v })}
                />
              </div>
            </div>

            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setPermModalOpen(false)}>
                Cancel
              </Button>
              <Button type="submit" disabled={setPermMutation.isPending}>
                {setPermMutation.isPending ? "Saving..." : "Save Permissions"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
