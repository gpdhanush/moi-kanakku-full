import { useEffect, useRef, useCallback, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useQueryClient } from "@tanstack/react-query";
import { clearAuth } from "@/lib/auth";
import { toast } from "@/hooks/use-toast";
import {
  getSessionTimeout,
  SESSION_TIMEOUT_CHANGED_EVENT,
} from "@/lib/settingsPrefs";

interface UseIdleTimeoutOptions {
  enabled?: boolean;
}

/**
 * Auto-logout after inactivity. Timeout comes from local settings preference.
 */
export function useIdleTimeout({ enabled = true }: UseIdleTimeoutOptions = {}) {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [timeoutMinutes, setTimeoutMinutes] = useState(getSessionTimeout);
  const timeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const warningRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const lastActivityRef = useRef(Date.now());
  const warningShownRef = useRef(false);

  useEffect(() => {
    const onChange = (event: Event) => {
      const detail = (event as CustomEvent<number>).detail;
      setTimeoutMinutes(
        typeof detail === "number" ? detail : getSessionTimeout()
      );
    };
    window.addEventListener(SESSION_TIMEOUT_CHANGED_EVENT, onChange);
    return () => window.removeEventListener(SESSION_TIMEOUT_CHANGED_EVENT, onChange);
  }, []);

  const clearTimers = useCallback(() => {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
      timeoutRef.current = null;
    }
    if (warningRef.current) {
      clearTimeout(warningRef.current);
      warningRef.current = null;
    }
  }, []);

  const logout = useCallback(async () => {
    clearTimers();
    await clearAuth();
    queryClient.clear();
    toast({
      title: "Session Expired",
      description: "You have been logged out due to inactivity.",
      variant: "destructive",
    });
    navigate("/login", { replace: true });
  }, [clearTimers, navigate, queryClient]);

  const resetTimer = useCallback(() => {
    clearTimers();
    warningShownRef.current = false;
    lastActivityRef.current = Date.now();

    if (!enabled || timeoutMinutes <= 0) return;

    const timeoutMs = timeoutMinutes * 60 * 1000;
    const warningLeadMs = Math.min(5 * 60 * 1000, timeoutMs * 0.25);
    const warningDelay = timeoutMs - warningLeadMs;

    if (warningDelay > 0 && warningLeadMs >= 30_000) {
      warningRef.current = setTimeout(() => {
        if (warningShownRef.current) return;
        if (Date.now() - lastActivityRef.current < warningDelay) return;
        warningShownRef.current = true;
        const mins = Math.max(1, Math.round(warningLeadMs / 60_000));
        toast({
          title: "Session Expiring Soon",
          description: `You will be logged out in about ${mins} minute${mins === 1 ? "" : "s"} due to inactivity.`,
        });
      }, warningDelay);
    }

    timeoutRef.current = setTimeout(() => {
      if (Date.now() - lastActivityRef.current >= timeoutMs) {
        void logout();
      }
    }, timeoutMs);
  }, [clearTimers, enabled, timeoutMinutes, logout]);

  useEffect(() => {
    if (!enabled || timeoutMinutes <= 0) {
      clearTimers();
      return;
    }

    const events = [
      "mousedown",
      "mousemove",
      "keypress",
      "scroll",
      "touchstart",
      "click",
      "keydown",
    ] as const;

    const handleActivity = () => resetTimer();
    events.forEach((event) => {
      document.addEventListener(event, handleActivity, { passive: true });
    });
    resetTimer();

    return () => {
      events.forEach((event) => {
        document.removeEventListener(event, handleActivity);
      });
      clearTimers();
    };
  }, [resetTimer, enabled, timeoutMinutes, clearTimers]);

  return { timeoutMinutes, resetTimer };
}
