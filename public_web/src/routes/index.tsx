"use client";

import { Link, createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { HugeiconsIcon } from "@hugeicons/react";
import type { IconSvgElement } from "@hugeicons/react";
import {
  ArrowDataTransferHorizontalIcon,
  ArrowLeft01Icon,
  ArrowRight01Icon,
  CalculatorIcon,
  Calendar03Icon,
  File01Icon,
  FolderCheckIcon,
  LanguageCircleIcon,
  NoteIcon,
  PlayIcon,
  Search01Icon,
  Search02Icon,
} from "@hugeicons/core-free-icons";
import {
  AnimatePresence,
  motion,
  useReducedMotion,
} from "framer-motion";
import { T } from "@/lib/lang";
import { DownloadModal, PlayButton } from "@/components/site";
import { FaqAccordion } from "@/components/faq-accordion";
import { WhyChooseBand } from "@/components/why-choose-band";
import { OccasionsHang } from "@/components/occasions-hang";
import { cn } from "@/lib/utils";
import {
  SERVICE_CITIES,
  buildPageHead,
  jsonLdScript,
  webPageSchema,
} from "@/lib/seo";
import weddingImg from "@/assets/home/wedding.webp";
import engagementsImg from "@/assets/home/engagements.webp";
import earImg from "@/assets/home/ear.webp";
import babyShowersImg from "@/assets/home/baby-showers.webp";
import grihapravesamImg from "@/assets/home/grihapravesam.webp";
import otherFamilyOccasionsImg from "@/assets/home/other-family-occasions.webp";
import brandMark from "@/assets/label-dark.png";

export const Route = createFileRoute("/")({
  head: () => {
    const head = buildPageHead({
      title: "Moi Kanakku - Free Digital Moi Ledger | மொய் கணக்கு Moi App",
      description:
        "Moi Kanakku (மொய் கணக்கு): free moi app for moi gift and moi function records. Moi tech for Tamil families in Dindigul, Madurai, Theni, Usilampatti. 100% free, no ads.",
      path: "/",
    });
    return {
      ...head,
      scripts: [
        jsonLdScript(
          webPageSchema({
            path: "/",
            name: "Moi Kanakku - Free Digital Moi Ledger",
            description:
              "Free Android digital moi ledger for Tamil family functions. Record moi given and received.",
          }),
        ),
      ],
    };
  },
  component: Index,
});

const spring = { type: "spring" as const, stiffness: 100, damping: 20 };

const benefits = [
  {
    icon: NoteIcon,
    ta: "எளிய பதிவு",
    en: "Easy Recording",
    dta: "உறவினர் பெயர், ஊர், மொய் தொகை மற்றும் விசேஷ விவரங்களை ஒரே நிமிடத்தில் தெளிவாகப் பதிவு செய்யுங்கள்.",
    den: "Record names, amounts, locations, and celebration details quickly in one easy digital notebook.",
  },
  {
    icon: FolderCheckIcon,
    ta: "ஒழுங்கான கணக்கு",
    en: "Organised Records",
    dta: "ஒவ்வொரு குடும்ப விசேஷத்திற்கும் தனித்தனியாக மொய் கணக்குகளைப் பிரித்து வைக்கலாம்.",
    den: "Keep contributions neatly grouped by family celebrations like weddings and housewarmings.",
  },
  {
    icon: Search02Icon,
    ta: "விரைவான தேடல்",
    en: "Quick Search",
    dta: "பெயர் அல்லது ஊரைத் தட்டச்சு செய்து முந்தைய மொய் விவரங்களை உடனடியாகக் கண்டறியலாம்.",
    den: "Find previous moi entries instantly by searching for a name or location.",
  },
] as const;

const features = [
  {
    icon: ArrowDataTransferHorizontalIcon,
    ta: "கொடுத்தது & பெற்றது",
    en: "Moi Given & Received",
    dta: "நீங்கள் கொடுத்த மொய் மற்றும் பெற்ற மொய் இரண்டையும் தனித்தனியாகப் பதிவு செய்யலாம்.",
    den: "Maintain separate logs for moi given and received.",
  },
  {
    icon: Calendar03Icon,
    ta: "விசேஷ ரீதியான கணக்கு",
    en: "Occasion-wise Records",
    dta: "திருமணம், காதணி, புதுமனை புகுவிழா என ஒவ்வொரு விசேஷத்திற்கும் தனியாகக் கணக்கு.",
    den: "Group entries specifically by celebration type.",
  },
  {
    icon: Search01Icon,
    ta: "பெயர் & தொகையைத் தேடுதல்",
    en: "Name & Amount Search",
    dta: "உறவினரின் பெயர் அல்லது ஊர் பெயரைத் தட்டச்சு செய்து முந்தைய விவரங்களைத் தேடலாம்.",
    den: "Quickly search by relation name or town.",
  },
  {
    icon: CalculatorIcon,
    ta: "மொத்த தொகை கணக்கீடு",
    en: "Event Totals Summary",
    dta: "ஒவ்வொரு விழாவிலும் வசூலான மொத்த மொய் தொகையைத் துல்லியமாகக் காட்டும்.",
    den: "Get instant total calculations automatically.",
  },
  {
    icon: File01Icon,
    ta: "கூடுதல் குறிப்புகள்",
    en: "Notes & Gift Details",
    dta: "பரிசுப் பொருட்கள் அல்லது சிறப்பு நினைவுக் குறிப்புகளையும் எளிதாகச் சேர்க்கலாம்.",
    den: "Add notes for non-cash gifts or gold items.",
  },
  {
    icon: LanguageCircleIcon,
    ta: "தமிழ் & ஆங்கில வசதி",
    en: "Tamil & English Support",
    dta: "செயலியை எளிமையான தமிழ் அல்லது ஆங்கிலத்தில் பயன்படுத்தி மகிழலாம்.",
    den: "Switch the UI between Tamil and English anytime.",
  },
] as const;

const steps = [
  {
    ta: "விசேஷத்தைச் சேருங்கள்",
    en: "Add Your Occasion",
    dta: "உங்கள் வீட்டுத் திருமணம் அல்லது விசேஷத்தின் பெயரையும் தேதியையும் உள்ளிடவும்.",
    den: "Create an event by entering the celebration name and date.",
  },
  {
    ta: "மொய் தொகையைப் பதிவு செய்யுங்கள்",
    en: "Record Names & Amounts",
    dta: "உறவினர் பெயர், ஊர் மற்றும் தந்த மொய் தொகையைத் தட்டச்சு செய்து சேமிக்கவும்.",
    den: "Enter relative names, village or city, and their contribution amount.",
  },
  {
    ta: "தேடிப் பாருங்கள் & PDF பெறுக",
    en: "View & Search Records",
    dta: "எப்போது வேண்டுமானாலும் முந்தைய மொய் விவரங்களைத் தேடலாம் அல்லது PDF அறிக்கையாகப் பெறலாம்.",
    den: "Access past records instantly or export as clean PDF statements.",
  },
] as const;

const occasions: {
  ta: string;
  en: string;
  src: string;
  objectPosition?: string;
}[] = [
  { ta: "திருமணம்", en: "Weddings", src: weddingImg },
  { ta: "நிச்சயதார்த்தம்", en: "Engagements", src: engagementsImg },
  { ta: "காதணி விழா", en: "Ear-piercing", src: earImg },
  { ta: "வளைகாப்பு", en: "Baby Showers", src: babyShowersImg },
  {
    ta: "புதுமனை புகுவிழா",
    en: "Housewarmings",
    src: grihapravesamImg,
    objectPosition: "center 28%",
  },
  { ta: "பிற குடும்ப விழாக்கள்", en: "Other Family Occasions", src: otherFamilyOccasionsImg },
];

const heroSlides = [
  {
    titleTa: "திருமண மொய் நோட்டு",
    titleEn: "Wedding Moi Ledger",
    total: "₹ 2,45,501",
    subTa: "சுந்தர் & அனிதா திருமணம் - மதுரை",
    subEn: "Sundar & Anitha Wedding - Madurai",
    rows: [
      { name: "சுப்பிரமணியன் மாமா", meta: "மதுரை · பெற்ற மொய்", amount: "₹ 10,001", tone: "in" as const },
      { name: "ராஜேந்திரன் & குடும்பம்", meta: "கோவை · பெற்ற மொய்", amount: "₹ 5,005", tone: "in" as const },
      { name: "கார்த்திக் K.", meta: "சென்னை · கொடுத்த மொய்", amount: "₹ 2,001", tone: "out" as const },
    ],
  },
  {
    titleTa: "காதணி விழா மொய்",
    titleEn: "Ear Piercing Moi Ledger",
    total: "₹ 88,000",
    subTa: "செல்வன் கார்த்தி காதணி விழா - திருச்சி",
    subEn: "Karthi Ear Piercing - Trichy",
    rows: [
      { name: "சின்னச்சாமி தாய்மாமன்", meta: "தஞ்சாவூர் · பெற்ற மொய்", amount: "₹ 25,005", tone: "in" as const },
      { name: "வீரமணி & சகோதரர்கள்", meta: "திருச்சி · பெற்ற மொய்", amount: "₹ 10,001", tone: "in" as const },
    ],
  },
  {
    titleTa: "புதுமனை புகுவிழா",
    titleEn: "Housewarming Moi Ledger",
    total: "₹ 65,100",
    subTa: "லக்ஷ்மி இல்லம் - திருநெல்வேலி",
    subEn: "Lakshmi Illam - Tirunelveli",
    rows: [
      { name: "பெருமாள் பெரியப்பா", meta: "நெல்லை · பெற்ற மொய்", amount: "₹ 5,005", tone: "in" as const },
      { name: "செல்வராஜ் நண்பர்கள்", meta: "சென்னை · பெற்ற மொய்", amount: "₹ 3,001", tone: "in" as const },
    ],
  },
] as const;

function HeroPhone() {
  const reduce = useReducedMotion();
  const [slide, setSlide] = useState(0);
  const total = heroSlides.length;

  useEffect(() => {
    if (reduce) return;
    const id = window.setInterval(() => setSlide((s) => (s + 1) % total), 4200);
    return () => window.clearInterval(id);
  }, [total, reduce]);

  const current = heroSlides[slide] ?? heroSlides[0];

  return (
    <div className="relative w-full max-w-[300px] sm:max-w-[320px]">
      <div className="relative overflow-hidden rounded-[5px] border border-[#0b3d2e]/15 bg-white shadow-[0_28px_60px_-28px_rgba(11,61,46,0.45)]">
        <div className="flex items-center justify-between bg-[#0b3d2e] px-3 py-2.5 text-white sm:px-4">
          <div className="flex min-w-0 items-center gap-2">
            <img
              src="/logo.png"
              alt=""
              className="h-7 w-7 shrink-0 rounded-[5px] object-contain"
            />
            <img
              src={brandMark}
              alt="Moi Kanakku"
              className="h-5 w-auto max-w-[140px] object-contain object-left brightness-0 invert sm:h-6"
            />
          </div>
          <span className="shrink-0 text-[10px] font-medium text-white/55">
            {slide + 1}/{total}
          </span>
        </div>

        <div className="relative min-h-[400px] bg-[#f4f7f5] p-4">
          <AnimatePresence mode="wait">
            <motion.div
              key={slide}
              initial={reduce ? false : { opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={reduce ? { opacity: 1, y: 0 } : { opacity: 0, y: -8 }}
              transition={{ duration: 0.35, ease: [0.16, 1, 0.3, 1] }}
              className="space-y-3"
            >
              <div className="rounded-[5px] bg-[#0b3d2e] p-4 text-white">
                <p className="text-[10px] font-semibold tracking-wide text-lime uppercase">
                  <T ta={current.titleTa} en={current.titleEn} />
                </p>
                <p className="mt-1 font-mono text-2xl font-bold tracking-tight">{current.total}</p>
                <p className="mt-1 text-[11px] text-white/65">
                  <T ta={current.subTa} en={current.subEn} />
                </p>
              </div>
              <div className="space-y-2">
                {current.rows.map((row) => (
                  <div
                    key={row.name}
                    className="flex items-center justify-between rounded-[5px] border border-[#0b3d2e]/8 bg-white p-2.5"
                  >
                    <div className="min-w-0">
                      <p className="truncate text-xs font-bold text-[#0b3d2e]">{row.name}</p>
                      <p className="text-[10px] text-muted-foreground">{row.meta}</p>
                    </div>
                    <span
                      className={cn(
                        "shrink-0 rounded-[5px] px-2 py-1 text-xs font-bold",
                        row.tone === "in"
                          ? "bg-[#e8f6ee] text-[#0b3d2e]"
                          : "bg-[#fce8e8] text-rose-700",
                      )}
                    >
                      {row.amount}
                    </span>
                  </div>
                ))}
              </div>
            </motion.div>
          </AnimatePresence>
        </div>

        <div className="flex items-center justify-between border-t border-[#0b3d2e]/10 bg-white px-3 py-2.5">
          <button
            type="button"
            onClick={() => setSlide((s) => (s - 1 + total) % total)}
            className="flex h-8 w-8 items-center justify-center rounded-[5px] bg-[#f4f7f5] text-[#0b3d2e] transition-colors hover:bg-[#eef6e4] active:scale-[0.96]"
            aria-label="Previous slide"
          >
            <HugeiconsIcon icon={ArrowLeft01Icon} size={16} strokeWidth={1.5} />
          </button>
          <div className="flex gap-1.5">
            {heroSlides.map((_, i) => (
              <button
                key={i}
                type="button"
                onClick={() => setSlide(i)}
                aria-label={`Go to slide ${i + 1}`}
                className={cn(
                  "h-1.5 rounded-full transition-all",
                  i === slide ? "w-5 bg-[#0b3d2e]" : "w-1.5 bg-[#0b3d2e]/25",
                )}
              />
            ))}
          </div>
          <button
            type="button"
            onClick={() => setSlide((s) => (s + 1) % total)}
            className="flex h-8 w-8 items-center justify-center rounded-[5px] bg-[#f4f7f5] text-[#0b3d2e] transition-colors hover:bg-[#eef6e4] active:scale-[0.96]"
            aria-label="Next slide"
          >
            <HugeiconsIcon icon={ArrowRight01Icon} size={16} strokeWidth={1.5} />
          </button>
        </div>
      </div>
    </div>
  );
}

function FeatureRow({
  icon,
  ta,
  en,
  dta,
  den,
  index,
}: {
  icon: IconSvgElement;
  ta: string;
  en: string;
  dta: string;
  den: string;
  index: number;
}) {
  const reduce = useReducedMotion();
  return (
    <motion.li
      initial={reduce ? false : { opacity: 0, y: 16 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, amount: 0.3 }}
      transition={{ ...spring, delay: index * 0.04 }}
      className="flex items-start gap-3 border-t border-[#0b3d2e]/10 py-5 first:border-t-0 first:pt-0"
    >
      <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-[5px] bg-[#eef6e4] text-[#0b3d2e]">
        <HugeiconsIcon icon={icon} size={20} strokeWidth={1.5} />
      </span>
      <div className="min-w-0">
        <h3 className="font-display text-base font-bold tracking-tight text-[#0b3d2e]">
          <T ta={ta} en={en} />
        </h3>
        <p className="mt-1 text-sm leading-relaxed text-muted-foreground">
          <T ta={dta} en={den} />
        </p>
      </div>
    </motion.li>
  );
}

function Index() {
  const reduce = useReducedMotion();
  const [modalOpen, setModalOpen] = useState(false);

  return (
    <div className="bg-[#f4f7f5] text-foreground">
      {/* Full-bleed celebration hero */}
      <section id="home" className="relative min-h-[100dvh] overflow-hidden">
        <img
          src={weddingImg}
          alt=""
          className="absolute inset-0 h-full w-full object-cover object-[center_28%]"
          fetchPriority="high"
        />
        <div
          aria-hidden
          className="absolute inset-0 bg-[linear-gradient(105deg,rgba(11,61,46,0.92)_0%,rgba(11,61,46,0.72)_48%,rgba(11,61,46,0.35)_100%)]"
        />
        <div
          aria-hidden
          className="absolute inset-0 bg-[radial-gradient(ellipse_at_80%_20%,rgba(144,208,31,0.18),transparent_45%)]"
        />

        <div className="relative mx-auto grid min-h-[100dvh] max-w-[1400px] items-start gap-8 px-4 pt-8 pb-14 sm:px-6 md:items-center md:gap-10 md:py-16 lg:grid-cols-12 lg:gap-8 lg:px-8 lg:py-20">
          {/* Mobile-first logo at top */}
          <motion.div
            initial={reduce ? false : { opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={spring}
            className="lg:col-span-12"
          >
            <img
              src={brandMark}
              alt="moi kanakku"
              className="h-10 w-auto brightness-0 invert sm:h-11 md:h-12"
            />
          </motion.div>

          <div className="lg:col-span-7">
            <motion.h1
              initial={reduce ? false : { opacity: 0, y: 28 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ ...spring, delay: 0.08 }}
              className="max-w-[14ch] font-display text-4xl font-extrabold tracking-tighter text-white sm:text-5xl lg:text-6xl lg:leading-[0.95]"
            >
              <T
                ta="மொய் கணக்கு இனி உங்கள் கையில்!"
                en="Your family's moi records, in your palm."
              />
            </motion.h1>

            <motion.p
              initial={reduce ? false : { opacity: 0, y: 18 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ ...spring, delay: 0.16 }}
              className="mt-5 max-w-[40ch] text-base leading-relaxed text-white/75"
            >
              <T
                ta="கொடுத்த மொய், பெற்ற மொய் மற்றும் விழா விவரங்களை எளிதாகப் பதிவு செய்து நிர்வகியுங்கள்."
                en="Record moi given and received, organise family occasions, and find past entries fast."
              />
            </motion.p>

            <motion.div
              initial={reduce ? false : { opacity: 0, y: 14 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ ...spring, delay: 0.24 }}
              className="mt-8"
            >
              <button
                type="button"
                onClick={() => setModalOpen(true)}
                className="inline-flex w-full items-center justify-center gap-3 rounded-[5px] bg-lime px-5 py-3.5 text-sm font-bold text-ink transition-colors hover:bg-lime-bright active:scale-[0.98] sm:w-auto"
              >
                <HugeiconsIcon icon={PlayIcon} size={20} strokeWidth={1.5} />
                <span className="text-left leading-tight">
                  <span className="block text-[10px] font-medium tracking-wide text-ink/55 uppercase">
                    Google Play
                  </span>
                  <span className="block">
                    <T ta="செயலியைப் பதிவிறக்குங்கள்" en="Download app" />
                  </span>
                </span>
              </button>
            </motion.div>
          </div>

          <motion.div
            initial={reduce ? false : { opacity: 0, y: 24, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            transition={{ ...spring, delay: 0.2 }}
            className="flex justify-center lg:col-span-5 lg:justify-end"
          >
            <HeroPhone />
          </motion.div>
        </div>
      </section>

      {/* Trust strip under hero */}
      <section className="border-b border-[#e5e7eb] bg-white">
        <div className="mx-auto grid max-w-[1400px] grid-cols-1 gap-px bg-[#e5e7eb] sm:grid-cols-3">
          {[
            {
              k: "Android 7.0+",
              ta: "அனைத்து Android போன்களுக்கும்",
              en: "Compatible phones",
            },
            {
              k: "100% Free",
              ta: "விளம்பரம் / சந்தா இல்லை",
              en: "No ads or subscriptions",
            },
            {
              k: "Cloud sync",
              ta: "கிளவுட் சேமிப்பு",
              en: "Secure online backup",
            },
          ].map((item, i) => (
            <motion.div
              key={item.k}
              initial={reduce ? false : { opacity: 0, y: 10 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ ...spring, delay: i * 0.05 }}
              className="bg-white px-6 py-5 sm:px-8"
            >
              <p className="font-display text-lg font-bold tracking-tight text-[#0b3d2e]">{item.k}</p>
              <p className="mt-1 text-sm text-muted-foreground">
                <T ta={item.ta} en={item.en} />
              </p>
            </motion.div>
          ))}
        </div>
      </section>

      {/* Benefits — asymmetric, not 3 equal cards */}
      <section id="benefits" className="py-16 md:py-24">
        <div className="mx-auto max-w-[1400px] px-4 sm:px-6 lg:px-8">
          <motion.h2
            initial={reduce ? false : { opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={spring}
            className="max-w-[22ch] font-display text-3xl font-extrabold tracking-tighter text-[#0b3d2e] md:text-4xl"
          >
            <T
              ta="விழாவை மகிழ்ச்சியாகக் கொண்டாடுங்கள். கணக்கை எளிதாக வைத்திருங்கள்."
              en="Enjoy the celebration. Keep the records organised."
            />
          </motion.h2>

          <div className="mt-10 grid gap-4 md:grid-cols-[1.3fr_1fr]">
            <motion.article
              initial={reduce ? false : { opacity: 0, x: -16 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={spring}
              className="flex min-h-[220px] flex-col justify-between rounded-[5px] border border-[#0b3d2e]/10 bg-[#0b3d2e] p-7 text-white"
            >
              <span className="flex h-12 w-12 items-center justify-center rounded-[5px] bg-lime text-ink">
                <HugeiconsIcon icon={benefits[0].icon} size={22} strokeWidth={1.5} />
              </span>
              <div className="mt-10">
                <h3 className="font-display text-2xl font-bold tracking-tight">
                  <T ta={benefits[0].ta} en={benefits[0].en} />
                </h3>
                <p className="mt-2 max-w-[40ch] text-sm leading-relaxed text-white/70">
                  <T ta={benefits[0].dta} en={benefits[0].den} />
                </p>
              </div>
            </motion.article>

            <div className="grid gap-4">
              {benefits.slice(1).map((b, i) => (
                <motion.article
                  key={b.en}
                  initial={reduce ? false : { opacity: 0, x: 16 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true }}
                  transition={{ ...spring, delay: 0.06 + i * 0.06 }}
                  className="flex items-start gap-4 rounded-[5px] border border-[#0b3d2e]/10 bg-white p-5"
                >
                  <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-[5px] bg-[#eef6e4] text-[#0b3d2e]">
                    <HugeiconsIcon icon={b.icon} size={20} strokeWidth={1.5} />
                  </span>
                  <div>
                    <h3 className="font-display text-lg font-bold tracking-tight text-[#0b3d2e]">
                      <T ta={b.ta} en={b.en} />
                    </h3>
                    <p className="mt-1.5 text-sm leading-relaxed text-muted-foreground">
                      <T ta={b.dta} en={b.den} />
                    </p>
                  </div>
                </motion.article>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* Features — split list, not card grid */}
      <section id="features" className="border-y border-[#e5e7eb] bg-white py-16 md:py-24">
        <div className="mx-auto grid max-w-[1400px] gap-10 px-4 sm:px-6 lg:grid-cols-[0.9fr_1.1fr] lg:gap-16 lg:px-8">
          <div>
            <motion.h2
              initial={reduce ? false : { opacity: 0, y: 16 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={spring}
              className="max-w-[18ch] font-display text-3xl font-extrabold tracking-tighter text-[#0b3d2e] md:text-4xl"
            >
              <T
                ta="உங்கள் மொய் கணக்கிற்கு தேவையான அனைத்து வசதிகளும்"
                en="Everything you need for family moi records."
              />
            </motion.h2>
            <p className="mt-4 max-w-[40ch] text-sm leading-relaxed text-muted-foreground">
              <T
                ta="கொடுத்தது, பெற்றது, தேடல், மொத்தம் - அனைத்தும் ஒரே செயலியில்."
                en="Given, received, search, and totals - all in one Android app."
              />
            </p>
          </div>
          <ul>
            {features.map((f, i) => (
              <FeatureRow key={f.en} {...f} index={i} />
            ))}
          </ul>
        </div>
      </section>

      {/* How it works — numbered track, not equal cards */}
      <section id="how-it-works" className="bg-[#0b3d2e] py-16 text-white md:py-24">
        <div className="mx-auto max-w-[1400px] px-4 sm:px-6 lg:px-8">
          <motion.h2
            initial={reduce ? false : { opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={spring}
            className="max-w-[20ch] font-display text-3xl font-extrabold tracking-tighter md:text-4xl"
          >
            <T ta="மூன்று எளிய படிகளில் தொடங்குங்கள்" en="Get started in three simple steps." />
          </motion.h2>

          <ol className="mt-12 grid gap-6 md:grid-cols-3 md:gap-0">
            {steps.map((s, i) => (
              <motion.li
                key={s.en}
                initial={reduce ? false : { opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ ...spring, delay: i * 0.08 }}
                className={cn(
                  "relative md:px-6",
                  i > 0 && "md:border-l md:border-white/15",
                  i === 0 && "md:pl-0",
                  i === steps.length - 1 && "md:pr-0",
                )}
              >
                <h3 className="font-display text-xl font-bold tracking-tight">
                  <T ta={s.ta} en={s.en} />
                </h3>
                <p className="mt-2 text-sm leading-relaxed text-white/65">
                  <T ta={s.dta} en={s.den} />
                </p>
              </motion.li>
            ))}
          </ol>
        </div>
      </section>

      {/* Occasions — sticky hanging / lag stack */}
      <section id="occasions" className="bg-[#0f1f18] pt-16 pb-8 md:pt-24 md:pb-12">
        <div className="mx-auto max-w-[1400px] px-4 sm:px-6 lg:px-8">
          <motion.h2
            initial={reduce ? false : { opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={spring}
            className="sticky top-[4.5rem] z-30 mb-6 max-w-[18ch] bg-[#0f1f18]/90 pb-4 font-display text-3xl font-extrabold tracking-tighter text-white backdrop-blur-md md:top-20 md:mb-8 md:text-5xl md:leading-none"
          >
            <T ta="ஒவ்வொரு குடும்ப விசேஷத்திற்கும் ஏற்றது" en="For every family celebration." />
          </motion.h2>
          <OccasionsHang items={occasions} />
        </div>
      </section>

      {/* Local SEO internal links */}
      <section className="border-t border-[#0b3d2e]/08 bg-white py-14 md:py-18">
        <div className="mx-auto max-w-[1400px] px-4 sm:px-6 lg:px-8">
          <h2 className="max-w-[22ch] font-display text-2xl font-extrabold tracking-tighter text-[#0b3d2e] sm:text-3xl">
            <T
              ta="திண்டுக்கல் முதல் தமிழ்நாடு வரை மொய் சேவை"
              en="Moi service from Dindigul across Tamil Nadu"
            />
          </h2>
          <p className="mt-3 max-w-[58ch] text-sm leading-relaxed text-[#0b3d2e]/70">
            <T
              ta="மொய், மொய் டெக், மொய் பரிசு, மொய் விழா என தேடுபவர்களுக்கு. மதுரை, தேனி, உசிலம்பட்டி மற்றும் பிற நகரங்களுக்கான உள்ளூர் பக்கங்கள்."
              en="For searches like moi, moi tech, moi gift and moi functions. Local pages for Madurai, Theni, Usilampatti and more."
            />
          </p>
          <ul className="mt-6 flex flex-wrap gap-2">
            {SERVICE_CITIES.map((city) => (
              <li key={city.slug}>
                <Link
                  to="/locations/$city"
                  params={{ city: city.slug }}
                  className="inline-flex rounded-[5px] border border-[#0b3d2e]/12 bg-[#f7faf8] px-3 py-1.5 text-sm font-medium text-[#0b3d2e] transition-colors hover:bg-[#eef6e4]"
                >
                  <T ta={`மொய் ${city.nameTa}`} en={`Moi ${city.nameEn}`} />
                </Link>
              </li>
            ))}
            <li>
              <Link
                to="/locations"
                className="inline-flex rounded-[5px] bg-[#0b3d2e] px-3 py-1.5 text-sm font-semibold text-white hover:bg-black"
              >
                <T ta="அனைத்து இடங்கள்" en="All locations" />
              </Link>
            </li>
          </ul>
        </div>
      </section>

      <FaqAccordion className="border-[#e5e7eb] bg-white" />

      <WhyChooseBand />

      {/* Final CTA — split, one download intent */}
      <section className="border-t border-[#e5e7eb] bg-white py-16 md:py-20">
        <div className="mx-auto max-w-[1400px] px-4 sm:px-6 lg:px-8">
          <motion.div
            initial={reduce ? false : { opacity: 0, y: 18 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={spring}
            className="flex flex-col items-start justify-between gap-8 rounded-[5px] bg-[#0b3d2e] px-7 py-10 text-white sm:px-10 md:flex-row md:items-center"
          >
            <div>
              <h2 className="max-w-[18ch] font-display text-3xl font-extrabold tracking-tighter md:text-4xl">
                <T
                  ta="உங்கள் அடுத்த விழாவிற்கு தயாராகுங்கள்!"
                  en="Ready for your next celebration?"
                />
              </h2>
              <p className="mt-3 max-w-[42ch] text-sm text-white/70">
                <T
                  ta="Google Play Store இலிருந்து Moi Kanakku செயலியை இலவசமாகப் பதிவிறக்கி உங்கள் மொய் பதிவுகளை நிர்வகிக்கவும்."
                  en="Download free Moi Kanakku from Google Play. No ads, no subscriptions."
                />
              </p>
            </div>
            <PlayButton />
          </motion.div>
        </div>
      </section>

      <DownloadModal open={modalOpen} onClose={() => setModalOpen(false)} />
    </div>
  );
}
