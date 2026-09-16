import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Calendar,
  Plus,
  Search,
  RefreshCw,
  MapPin,
  Tag,
  DollarSign,
  Users,
  CheckCircle2,
  Clock,
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
import { franchiseApi, FranchiseFunction } from "@/features/franchise/api";
import { getUserRole } from "@/lib/auth";

export default function FranchiseFunctions() {
  const queryClient = useQueryClient();
  const userRole = getUserRole();
  const isStaff = userRole === "FRANCHISE_STAFF";

  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [selectedFunc, setSelectedFunc] = useState<FranchiseFunction | null>(null);

  // New function form
  const [newFunc, setNewFunc] = useState({
    name: "",
    function_date: new Date().toISOString().split("T")[0],
    location: "",
    event_type: "WEDDING",
  });

  // Query Functions List (Admin or Staff Assigned Functions)
  const { data: adminFuncs, isLoading: adminLoading, refetch: refetchAdmin } = useQuery({
    queryKey: ["franchise-functions"],
    queryFn: franchiseApi.listFunctions,
    enabled: !isStaff,
  });

  const { data: staffFuncs, isLoading: staffLoading, refetch: refetchStaff } = useQuery({
    queryKey: ["staff-assigned-functions"],
    queryFn: franchiseApi.getAssignedFunctions,
    enabled: isStaff,
  });

  const functionsList: FranchiseFunction[] = isStaff
    ? staffFuncs?.functions || []
    : adminFuncs?.functions || [];
  const isLoading = isStaff ? staffLoading : adminLoading;
  const refetch = isStaff ? refetchStaff : refetchAdmin;

  // Create Function Mutation
  const createMutation = useMutation({
    mutationFn: franchiseApi.createFunction,
    onSuccess: () => {
      toast.success("New function/event created successfully");
      setCreateModalOpen(false);
      setNewFunc({ name: "", function_date: new Date().toISOString().split("T")[0], location: "", event_type: "WEDDING" });
      queryClient.invalidateQueries({ queryKey: ["franchise-functions"] });
    },
    onError: (err: any) => {
      toast.error(err?.response?.data?.responseValue?.message || "Failed to create function");
    },
  });

  return (
    <div className="space-y-6 p-6">
      {/* Header Banner */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
            <Calendar className="h-7 w-7 text-primary" />
            {isStaff ? "My Assigned Functions / Events" : "Branch Functions & Events"}
          </h1>
          <p className="text-sm text-muted-foreground">
            {isStaff
              ? "Access counters, record transaction gifts, and view event live summaries."
              : "Create and manage customer events hosted at this franchise branch."}
          </p>
        </div>
        <div className="flex items-center gap-2">
          {!isStaff && (
            <Button onClick={() => setCreateModalOpen(true)} className="gap-2">
              <Plus className="h-4 w-4" /> Create New Function
            </Button>
          )}
          <Button variant="outline" size="icon" onClick={() => refetch()}>
            <RefreshCw className="h-4 w-4" />
          </Button>
        </div>
      </div>

      {/* Functions Grid / Table Card */}
      <Card>
        <CardHeader>
          <CardTitle>Functions List ({functionsList.length})</CardTitle>
          <CardDescription>
            {isStaff
              ? "Events you have active operational permissions for."
              : "Directory of branch events and counter registers."}
          </CardDescription>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="py-8 text-center text-sm text-muted-foreground">Loading functions...</div>
          ) : functionsList.length === 0 ? (
            <div className="py-8 text-center text-sm text-muted-foreground">No functions found.</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Event Name</TableHead>
                  <TableHead>Event Type</TableHead>
                  <TableHead>Date & Location</TableHead>
                  <TableHead>Total Persons</TableHead>
                  <TableHead>Total Collected</TableHead>
                  <TableHead>Status</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {functionsList.map((f) => (
                  <TableRow key={f.id}>
                    <TableCell className="font-semibold">{f.name}</TableCell>
                    <TableCell>
                      <Badge variant="outline" className="text-xs">
                        <Tag className="h-3 w-3 mr-1" /> {f.event_type || "EVENT"}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-xs">
                      <div className="flex items-center gap-1 font-medium">
                        <Calendar className="h-3 w-3 text-muted-foreground" />
                        {f.function_date ? new Date(f.function_date).toLocaleDateString("en-IN") : "—"}
                      </div>
                      {f.location && (
                        <div className="flex items-center gap-1 text-muted-foreground">
                          <MapPin className="h-3 w-3" /> {f.location}
                        </div>
                      )}
                    </TableCell>
                    <TableCell className="text-xs font-semibold">
                      <span className="flex items-center gap-1">
                        <Users className="h-3.5 w-3.5 text-muted-foreground" />
                        {f.total_persons || 0} persons
                      </span>
                    </TableCell>
                    <TableCell className="font-bold text-emerald-600">
                      ₹{Number(f.total_amount || 0).toLocaleString("en-IN")}
                    </TableCell>
                    <TableCell>
                      {f.status === "ACTIVE" ? (
                        <Badge className="bg-emerald-500/10 text-emerald-600 border-emerald-200">Active Counter</Badge>
                      ) : (
                        <Badge variant="secondary">{f.status}</Badge>
                      )}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Modal: Create Function */}
      <Dialog open={createModalOpen} onOpenChange={setCreateModalOpen}>
        <DialogContent className="sm:max-w-[480px]">
          <DialogHeader>
            <DialogTitle>Create New Function / Event</DialogTitle>
            <DialogDescription>
              Set up an event counter register for a branch customer.
            </DialogDescription>
          </DialogHeader>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              if (!newFunc.name || !newFunc.function_date) {
                toast.error("Function name and date are required");
                return;
              }
              createMutation.mutate(newFunc);
            }}
            className="space-y-4 py-2"
          >
            <div className="space-y-2">
              <Label htmlFor="funcName">Function Name *</Label>
              <Input
                id="funcName"
                placeholder="e.g. Anbarasan & Priya Marriage"
                value={newFunc.name}
                onChange={(e) => setNewFunc({ ...newFunc, name: e.target.value })}
                required
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="funcDate">Event Date *</Label>
                <Input
                  id="funcDate"
                  type="date"
                  value={newFunc.function_date}
                  onChange={(e) => setNewFunc({ ...newFunc, function_date: e.target.value })}
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="funcType">Event Category</Label>
                <Select
                  value={newFunc.event_type}
                  onValueChange={(val) => setNewFunc({ ...newFunc, event_type: val })}
                >
                  <SelectTrigger id="funcType">
                    <SelectValue placeholder="Type..." />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="WEDDING">Wedding / கல்யாணம்</SelectItem>
                    <SelectItem value="RECEPTION">Reception</SelectItem>
                    <SelectItem value="BIRTHDAY">Birthday / பிறந்தநாள்</SelectItem>
                    <SelectItem value="EAR_PIERCING">Ear Piercing / காதுகுத்து</SelectItem>
                    <SelectItem value="HOUSE_WARMING">House Warming / கிரகப்பிரவேசம்</SelectItem>
                    <SelectItem value="OTHER">Other Event</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
            <div className="space-y-2">
              <Label htmlFor="funcLoc">Hall / Location Name</Label>
              <Input
                id="funcLoc"
                placeholder="e.g. SRS Mahal, Madurai"
                value={newFunc.location}
                onChange={(e) => setNewFunc({ ...newFunc, location: e.target.value })}
              />
            </div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setCreateModalOpen(false)}>
                Cancel
              </Button>
              <Button type="submit" disabled={createMutation.isPending}>
                {createMutation.isPending ? "Creating..." : "Create Event"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
