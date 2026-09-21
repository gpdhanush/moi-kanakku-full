import { ArrowUpRight } from "lucide-react";
import type { Service } from "@/data/services";
import { whatsappMessages } from "@/data/company";
import { getWhatsAppUrl } from "@/utils/whatsapp";

export function ServiceCard({ service }: { service: Service }) {
  return (
    <article className="group grid gap-6 border-t border-border py-10 transition-colors hover:border-primary lg:grid-cols-[0.8fr_1.6fr_1fr] lg:items-center">
      <div className="flex items-start gap-5">
        <span className="font-display text-sm text-accent">{service.index}</span>
        <h3 className="whitespace-pre-line font-display text-4xl font-semibold leading-none text-foreground sm:text-6xl lg:text-7xl">
          {service.title}
        </h3>
      </div>
      <p className="max-w-xl text-base leading-8 text-muted-foreground lg:text-lg">{service.description}</p>
      <div className="space-y-5 lg:justify-self-end">
        <div className="flex flex-wrap gap-2">
          {service.technologies.map((technology) => (
            <span key={technology} className="rounded-full border border-border bg-secondary px-3 py-1 text-xs text-muted-foreground">
              {technology}
            </span>
          ))}
        </div>
        <a
          href={getWhatsAppUrl(whatsappMessages[service.whatsappKey])}
          target="_blank"
          rel="noreferrer"
          className="inline-flex items-center gap-2 text-sm font-semibold text-primary transition-colors hover:text-accent"
        >
          {service.cta}
          <ArrowUpRight aria-hidden="true" className="size-4 transition-transform group-hover:-translate-y-0.5 group-hover:translate-x-0.5" />
        </a>
      </div>
    </article>
  );
}
