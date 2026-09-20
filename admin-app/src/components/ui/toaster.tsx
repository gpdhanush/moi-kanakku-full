import { useToast } from "@/hooks/use-toast";
import { Toast, ToastClose, ToastDescription, ToastProvider, ToastTitle, ToastViewport } from "@/components/ui/toast";
import { AlertTriangle, CheckCircle2, Info } from "lucide-react";

export function Toaster() {
  const { toasts } = useToast();

  return (
    <ToastProvider>
      {toasts.map(function ({ id, title, description, action, ...props }) {
        const variant = props.variant || "default";

        return (
          <Toast key={id} {...props}>
            <div className="mr-auto flex min-w-0 items-center gap-x-2">
              {(variant === "destructive" || variant === "error") && (
                <AlertTriangle
                  className="h-7 w-7 shrink-0 text-current"
                  aria-hidden="true"
                />
              )}
              {variant === "success" && (
                <CheckCircle2
                  className="h-7 w-7 shrink-0 text-current"
                  aria-hidden="true"
                />
              )}
              {(variant === "default" || variant === "info") && (
                <Info
                  className="h-7 w-7 shrink-0 text-current"
                  aria-hidden="true"
                />
              )}
              <div className="grid min-w-0 gap-1">
                {title && <ToastTitle>{title}</ToastTitle>}
                {description && <ToastDescription>{description}</ToastDescription>}
              </div>
            </div>
            {action}
            <ToastClose />
          </Toast>
        );
      })}
      <ToastViewport />
    </ToastProvider>
  );
}

