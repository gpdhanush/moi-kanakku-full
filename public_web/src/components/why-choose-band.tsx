"use client";

import { memo } from "react";
import { Link } from "@tanstack/react-router";
import { HugeiconsIcon } from "@hugeicons/react";
import type { IconSvgElement } from "@hugeicons/react";
import {
  ArrowUpRight01Icon,
  CloudSavingDone01Icon,
  CustomerSupportIcon,
  ShieldKeyIcon,
} from "@hugeicons/core-free-icons";
import { motion, useReducedMotion } from "framer-motion";
import { T } from "@/lib/lang";
import { cn } from "@/lib/utils";

const spring = { type: "spring" as const, stiffness: 100, damping: 20 };

const reasons = [
  {
    icon: CloudSavingDone01Icon,
    ta: "Cloud-based",
    en: "Cloud-based",
    dta: "எங்கும் அணுகக்கூடிய பாதுகாப்பான தரவு சேமிப்பு",
    den: "Secure data storage you can reach from anywhere.",
    wide: true,
  },
  {
    icon: CustomerSupportIcon,
    ta: "24/7 ஆதரவு",
    en: "24/7 support",
    dta: "தமிழ் மற்றும் ஆங்கில மொழியில் தொழில்நுட்ப ஆதரவு",
    den: "Technical support in Tamil and English.",
    wide: false,
  },
  {
    icon: ShieldKeyIcon,
    ta: "முழு பாதுகாப்பு",
    en: "Full protection",
    dta: "வங்கி-நிலை பாதுகாப்பு மற்றும் தரவு குறியாக்கம்",
    den: "Bank-level security and data encryption.",
    wide: false,
  },
] as const;

const FloatIcon = memo(function FloatIcon({
  icon,
  className,
  delay = 0,
}: {
  icon: IconSvgElement;
  className?: string;
  delay?: number;
}) {
  const reduce = useReducedMotion();
  return (
    <motion.span
      className={cn(
        "flex h-12 w-12 items-center justify-center rounded-[5px] bg-[#0b3d2e] text-lime",
        className,
      )}
      animate={reduce ? false : { y: [0, -5, 0] }}
      transition={{
        duration: 3.4,
        repeat: Infinity,
        ease: "easeInOut",
        delay,
      }}
    >
      <HugeiconsIcon icon={icon} size={22} strokeWidth={1.5} />
    </motion.span>
  );
});

export function WhyChooseBand() {
  const reduce = useReducedMotion();

  return (
    <section className="relative overflow-hidden bg-[#f3f6f0] py-16 md:py-24">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_15%_0%,rgba(144,208,31,0.16),transparent_45%),radial-gradient(ellipse_at_90%_70%,rgba(11,61,46,0.06),transparent_40%)]"
      />

      <div className="relative mx-auto max-w-[1400px] px-4 sm:px-6 lg:px-8">
        {/* Why choose — asymmetric 2fr / 1fr stack, not 3 equal cards */}
        <motion.div
          initial={reduce ? false : { opacity: 0, y: 28 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, amount: 0.25 }}
          transition={spring}
          className="rounded-[5px] border border-white/60 bg-white/55 p-6 shadow-[inset_0_1px_0_rgba(255,255,255,0.75),0_20px_50px_-28px_rgba(11,61,46,0.18)] backdrop-blur-md sm:p-8 md:p-10"
        >
          <div className="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
            <h2 className="max-w-[22ch] font-display text-2xl font-extrabold tracking-tighter text-[#0b3d2e] sm:text-3xl md:text-4xl">
              <T
                ta="ஏன் Moi Kanakku தேர்வு செய்ய வேண்டும்?"
                en="Why choose Moi Kanakku?"
              />
            </h2>
            <p className="max-w-[36ch] text-sm leading-relaxed text-muted-foreground">
              <T
                ta="தெளிவான பதிவு, எப்போதும் உதவி, பாதுகாப்பான தரவு — ஒரே இடத்தில்."
                en="Clear records, always-on help, and protected data — in one place."
              />
            </p>
          </div>

          <div className="mt-8 grid gap-4 md:grid-cols-[1.35fr_1fr]">
            {/* Featured wide reason */}
            <motion.article
              initial={reduce ? false : { opacity: 0, x: -18 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ ...spring, delay: 0.05 }}
              className="flex min-h-[200px] flex-col justify-between rounded-[5px] border border-[#0b3d2e]/10 bg-[linear-gradient(145deg,rgba(238,246,228,0.9),rgba(255,255,255,0.75))] p-6 shadow-[inset_0_1px_0_rgba(255,255,255,0.8)]"
            >
              <FloatIcon icon={reasons[0].icon} delay={0} />
              <div className="mt-8">
                <h3 className="font-display text-xl font-bold tracking-tight text-[#0b3d2e]">
                  <T ta={reasons[0].ta} en={reasons[0].en} />
                </h3>
                <p className="mt-2 max-w-[36ch] text-sm leading-relaxed text-muted-foreground">
                  <T ta={reasons[0].dta} en={reasons[0].den} />
                </p>
              </div>
            </motion.article>

            {/* Stacked pair */}
            <div className="grid gap-4">
              {reasons.slice(1).map((r, i) => (
                <motion.article
                  key={r.en}
                  initial={reduce ? false : { opacity: 0, x: 18 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true }}
                  transition={{ ...spring, delay: 0.1 + i * 0.08 }}
                  className="flex items-start gap-4 rounded-[5px] border border-[#0b3d2e]/10 bg-white/80 p-5 shadow-[inset_0_1px_0_rgba(255,255,255,0.85)] backdrop-blur-sm"
                >
                  <FloatIcon icon={r.icon} delay={0.4 + i * 0.35} />
                  <div className="min-w-0 pt-0.5">
                    <h3 className="font-display text-lg font-bold tracking-tight text-[#0b3d2e]">
                      <T ta={r.ta} en={r.en} />
                    </h3>
                    <p className="mt-1.5 text-sm leading-relaxed text-muted-foreground">
                      <T ta={r.dta} en={r.den} />
                    </p>
                  </div>
                </motion.article>
              ))}
            </div>
          </div>
        </motion.div>

        {/* Membership CTA — single row */}
        <motion.div
          initial={reduce ? false : { opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, amount: 0.3 }}
          transition={{ ...spring, delay: 0.08 }}
          className="mt-10 flex flex-col items-start justify-between gap-6 rounded-[5px] border border-[#0b3d2e]/10 bg-[#0b3d2e] p-7 text-white sm:p-9 md:mt-14 md:flex-row md:items-center"
        >
          <div className="min-w-0 max-w-2xl">
            <h2 className="font-display text-2xl font-extrabold tracking-tighter sm:text-3xl md:text-4xl md:leading-none">
              <T
                ta="எங்களுடன் இணைந்து உறுப்பினராகுங்கள்"
                en="Join us and become a member"
              />
            </h2>
            <p className="mt-3 text-sm leading-relaxed text-white/70 sm:text-base">
              <T
                ta="உறுப்பினர்களுக்கான பிரத்யேக Android App மூலம் உங்கள் மொய் நிகழ்வுகளை எளிதாக நிர்வகிக்கலாம். நேரடி updates, reports மற்றும் event management அனைத்தும் ஒரே app-ல்."
                en="Manage your moi events with the member Android app - live updates, reports, and event management in one place."
              />
            </p>
          </div>
          <Link
            to="/moi-app"
            className="group inline-flex shrink-0 items-center gap-2 rounded-[5px] bg-lime py-2.5 pr-2 pl-5 text-sm font-semibold text-ink transition-colors hover:bg-lime-bright active:scale-[0.98]"
          >
            <T ta="ஆப் பற்றி அறிய" en="About the app" />
            <span className="flex h-8 w-8 items-center justify-center rounded-[5px] bg-ink/10 transition-transform group-hover:translate-x-0.5">
              <HugeiconsIcon icon={ArrowUpRight01Icon} size={16} strokeWidth={1.5} />
            </span>
          </Link>
        </motion.div>
      </div>
    </section>
  );
}
