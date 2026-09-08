import { cn } from "@/lib/utils";
import { LucideIcon } from "lucide-react";

export const STAT_CARD_COLORS = [
  "blue",
  "emerald",
  "violet",
  "cyan",
  "amber",
  "rose",
  "indigo",
  "teal",
  "orange",
  "fuchsia",
  "sky",
  "lime",
  "pink",
] as const;

export type StatCardColor = (typeof STAT_CARD_COLORS)[number];

const COLOR_STYLES: Record<
  StatCardColor,
  {
    card: string;
    title: string;
    value: string;
    iconWrap: string;
    icon: string;
    watermark: string;
    glow: string;
  }
> = {
  blue: {
    card: "border-blue-400/30 bg-gradient-to-br from-blue-500/25 via-blue-400/10 to-transparent dark:from-blue-500/30 dark:via-blue-500/10",
    title: "text-blue-700/80 dark:text-blue-200/80",
    value: "text-blue-950 dark:text-blue-50",
    iconWrap: "bg-blue-500/20 text-blue-600 dark:text-blue-300",
    icon: "text-blue-600 dark:text-blue-300",
    watermark: "text-blue-500/15 dark:text-blue-300/15",
    glow: "shadow-blue-500/10",
  },
  emerald: {
    card: "border-emerald-400/30 bg-gradient-to-br from-emerald-500/25 via-emerald-400/10 to-transparent dark:from-emerald-500/30 dark:via-emerald-500/10",
    title: "text-emerald-700/80 dark:text-emerald-200/80",
    value: "text-emerald-950 dark:text-emerald-50",
    iconWrap: "bg-emerald-500/20 text-emerald-600 dark:text-emerald-300",
    icon: "text-emerald-600 dark:text-emerald-300",
    watermark: "text-emerald-500/15 dark:text-emerald-300/15",
    glow: "shadow-emerald-500/10",
  },
  violet: {
    card: "border-violet-400/30 bg-gradient-to-br from-violet-500/25 via-violet-400/10 to-transparent dark:from-violet-500/30 dark:via-violet-500/10",
    title: "text-violet-700/80 dark:text-violet-200/80",
    value: "text-violet-950 dark:text-violet-50",
    iconWrap: "bg-violet-500/20 text-violet-600 dark:text-violet-300",
    icon: "text-violet-600 dark:text-violet-300",
    watermark: "text-violet-500/15 dark:text-violet-300/15",
    glow: "shadow-violet-500/10",
  },
  cyan: {
    card: "border-cyan-400/30 bg-gradient-to-br from-cyan-500/25 via-cyan-400/10 to-transparent dark:from-cyan-500/30 dark:via-cyan-500/10",
    title: "text-cyan-700/80 dark:text-cyan-200/80",
    value: "text-cyan-950 dark:text-cyan-50",
    iconWrap: "bg-cyan-500/20 text-cyan-600 dark:text-cyan-300",
    icon: "text-cyan-600 dark:text-cyan-300",
    watermark: "text-cyan-500/15 dark:text-cyan-300/15",
    glow: "shadow-cyan-500/10",
  },
  amber: {
    card: "border-amber-400/30 bg-gradient-to-br from-amber-500/25 via-amber-400/10 to-transparent dark:from-amber-500/30 dark:via-amber-500/10",
    title: "text-amber-700/80 dark:text-amber-200/80",
    value: "text-amber-950 dark:text-amber-50",
    iconWrap: "bg-amber-500/20 text-amber-600 dark:text-amber-300",
    icon: "text-amber-600 dark:text-amber-300",
    watermark: "text-amber-500/15 dark:text-amber-300/15",
    glow: "shadow-amber-500/10",
  },
  rose: {
    card: "border-rose-400/30 bg-gradient-to-br from-rose-500/25 via-rose-400/10 to-transparent dark:from-rose-500/30 dark:via-rose-500/10",
    title: "text-rose-700/80 dark:text-rose-200/80",
    value: "text-rose-950 dark:text-rose-50",
    iconWrap: "bg-rose-500/20 text-rose-600 dark:text-rose-300",
    icon: "text-rose-600 dark:text-rose-300",
    watermark: "text-rose-500/15 dark:text-rose-300/15",
    glow: "shadow-rose-500/10",
  },
  indigo: {
    card: "border-indigo-400/30 bg-gradient-to-br from-indigo-500/25 via-indigo-400/10 to-transparent dark:from-indigo-500/30 dark:via-indigo-500/10",
    title: "text-indigo-700/80 dark:text-indigo-200/80",
    value: "text-indigo-950 dark:text-indigo-50",
    iconWrap: "bg-indigo-500/20 text-indigo-600 dark:text-indigo-300",
    icon: "text-indigo-600 dark:text-indigo-300",
    watermark: "text-indigo-500/15 dark:text-indigo-300/15",
    glow: "shadow-indigo-500/10",
  },
  teal: {
    card: "border-teal-400/30 bg-gradient-to-br from-teal-500/25 via-teal-400/10 to-transparent dark:from-teal-500/30 dark:via-teal-500/10",
    title: "text-teal-700/80 dark:text-teal-200/80",
    value: "text-teal-950 dark:text-teal-50",
    iconWrap: "bg-teal-500/20 text-teal-600 dark:text-teal-300",
    icon: "text-teal-600 dark:text-teal-300",
    watermark: "text-teal-500/15 dark:text-teal-300/15",
    glow: "shadow-teal-500/10",
  },
  orange: {
    card: "border-orange-400/30 bg-gradient-to-br from-orange-500/25 via-orange-400/10 to-transparent dark:from-orange-500/30 dark:via-orange-500/10",
    title: "text-orange-700/80 dark:text-orange-200/80",
    value: "text-orange-950 dark:text-orange-50",
    iconWrap: "bg-orange-500/20 text-orange-600 dark:text-orange-300",
    icon: "text-orange-600 dark:text-orange-300",
    watermark: "text-orange-500/15 dark:text-orange-300/15",
    glow: "shadow-orange-500/10",
  },
  fuchsia: {
    card: "border-fuchsia-400/30 bg-gradient-to-br from-fuchsia-500/25 via-fuchsia-400/10 to-transparent dark:from-fuchsia-500/30 dark:via-fuchsia-500/10",
    title: "text-fuchsia-700/80 dark:text-fuchsia-200/80",
    value: "text-fuchsia-950 dark:text-fuchsia-50",
    iconWrap: "bg-fuchsia-500/20 text-fuchsia-600 dark:text-fuchsia-300",
    icon: "text-fuchsia-600 dark:text-fuchsia-300",
    watermark: "text-fuchsia-500/15 dark:text-fuchsia-300/15",
    glow: "shadow-fuchsia-500/10",
  },
  sky: {
    card: "border-sky-400/30 bg-gradient-to-br from-sky-500/25 via-sky-400/10 to-transparent dark:from-sky-500/30 dark:via-sky-500/10",
    title: "text-sky-700/80 dark:text-sky-200/80",
    value: "text-sky-950 dark:text-sky-50",
    iconWrap: "bg-sky-500/20 text-sky-600 dark:text-sky-300",
    icon: "text-sky-600 dark:text-sky-300",
    watermark: "text-sky-500/15 dark:text-sky-300/15",
    glow: "shadow-sky-500/10",
  },
  lime: {
    card: "border-lime-400/30 bg-gradient-to-br from-lime-500/25 via-lime-400/10 to-transparent dark:from-lime-500/30 dark:via-lime-500/10",
    title: "text-lime-700/80 dark:text-lime-200/80",
    value: "text-lime-950 dark:text-lime-50",
    iconWrap: "bg-lime-500/20 text-lime-600 dark:text-lime-300",
    icon: "text-lime-600 dark:text-lime-300",
    watermark: "text-lime-500/15 dark:text-lime-300/15",
    glow: "shadow-lime-500/10",
  },
  pink: {
    card: "border-pink-400/30 bg-gradient-to-br from-pink-500/25 via-pink-400/10 to-transparent dark:from-pink-500/30 dark:via-pink-500/10",
    title: "text-pink-700/80 dark:text-pink-200/80",
    value: "text-pink-950 dark:text-pink-50",
    iconWrap: "bg-pink-500/20 text-pink-600 dark:text-pink-300",
    icon: "text-pink-600 dark:text-pink-300",
    watermark: "text-pink-500/15 dark:text-pink-300/15",
    glow: "shadow-pink-500/10",
  },
};

export interface StatCardProps {
  title: string;
  value: string | number;
  icon: LucideIcon;
  color?: StatCardColor;
  /** Cycle colors by index when color is not set */
  colorIndex?: number;
  description?: string;
  trend?: {
    value: number;
    isPositive: boolean;
  };
  onClick?: () => void;
  className?: string;
  size?: "default" | "sm";
}

export function getStatCardColor(index: number): StatCardColor {
  return STAT_CARD_COLORS[index % STAT_CARD_COLORS.length];
}

export function StatCard({
  title,
  value,
  icon: Icon,
  color,
  colorIndex = 0,
  description,
  trend,
  onClick,
  className,
  size = "default",
}: StatCardProps) {
  const tone = COLOR_STYLES[color ?? getStatCardColor(colorIndex)];
  const compact = size === "sm";

  const content = (
    <>
      <div className="pointer-events-none absolute -right-2 -top-2 opacity-100 transition-transform duration-300 group-hover:scale-110">
        <Icon
          className={cn(compact ? "h-16 w-16" : "h-24 w-24", tone.watermark)}
          strokeWidth={1.25}
        />
      </div>

      <div className="relative z-10 flex items-start justify-between gap-2">
        <div className={cn("min-w-0 flex-1", compact ? "space-y-1" : "space-y-2")}>
          <p className={cn(compact ? "text-xs font-medium leading-tight" : "text-sm font-medium", tone.title)}>
            {title}
          </p>
          <p
            className={cn(
              compact
                ? "text-xl font-bold tracking-tight break-all"
                : "text-3xl font-bold tracking-tight",
              tone.value
            )}
          >
            {value}
          </p>
          {description && (
            <p className={cn("text-xs", tone.title)}>{description}</p>
          )}
          {trend && (
            <p
              className={cn(
                "text-xs font-medium",
                trend.isPositive
                  ? "text-emerald-600 dark:text-emerald-400"
                  : "text-rose-600 dark:text-rose-400"
              )}
            >
              {trend.isPositive ? "+" : "-"}
              {Math.abs(trend.value)}% from last week
            </p>
          )}
        </div>

        <div
          className={cn(
            "flex shrink-0 items-center justify-center rounded-xl backdrop-blur-md",
            compact ? "h-8 w-8" : "h-11 w-11",
            tone.iconWrap
          )}
        >
          <Icon className={cn(compact ? "h-4 w-4" : "h-5 w-5", tone.icon)} />
        </div>
      </div>
    </>
  );

  const classes = cn(
    "glass-stat-card group relative overflow-hidden text-left shadow-lg backdrop-blur-xl transition-all duration-300",
    "hover:-translate-y-0.5 hover:shadow-xl",
    compact ? "p-3" : "p-5",
    tone.card,
    tone.glow,
    onClick && "cursor-pointer",
    className
  );

  if (onClick) {
    return (
      <button type="button" onClick={onClick} className={classes}>
        {content}
      </button>
    );
  }

  return <div className={classes}>{content}</div>;
}

export function StatCardSkeleton({
  className,
  size = "default",
}: {
  className?: string;
  size?: "default" | "sm";
}) {
  const compact = size === "sm";
  return (
    <div
      className={cn(
        "glass-stat-card animate-pulse border-border/40 bg-card/50 backdrop-blur-xl",
        compact ? "p-3" : "p-5",
        className
      )}
    >
      <div className="flex items-start justify-between gap-2">
        <div className={cn("flex-1", compact ? "space-y-2" : "space-y-3")}>
          <div className={cn("rounded bg-muted", compact ? "h-3 w-20" : "h-4 w-28")} />
          <div className={cn("rounded bg-muted", compact ? "h-6 w-12" : "h-8 w-16")} />
        </div>
        <div className={cn("rounded-xl bg-muted", compact ? "h-8 w-8" : "h-11 w-11")} />
      </div>
    </div>
  );
}
