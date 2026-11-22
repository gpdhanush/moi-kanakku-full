import { useCallback, useEffect, useState } from "react";
import useEmblaCarousel from "embla-carousel-react";
import { ChevronLeft, ChevronRight, Star } from "lucide-react";
import { motion, useReducedMotion } from "framer-motion";
import { T, useLang } from "@/lib/lang";
import { PLAY_URL } from "@/components/site";
import { cn } from "@/lib/utils";
import { TestimonialCard } from "@/components/ui/testimonial-card";
import playReviews from "@/data/play-reviews.json";

export type PlayReview = {
  author: string;
  /** null when the star rating isn't known (e.g. a hand-added review). */
  stars: number | null;
  /** ISO date, YYYY-MM-DD. */
  date: string | null;
  text: string;
};

type PlayReviewData = {
  rating: number | null;
  ratingCount: number | null;
  reviews: PlayReview[];
};

const spring = { type: "spring" as const, stiffness: 100, damping: 20 };

function Stars({ value, className }: { value: number; className?: string }) {
  const full = Math.round(value);
  return (
    <span className={cn("flex items-center gap-0.5", className)} aria-label={`${value} / 5`}>
      {Array.from({ length: 5 }, (_, i) => (
        <Star
          key={i}
          aria-hidden
          className={cn(
            "h-4 w-4",
            i < full ? "fill-lime text-lime" : "fill-transparent text-[#0b3d2e]/20",
          )}
        />
      ))}
    </span>
  );
}

const AUTOPLAY_MS = 5000;

function formatReviewDate(iso: string, lang: "ta" | "en") {
  const d = new Date(`${iso}T00:00:00Z`);
  if (Number.isNaN(d.getTime())) return iso;
  return d.toLocaleDateString(lang === "ta" ? "ta-IN" : "en-IN", {
    day: "numeric",
    month: "long",
    year: "numeric",
    timeZone: "UTC",
  });
}

/** Newest first; undated reviews go last. */
function sortReviewsNewestFirst(reviews: PlayReview[]) {
  return [...reviews].sort((a, b) => (b.date ?? "").localeCompare(a.date ?? ""));
}

function ReviewCard({ review }: { review: PlayReview }) {
  const { lang } = useLang();
  return (
    <TestimonialCard
      name={review.author}
      subtitle={
        review.date ? (
          <time dateTime={review.date}>{formatReviewDate(review.date, lang)}</time>
        ) : (
          "Google Play"
        )
      }
      stars={review.stars}
      text={review.text}
    />
  );
}

function TestimonialCarousel({ reviews }: { reviews: PlayReview[] }) {
  const reduce = useReducedMotion();
  const multiple = reviews.length > 1;
  const [emblaRef, api] = useEmblaCarousel({ loop: multiple, align: "start" });
  const [selected, setSelected] = useState(0);
  const [paused, setPaused] = useState(false);

  useEffect(() => {
    if (!api) return;
    const onSelect = () => setSelected(api.selectedScrollSnap());
    onSelect();
    api.on("select", onSelect).on("reInit", onSelect);
    return () => {
      api.off("select", onSelect).off("reInit", onSelect);
    };
  }, [api]);

  // Autoplay: off for reduced motion, paused while hovered/focused or the tab is hidden.
  useEffect(() => {
    if (!api || !multiple || reduce || paused) return;
    const id = window.setInterval(() => {
      if (document.visibilityState === "visible") api.scrollNext();
    }, AUTOPLAY_MS);
    return () => window.clearInterval(id);
  }, [api, multiple, reduce, paused]);

  const prev = useCallback(() => api?.scrollPrev(), [api]);
  const next = useCallback(() => api?.scrollNext(), [api]);

  return (
    <motion.div
      initial={reduce ? false : { opacity: 0, y: 18 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true }}
      transition={spring}
      className="mt-10"
      role="region"
      aria-roledescription="carousel"
      aria-label="Google Play reviews"
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
      onFocusCapture={() => setPaused(true)}
      onBlurCapture={() => setPaused(false)}
      onKeyDown={(e) => {
        if (e.key === "ArrowLeft") prev();
        if (e.key === "ArrowRight") next();
      }}
    >
      <div ref={emblaRef} className="-my-3 overflow-hidden py-3">
        <ul className="-ml-5 flex touch-pan-y">
          {reviews.map((review, i) => (
            <li
              key={`${review.author}-${review.date ?? i}`}
              role="group"
              aria-roledescription="slide"
              aria-label={`${i + 1} / ${reviews.length}`}
              className="min-w-0 shrink-0 grow-0 basis-full pl-5 sm:basis-1/2 lg:basis-1/3"
            >
              <ReviewCard review={review} />
            </li>
          ))}
        </ul>
      </div>

      {multiple && (
        <div className="mt-6 flex items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            {reviews.map((r, i) => (
              <button
                key={`dot-${r.author}-${i}`}
                type="button"
                onClick={() => api?.scrollTo(i)}
                aria-label={`Go to review ${i + 1}`}
                aria-current={i === selected}
                className={cn(
                  "h-2 rounded-full transition-all",
                  i === selected ? "w-6 bg-[#0b3d2e]" : "w-2 bg-[#0b3d2e]/25 hover:bg-[#0b3d2e]/50",
                )}
              />
            ))}
          </div>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={prev}
              aria-label="Previous review"
              className="flex h-10 w-10 items-center justify-center rounded-full border border-[#0b3d2e]/15 bg-white text-[#0b3d2e] transition-colors hover:bg-[#eef6e4]"
            >
              <ChevronLeft className="h-5 w-5" />
            </button>
            <button
              type="button"
              onClick={next}
              aria-label="Next review"
              className="flex h-10 w-10 items-center justify-center rounded-full bg-[#0b3d2e] text-white transition-colors hover:bg-black"
            >
              <ChevronRight className="h-5 w-5" />
            </button>
          </div>
        </div>
      )}
    </motion.div>
  );
}

/** Google Play reviews (snapshot in `src/data/play-reviews.json`, refreshed by `scripts/fetch-play-reviews.mjs`). */
export function TestimonialsSection({
  data = playReviews as PlayReviewData,
  className,
}: {
  data?: PlayReviewData;
  className?: string;
}) {
  if (data.reviews.length === 0) return null;

  return (
    <section
      id="testimonials"
      aria-labelledby="testimonials-heading"
      className={cn("bg-[#f7faf8] py-16 md:py-24", className)}
    >
      <div className="mx-auto max-w-[1400px] px-4 sm:px-6 lg:px-8">
        <div className="flex flex-col gap-6 md:flex-row md:items-end md:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-[#0b3d2e]/60">
              <T ta="பயனர் கருத்துகள்" en="Testimonials" />
            </p>
            <h2
              id="testimonials-heading"
              className="mt-2 max-w-[22ch] font-display text-3xl font-extrabold tracking-tighter text-[#0b3d2e] md:text-4xl"
            >
              <T ta="எங்கள் பயனர்கள் சொல்வது" en="What our users say" />
            </h2>
          </div>

          {data.rating != null && (
            <a
              href={PLAY_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-3 self-start rounded-[5px] border border-[#0b3d2e]/12 bg-white px-4 py-3 transition-colors hover:bg-[#eef6e4] md:self-auto"
            >
              <span className="font-display text-3xl font-extrabold text-[#0b3d2e]">
                {data.rating.toFixed(1)}
              </span>
              <span className="flex flex-col">
                <Stars value={data.rating} />
                <span className="mt-1 text-xs text-[#0b3d2e]/70">
                  {data.ratingCount != null ? (
                    <T
                      ta={`Google Play இல் ${data.ratingCount} மதிப்பீடுகள்`}
                      en={`${data.ratingCount} ratings on Google Play`}
                    />
                  ) : (
                    <T ta="Google Play மதிப்பீடு" en="Google Play rating" />
                  )}
                </span>
              </span>
            </a>
          )}
        </div>

        <TestimonialCarousel reviews={sortReviewsNewestFirst(data.reviews)} />

        <p className="mt-6 text-xs text-[#0b3d2e]/60">
          <T
            ta="Google Play Store இல் பதிவான உண்மையான மதிப்புரைகள்."
            en="Real reviews from the Google Play Store."
          />{" "}
          <a
            href={PLAY_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="font-semibold underline underline-offset-2"
          >
            <T ta="அனைத்தையும் பார்க்க" en="See all reviews" />
          </a>
        </p>
      </div>
    </section>
  );
}
