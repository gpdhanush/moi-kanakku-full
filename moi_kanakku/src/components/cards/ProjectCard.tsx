import { ArrowUpRight } from "lucide-react";
import type { Project } from "@/data/projects";

export function ProjectCard({ project, featured = false }: { project: Project; featured?: boolean }) {
  return (
    <article className="group overflow-hidden rounded-lg border border-border bg-card transition-transform duration-500 hover:-translate-y-1">
      <div className="relative aspect-[16/10] overflow-hidden bg-surface-strong">
        <div className="absolute inset-0 bg-project-grid" aria-hidden="true" />
        <div className="absolute inset-x-6 bottom-6 flex items-end justify-between gap-4">
          <div>
            <p className="text-xs uppercase tracking-[0.2em] text-muted-foreground">{project.category}</p>
            <h3 className="mt-2 font-display text-3xl font-semibold text-foreground">{project.title}</h3>
          </div>
          <ArrowUpRight aria-hidden="true" className="text-accent transition-transform group-hover:-translate-y-1 group-hover:translate-x-1" />
        </div>
      </div>
      <div className={featured ? "p-7 sm:p-8" : "p-6"}>
        <p className="leading-7 text-muted-foreground">{project.description}</p>
        <div className="mt-6 flex flex-wrap gap-2">
          {project.technologies.map((technology) => (
            <span key={technology} className="rounded-full border border-border px-3 py-1 text-xs text-muted-foreground">
              {technology}
            </span>
          ))}
        </div>
        <div className="mt-6 flex justify-between border-t border-border pt-4 text-xs uppercase tracking-[0.18em] text-muted-foreground">
          <span>{project.client}</span>
          <span>{project.year}</span>
        </div>
      </div>
    </article>
  );
}
