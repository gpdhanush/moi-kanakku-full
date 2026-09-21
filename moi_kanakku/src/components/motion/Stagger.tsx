import { Children, type ReactNode } from "react";
import { cn } from "@/lib/utils";

export function Stagger({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <div className={cn("grid gap-4", className)}>
      {Children.map(children, (child, index) => (
        <div data-reveal className="motion-safe:opacity-0" style={{ transitionDelay: `${index * 60}ms` }}>
          {child}
        </div>
      ))}
    </div>
  );
}
