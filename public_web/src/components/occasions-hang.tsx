"use client";

import { useEffect, useRef, useState } from "react";
import { HugeiconsIcon } from "@hugeicons/react";
import {
  ArrowLeft01Icon,
  ArrowRight01Icon,
  Cancel01Icon,
} from "@hugeicons/core-free-icons";
import {
  motion,
  useReducedMotion,
  useScroll,
  useSpring,
  useTransform,
} from "framer-motion";
import { T, useLang } from "@/lib/lang";
import { cn } from "@/lib/utils";

export type OccasionItem = {
  ta: string;
  en: string;
  src: string;
  objectPosition?: string;
};

function HangCard({
  item,
  index,
  onOpen,
}: {
  item: OccasionItem;
  index: number;
  onOpen: () => void;
}) {
  const reduce = useReducedMotion();
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start end", "start start"],
  });
  const rawScale = useTransform(scrollYProgress, [0, 0.55, 1], [0.92, 0.97, 1]);
  const rawY = useTransform(scrollYProgress, [0, 1], [48, 0]);
  const scale = useSpring(rawScale, { stiffness: 90, damping: 22 });
  const y = useSpring(rawY, { stiffness: 90, damping: 22 });

  return (
    <div
      ref={ref}
      className="sticky top-[9.5rem] mb-6 h-[min(72dvh,600px)] md:top-[11rem] md:mb-8"
      style={{ zIndex: index + 1 }}
    >
      <motion.button
        type="button"
        onClick={onOpen}
        style={reduce ? {} : { scale, y }}
        className={cn(
          "group relative h-full w-full overflow-hidden rounded-[5px] text-left",
          "border border-white/10 shadow-[0_28px_70px_-24px_rgba(11,61,46,0.55)]",
          "active:scale-[0.995]",
        )}
      >
        <img
          src={item.src}
          alt=""
          className="absolute inset-0 h-full w-full object-cover transition-transform duration-700 ease-[cubic-bezier(0.16,1,0.3,1)] group-hover:scale-[1.03]"
          style={item.objectPosition ? { objectPosition: item.objectPosition } : undefined}
          loading={index === 0 ? "eager" : "lazy"}
        />
        <div className="absolute inset-0 bg-gradient-to-t from-[#0b3d2e]/90 via-[#0b3d2e]/25 to-transparent" />
        <div className="absolute inset-x-0 bottom-0 flex items-end justify-between gap-4 p-6 sm:p-8">
          <h3 className="font-display text-2xl font-extrabold tracking-tight text-white sm:text-3xl md:text-4xl">
            <T ta={item.ta} en={item.en} />
          </h3>
          <span className="hidden rounded-[5px] border border-white/25 bg-white/10 px-3 py-2 text-xs font-semibold text-white backdrop-blur-md sm:inline-flex">
            <T ta="பார்க்க" en="View" />
          </span>
        </div>
      </motion.button>
    </div>
  );
}

export function OccasionsHang({ items }: { items: OccasionItem[] }) {
  const { lang } = useLang();
  const reduce = useReducedMotion();
  const [active, setActive] = useState<number | null>(null);
  const current = active === null ? null : items[active];

  useEffect(() => {
    if (active === null) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setActive(null);
      if (e.key === "ArrowLeft") {
        setActive((i) => (i === null ? null : (i - 1 + items.length) % items.length));
      }
      if (e.key === "ArrowRight") {
        setActive((i) => (i === null ? null : (i + 1) % items.length));
      }
    };
    window.addEventListener("keydown", onKey);
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      window.removeEventListener("keydown", onKey);
      document.body.style.overflow = prev;
    };
  }, [active, items.length]);

  return (
    <>
      <div className={cn("relative", reduce && "space-y-4")}>
        {items.map((item, i) => (
          <HangCard
            key={item.en}
            item={item}
            index={i}
            onOpen={() => setActive(i)}
          />
        ))}
      </div>

      {current && active !== null && (
        <div
          className="fixed inset-0 z-[60] flex items-center justify-center bg-[#0b3d2e]/94 p-4 backdrop-blur-md"
          onClick={() => setActive(null)}
          role="presentation"
        >
          <div
            className="relative flex w-full max-w-5xl flex-col gap-4"
            onClick={(e) => e.stopPropagation()}
            role="dialog"
            aria-modal="true"
            aria-label={lang === "ta" ? current.ta : current.en}
          >
            <div className="flex items-center justify-between gap-4">
              <h3 className="font-display text-xl font-bold text-white sm:text-2xl">
                <T ta={current.ta} en={current.en} />
              </h3>
              <button
                type="button"
                onClick={() => setActive(null)}
                className="rounded-[5px] bg-white/10 p-2 text-white transition-colors hover:bg-white/20"
                aria-label="Close"
              >
                <HugeiconsIcon icon={Cancel01Icon} size={20} strokeWidth={1.5} />
              </button>
            </div>
            <div className="relative overflow-hidden rounded-[5px] bg-black/30">
              <img
                src={current.src}
                alt={lang === "ta" ? current.ta : current.en}
                className="max-h-[70vh] w-full object-contain"
              />
              <button
                type="button"
                onClick={() =>
                  setActive((i) => (i === null ? null : (i - 1 + items.length) % items.length))
                }
                className="absolute top-1/2 left-2 -translate-y-1/2 rounded-[5px] bg-black/55 p-2.5 text-white hover:bg-black/75 sm:left-4"
                aria-label="Previous image"
              >
                <HugeiconsIcon icon={ArrowLeft01Icon} size={22} strokeWidth={1.5} />
              </button>
              <button
                type="button"
                onClick={() => setActive((i) => (i === null ? null : (i + 1) % items.length))}
                className="absolute top-1/2 right-2 -translate-y-1/2 rounded-[5px] bg-black/55 p-2.5 text-white hover:bg-black/75 sm:right-4"
                aria-label="Next image"
              >
                <HugeiconsIcon icon={ArrowRight01Icon} size={22} strokeWidth={1.5} />
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
