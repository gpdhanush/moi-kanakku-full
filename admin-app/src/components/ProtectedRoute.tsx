import { Navigate, useLocation } from "react-router-dom";
import { isAuthenticated, getUserRole } from "@/lib/auth";

interface ProtectedRouteProps {
  children: JSX.Element;
  allowedRoles?: Array<'SUPER_ADMIN' | 'FRANCHISE_ADMIN' | 'FRANCHISE_STAFF' | 'FRANCHISE_CUSTOMER' | 'DIRECT_USER'>;
}

export function ProtectedRoute({ children, allowedRoles }: ProtectedRouteProps) {
  const location = useLocation();

  if (!isAuthenticated()) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  if (allowedRoles && allowedRoles.length > 0) {
    const userRole = getUserRole();
    if (!allowedRoles.includes(userRole)) {
      return <Navigate to="/dashboard" replace />;
    }
  }

  return children;
}

export default ProtectedRoute;
