import { Outlet, createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/locations")({
  component: LocationsLayout,
});

function LocationsLayout() {
  return <Outlet />;
}
