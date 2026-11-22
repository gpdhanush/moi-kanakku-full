import type { ReactNode } from "react";
import { Star } from "lucide-react";
import { cn } from "@/lib/utils";

export type TestimonialCardProps = {
  name: string;
  /** Second line under the name (e.g. the review date). */
  subtitle?: ReactNode;
  /** Image URL for the avatar; falls back to the name's initials. */
  avatarSrc?: string;
  /** 0–5. Omit/null to hide the star row. */
  stars?: number | null;
  text: string;
  /** "Read more" link target; hidden when omitted. */
  href?: string;
  readMoreLabel?: ReactNode;
  className?: string;
};

function initials(name: string) {
  return name
    .replace(/[^\p{L}\s]/gu, " ")
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0]!.toUpperCase())
    .join("");
}

/** Review card in the Moi Kanakku theme (deep green + lime). */
export function TestimonialCard({
  name,
  subtitle,
  avatarSrc,
  stars,
  text,
  href,
  readMoreLabel = "Read more",
  className,
}: TestimonialCardProps) {
  return (
    <figure
      className={cn(
        "flex h-full flex-col overflow-hidden rounded-lg border border-[#0b3d2e]/10 bg-white text-sm shadow-[0px_4px_15px_0px] shadow-black/5",
        className,
      )}
    >
      <figcaption className="flex items-center gap-4 bg-lime-soft px-5 py-4">
        {avatarSrc ? (
          <img className="h-12 w-12 shrink-0 rounded-full object-cover" src={avatarSrc} alt="" />
        ) : (
          <span
            aria-hidden
            className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-[#0b3d2e] text-base font-semibold text-lime"
          >
            {initials(name)}
          </span>
        )}
        <div className="min-w-0">
          <p className="truncate text-lg font-medium text-[#0b3d2e]">{name}</p>
          {subtitle && <p className="text-[#0b3d2e]/70">{subtitle}</p>}
        </div>
      </figcaption>

      <div className="flex-1 p-5 pb-7">
        {stars != null && (
          <div className="flex gap-0.5" aria-label={`${stars} / 5`}>
            {Array.from({ length: 5 }, (_, i) => (
              <Star
                key={i}
                aria-hidden
                className={cn(
                  "h-5 w-5",
                  i < Math.round(stars)
                    ? "fill-lime text-lime"
                    : "fill-transparent text-[#0b3d2e]/20",
                )}
              />
            ))}
          </div>
        )}
        <blockquote className={cn("leading-relaxed text-[#0b3d2e]/70", stars != null && "mt-5")}>
          {text}
        </blockquote>
      </div>

      {href && (
        <a
          href={href}
          target="_blank"
          rel="noopener noreferrer"
          className="px-5 pb-6 font-medium text-[#0b3d2e] underline underline-offset-2 hover:text-black"
        >
          {readMoreLabel}
        </a>
      )}
    </figure>
  );
}
