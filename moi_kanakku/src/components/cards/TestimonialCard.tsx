import { Star } from "lucide-react";
import type { Testimonial } from "@/data/testimonials";

export function TestimonialCard({ testimonial }: { testimonial: Testimonial }) {
  return (
    <article className="min-w-[20rem] rounded-lg border border-border bg-card p-6 sm:min-w-[28rem]">
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <div className="flex size-12 items-center justify-center rounded-full bg-secondary font-display text-sm font-semibold text-secondary-foreground">
            {testimonial.photoInitials}
          </div>
          <div>
            <h3 className="font-semibold text-card-foreground">{testimonial.name}</h3>
            <p className="text-sm text-muted-foreground">{testimonial.designation}, {testimonial.company}</p>
          </div>
        </div>
        <div className="flex" aria-label={`${testimonial.rating} star rating`}>
          {Array.from({ length: testimonial.rating }).map((_, index) => (
            <Star key={index} className="size-4 fill-accent text-accent" aria-hidden="true" />
          ))}
        </div>
      </div>
      <p className="mt-8 text-lg leading-8 text-foreground">“{testimonial.review}”</p>
      <p className="mt-6 text-xs uppercase tracking-[0.18em] text-muted-foreground">{testimonial.project}</p>
    </article>
  );
}
