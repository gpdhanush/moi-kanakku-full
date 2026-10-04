import { useMemo } from "react";
import { d3Curve, defineChart, lineY } from "@tanstack/charts";
import { crosshair } from "@tanstack/charts/crosshair";
import { Chart } from "@tanstack/charts/react";
import { scaleLinear } from "@tanstack/charts/scales/linear";
import { scalePoint } from "@tanstack/charts/scales/point";
import { tooltip } from "@tanstack/charts/tooltip";
import { curveCatmullRom } from "d3-shape";
import { cn } from "@/lib/utils";

type TrendPoint = {
  date: string;
  count: number;
};

type SignupTrendChartProps = {
  data: TrendPoint[];
  height?: number;
  className?: string;
  ariaLabel?: string;
  seriesLabel?: string;
  emptyMessage?: string;
};

function formatAxisDate(rawDate: string): string {
  const date = new Date(`${rawDate}T00:00:00`);
  if (Number.isNaN(date.getTime())) {
    return rawDate.length >= 10 ? rawDate.slice(5) : rawDate;
  }
  return date.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
  });
}

export function SignupTrendChart({
  data,
  height = 260,
  className,
  ariaLabel = "Daily trend",
  seriesLabel = "Count",
  emptyMessage = "No data recorded for this month.",
}: SignupTrendChartProps) {
  const points = useMemo(
    () =>
      data.map((item) => ({
        date: formatAxisDate(
          typeof item.date === "string"
            ? item.date.slice(0, 10)
            : String(item.date),
        ),
        count: Number(item.count) || 0,
      })),
    [data],
  );

  const chartDefinition = useMemo(
    () =>
      defineChart({
        marks: [
          lineY(points, {
            x: "date",
            y: "count",
            stroke: "#02B2AF",
            strokeWidth: 2.5,
            points: true,
            curve: d3Curve(curveCatmullRom),
          }),
          crosshair({
            x: {
              label: {
                format: (value) => String(value),
                fill: "#ffffff",
                stroke: "#334155",
                strokeWidth: 12,
                fontSize: 11,
                fontWeight: 700,
                offset: 10,
              },
              stroke: "#64748b",
              strokeWidth: 1,
              strokeDasharray: "4 4",
            },
            y: {
              label: {
                format: (value) => String(value),
                fill: "#ffffff",
                stroke: "#334155",
                strokeWidth: 12,
                fontSize: 11,
                fontWeight: 700,
                offset: 10,
              },
              stroke: "#64748b",
              strokeWidth: 1,
              strokeDasharray: "4 4",
            },
            marker: {
              radius: 5,
              fill: "#02B2AF",
              stroke: "#ffffff",
              strokeWidth: 2,
            },
          }),
        ],
        scales: {
          x: {
            scale: () => scalePoint<string>().padding(0.2),
            axis: { label: "Date" },
          },
          y: {
            scale: scaleLinear,
            nice: true,
            grid: true,
            axis: { label: seriesLabel },
          },
        },
        focus: "nearest-x",
        maxFocusDistance: Number.POSITIVE_INFINITY,
        tooltip: {
          use: tooltip,
          className: "mk-users-chart-tooltip",
          content: (focusedPoints) => {
            const primary = focusedPoints[0];
            if (!primary) return { rows: [] };
            return {
              title: String(primary.xValue ?? ""),
              rows: [
                {
                  label: seriesLabel,
                  value: String(Number(primary.yValue ?? 0)),
                  color: "#02B2AF",
                  active: true,
                },
              ],
            };
          },
        },
        svgAnimation: true,
      }),
    [points, seriesLabel],
  );

  const total = points.reduce((sum, point) => sum + point.count, 0);
  if (points.length === 0 || total === 0) {
    return (
      <div
        className={cn(
          "flex items-center justify-center text-sm text-muted-foreground",
          className,
        )}
        style={{ height }}
      >
        {emptyMessage}
      </div>
    );
  }

  return (
    <div
      className={cn("mk-users-monthly-chart w-full", className)}
      style={{ height }}
    >
      <Chart
        definition={chartDefinition}
        height={height}
        className="h-full w-full"
        ariaLabel={ariaLabel}
        ariaDescription={`Line chart of daily ${seriesLabel.toLowerCase()}. Hover to see date and count.`}
      />
    </div>
  );
}
