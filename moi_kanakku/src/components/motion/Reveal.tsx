import type { ReactNode } from "react";
import { cn } from "@/lib/utils";

type RevealProps = {
  children: ReactNode;
  className?: string;
  as?: "div" | "span" | "li" | "article";
};

export function Reveal({ children, className, as = "div" }: RevealProps) {
  const Comp = as;
  return (
    <Comp data-reveal className={cn("motion-safe:opacity-0", className)}>
      {children}
    </Comp>
  );
}
