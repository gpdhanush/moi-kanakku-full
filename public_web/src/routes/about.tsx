"use client";

import { useRef, type ReactNode } from "react";
import { createFileRoute, Link } from "@tanstack/react-router";
import { HugeiconsIcon } from "@hugeicons/react";
import type { IconSvgElement } from "@hugeicons/react";
import {
  ArrowUpRight01Icon,
  CheckmarkCircle02Icon,
  ComputerIcon,
  File01Icon,
  HeartCheckIcon,
  Message01Icon,
  QuoteUpIcon,
  Shield01Icon,
  SmartPhone01Icon,
  SourceCodeIcon,
  Target02Icon,
  UserGroupIcon,
} from "@hugeicons/core-free-icons";
import {
  motion,
  useMotionValue,
  useReducedMotion,
  useScroll,
  useSpring,
  useTransform,
} from "framer-motion";
import { T } from "@/lib/lang";
import { buildPageHead } from "@/lib/seo";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/about")({
  head: () =>
    buildPageHead({
      title: "About Moi Kanakku | GK Tech மொய் கணக்கு",
      description:
        "Moi Kanakku by GK Tech, built by GNANA PRAKASAM A in Dindigul. Modern digital moi ledger for Tamil family functions.",
      path: "/about",
    }),
  component: About,
});

const spring = { type: "spring" as const, stiffness: 100, damping: 20 };

const mission = [
  {
    icon: Target02Icon,
    ta: "குழப்பமில்லாத, பிழையில்லாத மொய் கணக்கீடு.",
    en: "Clear, error-free moi calculation.",
  },
  {
    icon: Shield01Icon,
    ta: "ஊர்வாரி, குடும்ப வாரி மொய் வரலாற்றை பாதுகாப்பாக சேமித்தல்.",
    en: "Safely storing village-wise and family-wise moi history.",
  },
  {
    icon: HeartCheckIcon,
    ta: "புதிய தலைமுறைக்கு தரவு-சார்ந்த நிலையான மொய் பதிவு முறை.",
    en: "A stable, data-driven moi record method for the next generation.",
  },
] as const;

const process = [
  {
    icon: UserGroupIcon,
    ta: "நிகழ்ச்சிக்கு நேரடியாக tech team வருகை.",
    en: "Direct tech team visit to your event.",
  },
  {
    icon: Message01Icon,
    ta: "மொய் செய்தவுடன் உடனடி ரசீது & SMS.",
    en: "Instant receipt & SMS right after moi is given.",
  },
  {
    icon: File01Icon,
    ta: "நிகழ்ச்சி முடிவில் முழு அறிக்கை - print, PDF, digital backup.",
    en: "Full report at the end - print, PDF, and digital backup.",
  },
] as const;

const pillars = [
  {
    icon: ComputerIcon,
    ta: "மொய் @ கம்ப்யூட்டர்",
    en: "Moi @ Computer",
    dta: "விழா மேசையில் நேரடி பதிவு.",
    den: "Live recording at the function desk.",
  },
  {
    icon: SmartPhone01Icon,
    ta: "மொய் @ கைப்பேசி",
    en: "Moi on mobile",
    dta: "கொடுத்த / பெற்ற மொய் உங்கள் கையில்.",
    den: "Given and received moi in your palm.",
  },
  {
    icon: SourceCodeIcon,
    ta: "GK Tech",
    en: "GK Tech",
    dta: "நம்பகமான டிஜிட்டல் தீர்வுகள்.",
    den: "Reliable digital solutions.",
  },
] as const;

function MagneticCta({
  children,
  className,
}: {
  children: ReactNode;
  className?: string;
}) {
  const reduce = useReducedMotion();
  const x = useMotionValue(0);
  const y = useMotionValue(0);
  const sx = useSpring(x, { stiffness: 200, damping: 18 });
  const sy = useSpring(y, { stiffness: 200, damping: 18 });

  return (
    <motion.div
      style={reduce ? {} : { x: sx, y: sy }}
      onMouseMove={(e) => {
        if (reduce) return;
        const r = e.currentTarget.getBoundingClientRect();
        x.set((e.clientX - r.left - r.width / 2) * 0.22);
        y.set((e.clientY - r.top - r.height / 2) * 0.22);
      }}
      onMouseLeave={() => {
        x.set(0);
        y.set(0);
      }}
      className={className}
    >
      {children}
    </motion.div>
  );
}

function ProcessTrack() {
  const reduce = useReducedMotion();
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start 0.75", "end 0.55"],
  });
  const width = useTransform(scrollYProgress, [0, 1], ["0%", "100%"]);

  return (
    <div ref={ref} className="relative mt-12">
      <div className="pointer-events-none absolute top-[1.375rem] right-0 left-0 hidden h-px md:block">
        <div className="h-full w-full bg-white/12" />
        <motion.div
          className="absolute inset-y-0 left-0 h-full origin-left bg-lime"
          style={reduce ? { width: "100%" } : { width }}
        />
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        {process.map((step, i) => (
          <motion.article
            key={step.en}
            initial={reduce ? false : { opacity: 0, y: 28 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, amount: 0.4 }}
            transition={{ ...spring, delay: i * 0.08 }}
            className="relative rounded-[5px] border border-white/12 bg-white/[0.06] p-6 backdrop-blur-md"
          >
            <span className="flex h-11 w-11 items-center justify-center rounded-[5px] bg-lime text-ink">
              <HugeiconsIcon icon={step.icon} size={22} strokeWidth={1.5} />
            </span>
            <p className="mt-5 text-base leading-relaxed text-white/85">
              <T ta={step.ta} en={step.en} />
            </p>
          </motion.article>
        ))}
      </div>
    </div>
  );
}

function MissionCard({
  icon,
  ta,
  en,
  index,
}: {
  icon: IconSvgElement;
  ta: string;
  en: string;
  index: number;
}) {
  const reduce = useReducedMotion();
  return (
    <motion.li
      initial={reduce ? false : { opacity: 0, x: -20, filter: "blur(6px)" }}
      whileInView={{ opacity: 1, x: 0, filter: "blur(0px)" }}
      viewport={{ once: true, amount: 0.4 }}
      transition={{ ...spring, delay: index * 0.07 }}
      className="flex items-start gap-3 rounded-[5px] border border-[#0b3d2e]/10 bg-white/70 p-4 shadow-[inset_0_1px_0_rgba(255,255,255,0.65)] backdrop-blur-sm"
    >
      <span className="mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-[5px] bg-[#0b3d2e] text-lime">
        <HugeiconsIcon icon={icon} size={18} strokeWidth={1.5} />
      </span>
      <p className="pt-1 text-sm leading-relaxed text-[#0b3d2e]/90 sm:text-base">
        <T ta={ta} en={en} />
      </p>
    </motion.li>
  );
}

function About() {
  const reduce = useReducedMotion();

  return (
    <div className="bg-[#f4f7f5] text-foreground">
      {/* Hero — asymmetric, mask rise (not services clip wipe) */}
      <section className="relative overflow-hidden border-b border-[#e5e7eb] bg-white">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_85%_10%,rgba(144,208,31,0.18),transparent_45%),radial-gradient(ellipse_at_10%_80%,rgba(11,61,46,0.06),transparent_40%)]"
        />
        {!reduce && (
          <motion.div
            aria-hidden
            className="pointer-events-none absolute top-16 right-[12%] h-40 w-40 rounded-full bg-lime/25 blur-3xl"
            animate={{ y: [0, -18, 0], opacity: [0.35, 0.6, 0.35] }}
            transition={{ duration: 7, repeat: Infinity, ease: "easeInOut" }}
          />
        )}

        <div className="relative mx-auto grid max-w-[1400px] gap-12 px-4 py-16 sm:px-6 lg:grid-cols-[1.15fr_0.85fr] lg:px-8 lg:py-24">
          <div>
            <motion.h1
              initial={reduce ? false : { opacity: 0, y: 40 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ ...spring, delay: 0.05 }}
              className="max-w-[16ch] font-display text-4xl font-extrabold tracking-tighter text-[#0b3d2e] md:text-5xl lg:text-6xl lg:leading-[0.95]"
            >
              <T
                ta="நமது கலாச்சாரத்தை நவீன யுகத்திற்கு"
                en="Carrying our culture into the modern era"
              />
            </motion.h1>

            <motion.p
              initial={reduce ? false : { opacity: 0, y: 24 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ ...spring, delay: 0.18 }}
              className="mt-6 max-w-[48ch] text-base leading-relaxed text-muted-foreground"
            >
              <T
                ta="ஒவ்வொரு நிகழ்ச்சியிலும் மொய் பதிவு ஒரு பொறுப்பு. அது தெளிவாக, துல்லியமாக, பாதுகாப்பாக இருக்க வேண்டும் என்ற கனவே இந்த தீர்வு."
                en="Recording moi at every function is a responsibility. This solution was built so it stays clear, accurate and safe."
              />
            </motion.p>

            <motion.div
              initial={reduce ? false : { opacity: 0, scale: 0.94 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ ...spring, delay: 0.3 }}
              className="mt-8 flex flex-wrap items-center gap-3"
            >
              <MagneticCta>
                <Link
                  to="/contact"
                  className="group inline-flex items-center gap-2 rounded-[5px] bg-[#0b3d2e] py-2.5 pr-2 pl-5 text-sm font-semibold text-white transition-colors hover:bg-black active:scale-[0.98]"
                >
                  <T ta="தொடர்புகொள்ள" en="Contact us" />
                  <span className="flex h-8 w-8 items-center justify-center rounded-[5px] bg-white/10 transition-transform group-hover:translate-x-0.5">
                    <HugeiconsIcon icon={ArrowUpRight01Icon} size={16} strokeWidth={1.5} />
                  </span>
                </Link>
              </MagneticCta>
              <Link
                to="/services"
                className="inline-flex items-center rounded-[5px] border border-[#0b3d2e]/15 bg-white px-5 py-2.5 text-sm font-semibold text-[#0b3d2e] transition-colors hover:border-[#0b3d2e] active:scale-[0.98]"
              >
                <T ta="சேவைகளைப் பார்க்க" en="View services" />
              </Link>
            </motion.div>

            <motion.p
              initial={reduce ? false : { opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.45 }}
              className="mt-8 flex items-center gap-2 text-sm text-muted-foreground"
            >
              <span className="flex h-8 w-8 items-center justify-center rounded-[5px] bg-[#eef6e4] text-[#0b3d2e]">
                <HugeiconsIcon icon={SourceCodeIcon} size={16} strokeWidth={1.5} />
              </span>
              <span>
                GK Tech ·{" "}
                <span className="font-semibold text-[#0b3d2e]">GNANA PRAKASAM A</span>
              </span>
            </motion.p>
          </div>

          <motion.aside
            initial={reduce ? false : { opacity: 0, scale: 0.92, rotate: 2 }}
            animate={{ opacity: 1, scale: 1, rotate: 0 }}
            transition={{ ...spring, delay: 0.22 }}
            className="relative flex min-h-[280px] flex-col justify-between overflow-hidden rounded-[5px] bg-[#0b3d2e] p-7 text-white shadow-[0_24px_60px_-28px_rgba(11,61,46,0.55)] sm:p-8"
          >
            <span className="flex h-11 w-11 items-center justify-center rounded-[5px] bg-white/10 text-lime">
              <HugeiconsIcon icon={QuoteUpIcon} size={22} strokeWidth={1.5} />
            </span>
            <blockquote className="mt-8 font-display text-xl font-bold tracking-tight md:text-2xl md:leading-snug">
              <T
                ta="“மொய் செய்வோம்! மொய் பெறுவோம்! நமது கலாச்சாரத்தை காப்போம் நவீன முறையில்.”"
                en="“Let's give moi! Let's receive moi! Let's preserve our culture — the modern way.”"
              />
            </blockquote>
            <div className="mt-8 flex flex-wrap gap-2">
              {["Moi Kanakku", "Clear records", "Family trust"].map((label, i) => (
                <motion.span
                  key={label}
                  animate={
                    reduce
                      ? false
                      : { y: [0, -3, 0], opacity: [0.75, 1, 0.75] }
                  }
                  transition={{
                    duration: 3.2 + i * 0.4,
                    repeat: Infinity,
                    ease: "easeInOut",
                    delay: i * 0.3,
                  }}
                  className="rounded-[5px] border border-white/15 bg-white/8 px-3 py-1 text-xs font-medium text-white/80"
                >
                  {label}
                </motion.span>
              ))}
            </div>
            {!reduce && (
              <motion.div
                aria-hidden
                className="pointer-events-none absolute -right-10 -bottom-10 h-40 w-40 rounded-full bg-lime/30 blur-2xl"
                animate={{ scale: [1, 1.15, 1] }}
                transition={{ duration: 5, repeat: Infinity, ease: "easeInOut" }}
              />
            )}
          </motion.aside>
        </div>
      </section>

      {/* Mission */}
      <section className="relative overflow-hidden py-20 md:py-28">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_0%_50%,rgba(144,208,31,0.12),transparent_40%)]"
        />
        <div className="relative mx-auto grid max-w-[1400px] gap-12 px-4 sm:px-6 lg:grid-cols-2 lg:px-8 lg:gap-16">
          <div>
            <motion.h2
              initial={reduce ? false : { opacity: 0, letterSpacing: "0.08em" }}
              whileInView={{ opacity: 1, letterSpacing: "-0.03em" }}
              viewport={{ once: true }}
              transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
              className="font-display text-3xl font-extrabold tracking-tighter text-[#0b3d2e] md:text-4xl"
            >
              <T ta="எங்கள் நோக்கம்" en="Our mission" />
            </motion.h2>
            <motion.p
              initial={reduce ? false : { opacity: 0, y: 12 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={spring}
              className="mt-4 max-w-[42ch] text-sm leading-relaxed text-muted-foreground"
            >
              <T
                ta="மொய் பதிவை எளிதாக்கி, குடும்பங்களுக்கும் விழா அமைப்பாளர்களுக்கும் நம்பிக்கையைத் தருவதே எங்கள் நோக்கம்."
                en="Our aim is to simplify moi recording and give families and event hosts real confidence."
              />
            </motion.p>

            <ul className="mt-8 space-y-3">
              {mission.map((item, i) => (
                <MissionCard key={item.en} {...item} index={i} />
              ))}
            </ul>
          </div>

          <div className="grid gap-4 sm:grid-cols-1">
            {pillars.map((p, i) => (
              <motion.div
                key={p.en}
                initial={reduce ? false : { opacity: 0, x: 28 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true, amount: 0.35 }}
                transition={{ ...spring, delay: i * 0.08 }}
                className={cn(
                  "flex items-center gap-4 rounded-[5px] border border-[#0b3d2e]/10 p-5",
                  i === 1
                    ? "bg-[#0b3d2e] text-white"
                    : "bg-white/80 text-[#0b3d2e] backdrop-blur-sm",
                )}
              >
                <span
                  className={cn(
                    "flex h-12 w-12 shrink-0 items-center justify-center rounded-[5px]",
                    i === 1 ? "bg-lime text-ink" : "bg-[#eef6e4] text-[#0b3d2e]",
                  )}
                >
                  <HugeiconsIcon icon={p.icon} size={22} strokeWidth={1.5} />
                </span>
                <div className="min-w-0">
                  <h3 className="font-display text-lg font-bold tracking-tight">
                    <T ta={p.ta} en={p.en} />
                  </h3>
                  <p
                    className={cn(
                      "mt-1 text-sm",
                      i === 1 ? "text-white/70" : "text-muted-foreground",
                    )}
                  >
                    <T ta={p.dta} en={p.den} />
                  </p>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Process — scroll-linked track (distinct from services accordion) */}
      <section className="bg-[#0b3d2e] py-20 text-white md:py-28">
        <div className="mx-auto max-w-[1400px] px-4 sm:px-6 lg:px-8">
          <motion.h2
            initial={reduce ? false : { opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={spring}
            className="font-display text-3xl font-extrabold tracking-tighter md:text-4xl"
          >
            <T ta="எங்கள் செயல் முறை" en="Our process" />
          </motion.h2>
          <p className="mt-3 max-w-[46ch] text-sm text-white/65">
            <T
              ta="நமது சேவைகள் — மொய் @ கம்ப்யூட்டர் + மொய் @ கைப்பேசி."
              en="Our services — Moi @ Computer + Moi on mobile."
            />
          </p>
          <ProcessTrack />
        </div>
      </section>

      {/* Values strip */}
      <section className="border-b border-[#e5e7eb] bg-white py-16">
        <div className="mx-auto grid max-w-[1400px] gap-4 px-4 sm:grid-cols-3 sm:px-6 lg:px-8">
          {[
            {
              icon: CheckmarkCircle02Icon,
              ta: "துல்லியம்",
              en: "Accuracy",
              dta: "ஒவ்வொரு தொகைக்கும் தெளிவான பதிவு.",
              den: "A clear record for every amount.",
            },
            {
              icon: Shield01Icon,
              ta: "பாதுகாப்பு",
              en: "Safety",
              dta: "டிஜிட்டல் காப்பு மற்றும் அறிக்கைகள்.",
              den: "Digital backup and full reports.",
            },
            {
              icon: HeartCheckIcon,
              ta: "நம்பிக்கை",
              en: "Trust",
              dta: "குடும்பங்களுக்கான வெளிப்படையான கணக்கு.",
              den: "Transparent accounts for families.",
            },
          ].map((v, i) => (
            <motion.div
              key={v.en}
              initial={reduce ? false : { opacity: 0, y: 16 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ ...spring, delay: i * 0.06 }}
              className="flex items-center gap-3 rounded-[5px] border border-[#e8ece9] bg-[#f9fafb] p-5"
            >
              <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-[5px] bg-[#eef6e4] text-[#0b3d2e]">
                <HugeiconsIcon icon={v.icon} size={20} strokeWidth={1.5} />
              </span>
              <div>
                <h3 className="font-display text-base font-bold text-[#0b3d2e]">
                  <T ta={v.ta} en={v.en} />
                </h3>
                <p className="mt-0.5 text-sm text-muted-foreground">
                  <T ta={v.dta} en={v.den} />
                </p>
              </div>
            </motion.div>
          ))}
        </div>
      </section>

      {/* CTA */}
      <section className="py-20 md:py-24">
        <div className="mx-auto max-w-[1400px] px-4 sm:px-6 lg:px-8">
          <motion.div
            initial={reduce ? false : { opacity: 0, scale: 0.96 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            transition={spring}
            className="flex flex-col items-start justify-between gap-8 overflow-hidden rounded-[5px] bg-[#0b3d2e] px-7 py-10 text-white sm:px-10 md:flex-row md:items-center"
          >
            <div>
              <h2 className="font-display text-3xl font-extrabold tracking-tighter md:text-4xl">
                <T ta="பேசலாமா?" en="Let's talk" />
              </h2>
              <p className="mt-2 max-w-[40ch] text-sm text-white/70">
                <T
                  ta="உங்கள் நிகழ்ச்சி பற்றி எங்களிடம் சொல்லுங்கள்."
                  en="Tell us about your function."
                />
              </p>
            </div>
            <MagneticCta>
              <Link
                to="/contact"
                className="inline-flex items-center gap-2 rounded-[5px] bg-lime px-5 py-3 text-sm font-semibold text-ink transition-colors hover:bg-lime-bright active:scale-[0.98]"
              >
                <T ta="தொடர்புகொள்ள" en="Contact us" />
                <HugeiconsIcon icon={ArrowUpRight01Icon} size={16} strokeWidth={1.5} />
              </Link>
            </MagneticCta>
          </motion.div>
        </div>
      </section>
    </div>
  );
}
