import type { ReactNode } from "react";
import { cn } from "@/lib/utils";
import { PageContainer } from "./PageContainer";

type SectionProps = {
  id?: string;
  eyebrow?: string;
  title?: string;
  description?: string;
  children: ReactNode;
  className?: string;
  containerClassName?: string;
};

export function Section({ id, eyebrow, title, description, children, className, containerClassName }: SectionProps) {
  return (
    <section id={id} className={cn("relative py-20 sm:py-28", className)}>
      <PageContainer className={containerClassName}>
        {(eyebrow || title || description) && (
          <div className="mb-12 max-w-3xl" data-reveal>
            {eyebrow && <p className="mb-4 text-xs font-semibold uppercase tracking-[0.24em] text-accent">{eyebrow}</p>}
            {title && <h2 className="font-display text-4xl font-semibold leading-tight text-foreground sm:text-6xl">{title}</h2>}
            {description && <p className="mt-5 text-base leading-8 text-muted-foreground sm:text-lg">{description}</p>}
          </div>
        )}
        {children}
      </PageContainer>
    </section>
  );
}
