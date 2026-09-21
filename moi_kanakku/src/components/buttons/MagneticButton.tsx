import { useState, type PointerEvent, type ReactNode } from "react";
import { ArrowUpRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { getMagneticTransform } from "@/animations/magnetic";
import { cn } from "@/lib/utils";

type MagneticButtonProps = {
  children: ReactNode;
  href?: string;
  onClick?: () => void;
  variant?: "primary" | "secondary" | "quiet";
  className?: string;
  icon?: boolean;
  ariaLabel?: string;
};

export function MagneticButton({
  children,
  href,
  onClick,
  variant = "primary",
  className,
  icon = true,
  ariaLabel,
}: MagneticButtonProps) {
  const [transform, setTransform] = useState("translate3d(0, 0, 0)");
  const classes = cn(
    "group h-12 rounded-full px-6 text-sm transition-transform duration-300 ease-out",
    variant === "primary" && "bg-primary text-primary-foreground shadow-cinematic hover:bg-primary/90",
    variant === "secondary" &&
      "border border-border bg-secondary/80 text-secondary-foreground backdrop-blur-xl hover:bg-accent",
    variant === "quiet" && "bg-transparent text-foreground hover:bg-secondary",
    className,
  );

  const handlePointerMove = (event: PointerEvent<HTMLElement>) => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    setTransform(getMagneticTransform(event));
  };

  const buttonContent = (
    <>
      {children}
      {icon && <ArrowUpRight aria-hidden="true" className="transition-transform group-hover:-translate-y-0.5 group-hover:translate-x-0.5" />}
    </>
  );

  if (href) {
    return (
      <Button asChild className={classes} style={{ transform }} aria-label={ariaLabel}>
        <a
          href={href}
          onPointerMove={handlePointerMove}
          onPointerLeave={() => setTransform("translate3d(0, 0, 0)")}
        >
          {buttonContent}
        </a>
      </Button>
    );
  }

  return (
    <Button
      type="button"
      onClick={onClick}
      className={classes}
      style={{ transform }}
      aria-label={ariaLabel}
      onPointerMove={handlePointerMove}
      onPointerLeave={() => setTransform("translate3d(0, 0, 0)")}
    >
      {buttonContent}
    </Button>
  );
}
