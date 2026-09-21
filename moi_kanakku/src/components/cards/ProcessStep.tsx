import type { ProcessStep as ProcessStepType } from "@/data/process";

export function ProcessStep({ step, active }: { step: ProcessStepType; active?: boolean }) {
  return (
    <article className={active ? "min-w-[18rem] rounded-lg border border-primary bg-primary p-6 text-primary-foreground transition-all duration-500 sm:min-w-[25rem]" : "min-w-[16rem] rounded-lg border border-border bg-card p-6 transition-all duration-500 sm:min-w-[20rem]"}>
      <p className={active ? "font-display text-sm text-primary-foreground/70" : "font-display text-sm text-accent"}>{step.number}</p>
      <h3 className="mt-8 font-display text-3xl font-semibold">{step.title}</h3>
      <p className={active ? "mt-4 leading-7 text-primary-foreground/80" : "mt-4 leading-7 text-muted-foreground"}>{step.description}</p>
    </article>
  );
}
