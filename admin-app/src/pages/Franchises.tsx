import { useState, useEffect } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Building2,
  Plus,
  Search,
  UserPlus,
  UserMinus,
  RefreshCw,
  Edit2,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  Users,
  Calendar,
  DollarSign,
  ShieldAlert,
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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { toast } from "sonner";
import { franchiseApi, FranchiseBranch, FranchiseAdminUser } from "@/features/franchise/api";
import { getUserRole, getFranchiseContext } from "@/lib/auth";

export default function Franchises() {
  const queryClient = useQueryClient();
  const userRole = getUserRole();
  const franchiseContext = getFranchiseContext();
  const isSuperAdmin = userRole === "SUPER_ADMIN";

  const [search, setSearch] = useState("");
  const [selectedFranchise, setSelectedFranchise] = useState<FranchiseBranch | null>(null);
  
  // Modals
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [assignAdminModalOpen, setAssignAdminModalOpen] = useState(false);
  const [detailsModalOpen, setDetailsModalOpen] = useState(false);

  // Form states
  const [newBranch, setNewBranch] = useState({
    name: "",
    code: "",
    mobile: "",
    email: "",
    address: "",
    city: "",
    state: "",
    pincode: "",
  });
  const [assignAdminId, setAssignAdminId] = useState("");

  // Query Franchises (Super Admin)
  const { data: franchiseData, isLoading, refetch } = useQuery({
    queryKey: ["franchises", search],
    queryFn: () => franchiseApi.listFranchises({ search }),
    enabled: isSuperAdmin,
  });

  // Query Single Franchise Details (Franchise Admin or selected)
  const { data: detailData, isLoading: detailLoading } = useQuery({
    queryKey: ["franchise-detail", selectedFranchise?.id || franchiseContext?.franchise_id],
    queryFn: () => {
      const id = isSuperAdmin ? selectedFranchise?.id : franchiseContext?.franchise_id;
      if (!id) return Promise.resolve(null);
      return franchiseApi.getFranchise(Number(id));
    },
    enabled: (!isSuperAdmin && !!franchiseContext?.franchise_id) || (isSuperAdmin && !!selectedFranchise?.id),
  });

  // Create Franchise Mutation
  const createMutation = useMutation({
    mutationFn: franchiseApi.createFranchise,
    onSuccess: () => {
      toast.success("Franchise branch created successfully");
      setCreateModalOpen(false);
      setNewBranch({ name: "", code: "", mobile: "", email: "", address: "", city: "", state: "", pincode: "" });
      queryClient.invalidateQueries({ queryKey: ["franchises"] });
    },
    onError: (err: any) => {
      toast.error(err?.response?.data?.responseValue?.message || "Failed to create franchise branch");
    },
  });

  // Status Change Mutation
  const statusMutation = useMutation({
    mutationFn: ({ id, status }: { id: number; status: "ACTIVE" | "INACTIVE" | "SUSPENDED" }) =>
      franchiseApi.updateFranchiseStatus(id, status),
    onSuccess: () => {
      toast.success("Franchise status updated");
      queryClient.invalidateQueries({ queryKey: ["franchises"] });
    },
    onError: (err: any) => {
      toast.error(err?.response?.data?.responseValue?.message || "Failed to update status");
    },
  });

  // Assign Admin Mutation
  const assignAdminMutation = useMutation({
    mutationFn: ({ franchiseId, adminId }: { franchiseId: number; adminId: number }) =>
      franchiseApi.assignFranchiseAdmin(franchiseId, adminId),
    onSuccess: () => {
      toast.success("Franchise Admin assigned successfully");
      setAssignAdminModalOpen(false);
      setAssignAdminId("");
      queryClient.invalidateQueries({ queryKey: ["franchise-detail"] });
      queryClient.invalidateQueries({ queryKey: ["franchises"] });
    },
    onError: (err: any) => {
      toast.error(err?.response?.data?.responseValue?.message || "Failed to assign admin");
    },
  });

  // Remove Admin Mutation
  const removeAdminMutation = useMutation({
    mutationFn: ({ franchiseId, adminId }: { franchiseId: number; adminId: number }) =>
      franchiseApi.removeFranchiseAdmin(franchiseId, adminId),
    onSuccess: () => {
      toast.success("Franchise Admin removed");
      queryClient.invalidateQueries({ queryKey: ["franchise-detail"] });
    },
    onError: (err: any) => {
      toast.error(err?.response?.data?.responseValue?.message || "Failed to remove admin");
    },
  });

  const handleCreateSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newBranch.name || !newBranch.code) {
      toast.error("Franchise Name and Code are required");
      return;
    }
    createMutation.mutate(newBranch);
  };

  const handleAssignAdminSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedFranchise || !assignAdminId) return;
    assignAdminMutation.mutate({
      franchiseId: selectedFranchise.id,
      adminId: Number(assignAdminId),
    });
  };

  // Status Badge styling helper
  const getStatusBadge = (status: string) => {
    switch (status) {
      case "ACTIVE":
        return <Badge className="bg-emerald-500/10 text-emerald-600 border-emerald-200">Active</Badge>;
      case "INACTIVE":
        return <Badge variant="secondary">Inactive</Badge>;
      case "SUSPENDED":
        return <Badge className="bg-rose-500/10 text-rose-600 border-rose-200">Suspended</Badge>;
      default:
        return <Badge variant="outline">{status}</Badge>;
    }
  };

  return (
    <div className="space-y-6 p-6">
      {/* Header Banner */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
            <Building2 className="h-7 w-7 text-primary" />
            {isSuperAdmin ? "Franchise Branches Management" : `Branch Overview — ${franchiseContext?.franchise_name || "Franchise"}`}
          </h1>
          <p className="text-sm text-muted-foreground">
            {isSuperAdmin
              ? "Manage multi-branch franchise locations, assign branch administrators, and monitor performance."
              : `Branch Code: ${franchiseContext?.franchise_code || "N/A"} — Manage your franchise branch operations and team.`}
          </p>
        </div>
        <div className="flex items-center gap-2">
          {isSuperAdmin && (
            <Button onClick={() => setCreateModalOpen(true)} className="gap-2">
              <Plus className="h-4 w-4" /> Create Branch
            </Button>
          )}
          <Button variant="outline" size="icon" onClick={() => refetch()}>
            <RefreshCw className="h-4 w-4" />
          </Button>
        </div>
      </div>

      {/* Franchise Admin Overview Cards */}
      {!isSuperAdmin && (
        <div className="grid gap-4 md:grid-cols-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium">Branch Customers</CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{detailData?.summary?.total_customers || 0}</div>
              <p className="text-xs text-muted-foreground">Active registered customers</p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium">Branch Staff</CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{detailData?.summary?.total_staff || 0}</div>
              <p className="text-xs text-muted-foreground">Assigned staff accounts</p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium">Total Events / Functions</CardTitle>
              <Calendar className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{detailData?.summary?.total_functions || 0}</div>
              <p className="text-xs text-muted-foreground">Managed functions</p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium">Collection Total</CardTitle>
              <DollarSign className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                ₹{Number(detailData?.summary?.total_amount || 0).toLocaleString("en-IN")}
              </div>
              <p className="text-xs text-muted-foreground">Recorded transaction gifts</p>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Super Admin Franchises Table */}
      {isSuperAdmin && (
        <Card>
          <CardHeader>
            <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
              <div>
                <CardTitle>All Franchise Branches ({franchiseData?.total || 0})</CardTitle>
                <CardDescription>Directory of all registered franchise branches.</CardDescription>
              </div>
              <div className="relative w-full md:w-64">
                <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Search branch name or code..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="pl-8"
                />
              </div>
            </div>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="py-8 text-center text-sm text-muted-foreground">Loading franchise branches...</div>
            ) : franchiseData?.franchises?.length === 0 ? (
              <div className="py-8 text-center text-sm text-muted-foreground">No franchise branches found.</div>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Code</TableHead>
                    <TableHead>Branch Name</TableHead>
                    <TableHead>City / Location</TableHead>
                    <TableHead>Contact</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {franchiseData?.franchises?.map((branch) => (
                    <TableRow key={branch.id}>
                      <TableCell className="font-mono text-xs font-bold text-primary">
                        {branch.code}
                      </TableCell>
                      <TableCell className="font-semibold">{branch.name}</TableCell>
                      <TableCell>{branch.city ? `${branch.city}, ${branch.state || ''}` : "—"}</TableCell>
                      <TableCell className="text-xs">
                        {branch.mobile && <div>📱 {branch.mobile}</div>}
                        {branch.email && <div>✉️ {branch.email}</div>}
                      </TableCell>
                      <TableCell>{getStatusBadge(branch.status)}</TableCell>
                      <TableCell className="text-right space-x-2">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => {
                            setSelectedFranchise(branch);
                            setDetailsModalOpen(true);
                          }}
                        >
                          View Details
                        </Button>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => {
                            setSelectedFranchise(branch);
                            setAssignAdminModalOpen(true);
                          }}
                        >
                          <UserPlus className="h-3.5 w-3.5 mr-1" /> Admin
                        </Button>
                        <Select
                          value={branch.status}
                          onValueChange={(val: any) =>
                            statusMutation.mutate({ id: branch.id, status: val })
                          }
                        >
                          <SelectTrigger className="w-28 h-8 text-xs inline-flex">
                            <SelectValue placeholder="Status" />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="ACTIVE">Active</SelectItem>
                            <SelectItem value="INACTIVE">Inactive</SelectItem>
                            <SelectItem value="SUSPENDED">Suspended</SelectItem>
                          </SelectContent>
                        </Select>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>
      )}

      {/* Modal: Create Branch */}
      <Dialog open={createModalOpen} onOpenChange={setCreateModalOpen}>
        <DialogContent className="sm:max-w-[500px]">
          <DialogHeader>
            <DialogTitle>Create New Franchise Branch</DialogTitle>
            <DialogDescription>
              Register a new franchise branch. Code must be unique (e.g. MOI-CHE-01).
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleCreateSubmit} className="space-y-4 py-2">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="branchName">Branch Name *</Label>
                <Input
                  id="branchName"
                  placeholder="e.g. Chennai Central"
                  value={newBranch.name}
                  onChange={(e) => setNewBranch({ ...newBranch, name: e.target.value })}
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="branchCode">Branch Code *</Label>
                <Input
                  id="branchCode"
                  placeholder="e.g. MOI-CHE-01"
                  value={newBranch.code}
                  onChange={(e) => setNewBranch({ ...newBranch, code: e.target.value.toUpperCase() })}
                  required
                />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="branchMobile">Contact Mobile</Label>
                <Input
                  id="branchMobile"
                  placeholder="10-digit mobile"
                  value={newBranch.mobile}
                  onChange={(e) => setNewBranch({ ...newBranch, mobile: e.target.value })}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="branchEmail">Contact Email</Label>
                <Input
                  id="branchEmail"
                  type="email"
                  placeholder="branch@example.com"
                  value={newBranch.email}
                  onChange={(e) => setNewBranch({ ...newBranch, email: e.target.value })}
                />
              </div>
            </div>
            <div className="space-y-2">
              <Label htmlFor="branchAddress">Address</Label>
              <Input
                id="branchAddress"
                placeholder="Street address"
                value={newBranch.address}
                onChange={(e) => setNewBranch({ ...newBranch, address: e.target.value })}
              />
            </div>
            <div className="grid grid-cols-3 gap-3">
              <div className="space-y-2">
                <Label htmlFor="branchCity">City</Label>
                <Input
                  id="branchCity"
                  value={newBranch.city}
                  onChange={(e) => setNewBranch({ ...newBranch, city: e.target.value })}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="branchState">State</Label>
                <Input
                  id="branchState"
                  value={newBranch.state}
                  onChange={(e) => setNewBranch({ ...newBranch, state: e.target.value })}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="branchPincode">Pincode</Label>
                <Input
                  id="branchPincode"
                  value={newBranch.pincode}
                  onChange={(e) => setNewBranch({ ...newBranch, pincode: e.target.value })}
                />
              </div>
            </div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setCreateModalOpen(false)}>
                Cancel
              </Button>
              <Button type="submit" disabled={createMutation.isPending}>
                {createMutation.isPending ? "Creating..." : "Create Branch"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Modal: Assign Admin */}
      <Dialog open={assignAdminModalOpen} onOpenChange={setAssignAdminModalOpen}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Assign Franchise Admin</DialogTitle>
            <DialogDescription>
              Assign an existing system admin ID to manage branch: <strong>{selectedFranchise?.name}</strong>.
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleAssignAdminSubmit} className="space-y-4 py-2">
            <div className="space-y-2">
              <Label htmlFor="adminId">System Admin ID</Label>
              <Input
                id="adminId"
                type="number"
                placeholder="Enter numeric Admin ID (e.g. 2)"
                value={assignAdminId}
                onChange={(e) => setAssignAdminId(e.target.value)}
                required
              />
            </div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setAssignAdminModalOpen(false)}>
                Cancel
              </Button>
              <Button type="submit" disabled={assignAdminMutation.isPending}>
                {assignAdminMutation.isPending ? "Assigning..." : "Assign Admin"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Modal: View Details */}
      <Dialog open={detailsModalOpen} onOpenChange={setDetailsModalOpen}>
        <DialogContent className="sm:max-w-[600px]">
          <DialogHeader>
            <DialogTitle>Branch Details — {selectedFranchise?.name}</DialogTitle>
            <DialogDescription>
              Branch Code: <span className="font-mono font-bold text-primary">{selectedFranchise?.code}</span>
            </DialogDescription>
          </DialogHeader>
          {detailLoading ? (
            <div className="py-6 text-center text-sm text-muted-foreground">Loading details...</div>
          ) : (
            <div className="space-y-4 py-2">
              <div className="grid grid-cols-2 gap-4 rounded-lg bg-muted/50 p-3 text-sm">
                <div>
                  <span className="text-xs text-muted-foreground">Contact Mobile:</span>
                  <p className="font-medium">{detailData?.franchise?.mobile || "—"}</p>
                </div>
                <div>
                  <span className="text-xs text-muted-foreground">Contact Email:</span>
                  <p className="font-medium">{detailData?.franchise?.email || "—"}</p>
                </div>
                <div>
                  <span className="text-xs text-muted-foreground">Location:</span>
                  <p className="font-medium">
                    {detailData?.franchise?.city
                      ? `${detailData.franchise.city}, ${detailData.franchise.state || ""} ${detailData.franchise.pincode || ""}`
                      : "—"}
                  </p>
                </div>
                <div>
                  <span className="text-xs text-muted-foreground">Current Status:</span>
                  <div>{getStatusBadge(detailData?.franchise?.status || "")}</div>
                </div>
              </div>

              <div>
                <h4 className="text-sm font-semibold mb-2 flex items-center justify-between">
                  <span>Assigned Franchise Administrators ({detailData?.admins?.length || 0})</span>
                </h4>
                {detailData?.admins?.length === 0 ? (
                  <p className="text-xs text-muted-foreground italic">No admins currently assigned to this branch.</p>
                ) : (
                  <div className="space-y-2">
                    {detailData?.admins?.map((admin: FranchiseAdminUser) => (
                      <div
                        key={admin.id}
                        className="flex items-center justify-between rounded-md border p-2.5 text-xs"
                      >
                        <div>
                          <p className="font-semibold text-foreground">{admin.full_name || `Admin #${admin.admin_id}`}</p>
                          <p className="text-muted-foreground">{admin.email} {admin.mobile ? `• ${admin.mobile}` : ''}</p>
                        </div>
                        {isSuperAdmin && (
                          <Button
                            variant="ghost"
                            size="sm"
                            className="h-7 text-rose-600 hover:text-rose-700"
                            onClick={() =>
                              removeAdminMutation.mutate({
                                franchiseId: Number(detailData.franchise.id),
                                adminId: admin.admin_id,
                              })
                            }
                          >
                            <UserMinus className="h-3.5 w-3.5 mr-1" /> Revoke
                          </Button>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
