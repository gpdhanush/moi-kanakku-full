import type { ReactNode } from "react";

export function TechnologyCard({ name, group, icon }: { name: string; group: string; icon?: ReactNode }) {
  return (
    <article className="group relative overflow-hidden rounded-lg border border-border bg-card p-5 transition-transform duration-500 hover:-translate-y-1">
      <div className="absolute inset-0 bg-tech-shine opacity-0 transition-opacity duration-500 group-hover:opacity-100" aria-hidden="true" />
      <div className="relative flex items-center justify-between gap-4">
        <div>
          <h3 className="font-display text-xl font-semibold text-card-foreground">{name}</h3>
          <p className="mt-2 text-xs uppercase tracking-[0.18em] text-muted-foreground">{group}</p>
        </div>
        {icon}
      </div>
    </article>
  );
}
