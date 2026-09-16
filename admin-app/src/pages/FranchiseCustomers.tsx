import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  UserCheck,
  UserPlus,
  Search,
  RefreshCw,
  Link as LinkIcon,
  CheckCircle2,
  XCircle,
  Phone,
  Mail,
  Building,
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
import { toast } from "sonner";
import { franchiseApi, FranchiseCustomer } from "@/features/franchise/api";

export default function FranchiseCustomers() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState("");
  const [linkModalOpen, setLinkModalOpen] = useState(false);
  const [createModalOpen, setCreateModalOpen] = useState(false);

  // Search user for linking state
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedUserToLink, setSelectedUserToLink] = useState<any | null>(null);

  // Create new customer form
  const [newCustomer, setNewCustomer] = useState({
    full_name: "",
    mobile: "",
    email: "",
    password: "",
  });

  // Query Customers List
  const { data, isLoading, refetch } = useQuery({
    queryKey: ["franchise-customers", search],
    queryFn: () => franchiseApi.listCustomers({ search }),
  });

  // Search User Query for linking
  const { data: searchResults, isLoading: searchLoading } = useQuery({
    queryKey: ["search-users-link", searchQuery],
    queryFn: () => franchiseApi.searchUsersForLinking(searchQuery),
    enabled: searchQuery.trim().length >= 3,
  });

  // Link Customer Mutation
  const linkMutation = useMutation({
    mutationFn: (userId: number) => franchiseApi.linkCustomer(userId),
    onSuccess: () => {
      toast.success("Existing user linked as customer successfully");
      setLinkModalOpen(false);
      setSelectedUserToLink(null);
      setSearchQuery("");
      queryClient.invalidateQueries({ queryKey: ["franchise-customers"] });
    },
    onError: (err: any) => {
      toast.error(err?.response?.data?.responseValue?.message || "Failed to link customer");
    },
  });

  // Create Customer Account Mutation
  const createMutation = useMutation({
    mutationFn: franchiseApi.createCustomerAccount,
    onSuccess: () => {
      toast.success("New customer account created and linked successfully");
      setCreateModalOpen(false);
      setNewCustomer({ full_name: "", mobile: "", email: "", password: "" });
      queryClient.invalidateQueries({ queryKey: ["franchise-customers"] });
    },
    onError: (err: any) => {
      toast.error(err?.response?.data?.responseValue?.message || "Failed to create customer account");
    },
  });

  // Toggle Customer Status
  const statusMutation = useMutation({
    mutationFn: ({ userId, status }: { userId: number; status: "ACTIVE" | "INACTIVE" }) =>
      franchiseApi.updateCustomerStatus(userId, status),
    onSuccess: () => {
      toast.success("Customer status updated");
      queryClient.invalidateQueries({ queryKey: ["franchise-customers"] });
    },
    onError: (err: any) => {
      toast.error(err?.response?.data?.responseValue?.message || "Failed to update status");
    },
  });

  return (
    <div className="space-y-6 p-6">
      {/* Header Banner */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
            <UserCheck className="h-7 w-7 text-primary" />
            Branch Customers Directory
          </h1>
          <p className="text-sm text-muted-foreground">
            Manage customer accounts registered or linked with this franchise branch.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" onClick={() => setLinkModalOpen(true)} className="gap-2">
            <LinkIcon className="h-4 w-4" /> Link Existing User
          </Button>
          <Button onClick={() => setCreateModalOpen(true)} className="gap-2">
            <UserPlus className="h-4 w-4" /> Create New Customer
          </Button>
          <Button variant="outline" size="icon" onClick={() => refetch()}>
            <RefreshCw className="h-4 w-4" />
          </Button>
        </div>
      </div>

      {/* Main Customers Table Card */}
      <Card>
        <CardHeader>
          <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div>
              <CardTitle>Customers ({data?.total || 0})</CardTitle>
              <CardDescription>Accounts assigned to host events and record transactions.</CardDescription>
            </div>
            <div className="relative w-full md:w-64">
              <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search name, mobile or code..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="pl-8"
              />
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="py-8 text-center text-sm text-muted-foreground">Loading branch customers...</div>
          ) : data?.customers?.length === 0 ? (
            <div className="py-8 text-center text-sm text-muted-foreground">No customers found for this branch.</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Customer Code</TableHead>
                  <TableHead>Name</TableHead>
                  <TableHead>Contact Info</TableHead>
                  <TableHead>City</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {data?.customers?.map((cust) => (
                  <TableRow key={cust.id}>
                    <TableCell className="font-mono text-xs font-bold text-primary">
                      {cust.customer_code}
                    </TableCell>
                    <TableCell className="font-semibold">{cust.full_name || "—"}</TableCell>
                    <TableCell className="text-xs">
                      {cust.mobile && <div className="flex items-center gap-1"><Phone className="h-3 w-3 text-muted-foreground" /> {cust.mobile}</div>}
                      {cust.email && <div className="flex items-center gap-1 text-muted-foreground"><Mail className="h-3 w-3" /> {cust.email}</div>}
                    </TableCell>
                    <TableCell className="text-xs">{cust.city || "—"}</TableCell>
                    <TableCell>
                      {cust.status === "ACTIVE" ? (
                        <Badge className="bg-emerald-500/10 text-emerald-600 border-emerald-200">Active</Badge>
                      ) : (
                        <Badge variant="secondary">Inactive</Badge>
                      )}
                    </TableCell>
                    <TableCell className="text-right">
                      <Button
                        variant={cust.status === "ACTIVE" ? "outline" : "default"}
                        size="sm"
                        onClick={() =>
                          statusMutation.mutate({
                            userId: cust.user_id,
                            status: cust.status === "ACTIVE" ? "INACTIVE" : "ACTIVE",
                          })
                        }
                      >
                        {cust.status === "ACTIVE" ? "Deactivate" : "Activate"}
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Modal: Link Existing User */}
      <Dialog open={linkModalOpen} onOpenChange={setLinkModalOpen}>
        <DialogContent className="sm:max-w-[480px]">
          <DialogHeader>
            <DialogTitle>Link Existing App User</DialogTitle>
            <DialogDescription>
              Search by mobile number or email to link an existing Moi Kanakku user as a branch customer.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-2">
            <div className="space-y-2">
              <Label>Search User</Label>
              <Input
                placeholder="Enter at least 3 characters (mobile/email)..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
            {searchLoading ? (
              <div className="py-4 text-center text-xs text-muted-foreground">Searching users...</div>
            ) : searchResults?.users && searchResults.users.length > 0 ? (
              <div className="max-h-52 overflow-y-auto space-y-2 border rounded-md p-2">
                {searchResults.users.map((u: any) => (
                  <div
                    key={u.id}
                    className={`flex items-center justify-between p-2.5 rounded text-xs cursor-pointer border transition-colors ${
                      selectedUserToLink?.id === u.id
                        ? "bg-primary/10 border-primary font-medium"
                        : "hover:bg-muted/50 border-transparent"
                    }`}
                    onClick={() => setSelectedUserToLink(u)}
                  >
                    <div>
                      <p className="font-semibold text-foreground">{u.full_name || u.name}</p>
                      <p className="text-muted-foreground">{u.mobile} {u.email ? `• ${u.email}` : ""}</p>
                    </div>
                    {selectedUserToLink?.id === u.id && (
                      <CheckCircle2 className="h-4 w-4 text-primary shrink-0" />
                    )}
                  </div>
                ))}
              </div>
            ) : searchQuery.length >= 3 ? (
              <p className="text-xs text-muted-foreground text-center py-2">No unlinked users found matching query.</p>
            ) : null}

            <DialogFooter className="pt-2">
              <Button type="button" variant="outline" onClick={() => setLinkModalOpen(false)}>
                Cancel
              </Button>
              <Button
                disabled={!selectedUserToLink || linkMutation.isPending}
                onClick={() => selectedUserToLink && linkMutation.mutate(selectedUserToLink.id)}
              >
                {linkMutation.isPending ? "Linking..." : "Link Customer"}
              </Button>
            </DialogFooter>
          </div>
        </DialogContent>
      </Dialog>

      {/* Modal: Create New Customer */}
      <Dialog open={createModalOpen} onOpenChange={setCreateModalOpen}>
        <DialogContent className="sm:max-w-[450px]">
          <DialogHeader>
            <DialogTitle>Create New Customer Account</DialogTitle>
            <DialogDescription>
              Create a brand new customer user profile and associate with this branch.
            </DialogDescription>
          </DialogHeader>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              if (!newCustomer.full_name || !newCustomer.mobile) {
                toast.error("Full name and mobile are required");
                return;
              }
              createMutation.mutate(newCustomer);
            }}
            className="space-y-4 py-2"
          >
            <div className="space-y-2">
              <Label htmlFor="custName">Full Name *</Label>
              <Input
                id="custName"
                placeholder="e.g. Ramesh Kumar"
                value={newCustomer.full_name}
                onChange={(e) => setNewCustomer({ ...newCustomer, full_name: e.target.value })}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="custMobile">Mobile Number *</Label>
              <Input
                id="custMobile"
                placeholder="10-digit mobile number"
                value={newCustomer.mobile}
                onChange={(e) => setNewCustomer({ ...newCustomer, mobile: e.target.value })}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="custEmail">Email Address (Optional)</Label>
              <Input
                id="custEmail"
                type="email"
                placeholder="customer@example.com"
                value={newCustomer.email}
                onChange={(e) => setNewCustomer({ ...newCustomer, email: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="custPass">Default Password (Optional)</Label>
              <Input
                id="custPass"
                type="password"
                placeholder="Leave blank for auto-generated"
                value={newCustomer.password}
                onChange={(e) => setNewCustomer({ ...newCustomer, password: e.target.value })}
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
    </div>
  );
}
