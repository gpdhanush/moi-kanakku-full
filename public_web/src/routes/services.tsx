"use client";

import { useState } from "react";
import { createFileRoute, Link } from "@tanstack/react-router";
import { HugeiconsIcon } from "@hugeicons/react";
import type { IconSvgElement } from "@hugeicons/react";
import {
  AnalyticsUpIcon,
  ArrowUpRight01Icon,
  BookOpen01Icon,
  CheckListIcon,
  CustomerSupportIcon,
  Database01Icon,
  MonitorIcon,
  ReceiptIcon,
  ReceiptIndianRupeeIcon,
  SmartPhone01Icon,
  ThumbsUpIcon,
  TrophyIcon,
  UserGroupIcon,
} from "@hugeicons/core-free-icons";
import {
  AnimatePresence,
  LayoutGroup,
  motion,
  useMotionValue,
  useReducedMotion,
  useSpring,
  useTransform,
} from "framer-motion";
import { T } from "@/lib/lang";
import { cn } from "@/lib/utils";
import { buildPageHead } from "@/lib/seo";

export const Route = createFileRoute("/services")({
  head: () => {
    const title = "Moi Functions & Gift Services | Moi Kanakku";
    const description =
      "Moi function services: live moi @ computer, moi gift note updates, Moi App, and phone recording. Serving Dindigul, Madurai, Theni and Tamil Nadu.";
    return buildPageHead({ title, description, path: "/services" });
  },
  component: Services,
});

const spring = { type: "spring" as const, stiffness: 120, damping: 18 };

type CoreService = {
  icon: IconSvgElement;
  ta: string;
  en: string;
  dta: string;
  den: string;
  to: "/moi-at-computer" | "/ex-rupees" | "/moi-at-hand" | "/moi-app";
  tone: string;
};

const coreServices: CoreService[] = [
  {
    icon: MonitorIcon,
    ta: "மொய் @ கம்ப்யூட்டர்",
    en: "Moi @ Computer",
    dta: "விழா மேசையில் அனுபவம் உள்ள குழு வந்து கணினி வழியாக மொய் பதிவை நேரடியாகச் செய்வார்கள்.",
    den: "An experienced team visits your function desk and records moi live on a computer.",
    to: "/moi-at-computer",
    tone: "from-[#0b3d2e] to-[#145c44]",
  },
  {
    icon: BookOpen01Icon,
    ta: "பழைய நோட்டு புதுப்பிப்பு",
    en: "Ex Rupees",
    dta: "பழைய மொய் நோட்டுகளை ஊர்வாரியாக அகர வரிசைப்படுத்தி புதிதாக டைப் செய்து நோட்டாகத் தருகிறோம்.",
    den: "Village-wise, alphabetically sorted, freshly typed moi notes from your old books.",
    to: "/ex-rupees",
    tone: "from-[#3f4d1a] to-[#5a6e24]",
  },
  {
    icon: SmartPhone01Icon,
    ta: "மொய் - கையில் / ஆப்",
    en: "Moi at Hand & App",
    dta: "கொடுத்த / பெற்ற மொய் விவரங்களை உங்கள் கைப்பேசியிலேயே பதிவு செய்து மீண்டும் பார்க்கலாம்.",
    den: "Record and review moi given or received right on your phone with Moi Kanakku.",
    to: "/moi-app",
    tone: "from-[#0b3d2e] to-[#1a6b4d]",
  },
];

const coreHighlights = [
  {
    icon: UserGroupIcon,
    ta: "தொழில்முறை பணியாளர்கள்",
    en: "Professional staff",
    dta: "நிகழ்விற்கேற்ப அனுபவம் வாய்ந்த நபர்கள் - உங்கள் நிகழ்வுகளில் நேரடி மேசை அமைப்பு மற்றும் நிர்வாகம்.",
    den: "Experienced people for your event - live desk setup and management on the day.",
    accent: true,
  },
  {
    icon: ReceiptIcon,
    ta: "உடனடி ரசீதுகள்",
    en: "Instant receipts",
    dta: "தற்காலிக பரிமாற்ற ஆதாரம் - விருந்தினர்களுக்கு உடனடி ரசீது வழங்கல் வசதி.",
    den: "Clear proof of every exchange - guests receive a receipt right away.",
    accent: false,
  },
  {
    icon: Database01Icon,
    ta: "டிஜிட்டல் பதிவுகள்",
    en: "Digital records",
    dta: "முழுமையான தகவல் சேமிப்பு - நிகழ்வின் அனைத்து விவரங்களும் டிஜிட்டலாக பதிவாகும்.",
    den: "Complete information storage - every event detail is saved digitally.",
    accent: true,
  },
  {
    icon: CustomerSupportIcon,
    ta: "24/7 ஆதரவு",
    en: "24/7 Support",
    dta: "வாடிக்கையாளர் சேவை எப்போதும் கிடைக்கும்.",
    den: "Customer support is always available.",
    accent: false,
  },
] as const;

const benefits = [
  {
    icon: UserGroupIcon,
    ta: "திறமையான குழு",
    en: "Skilled on-site team",
    dta: "விழாவுக்கு ஏற்ப பயிற்சி பெற்ற நபர்கள் மேசை அமைப்பு மற்றும் பதிவு நிர்வாகத்தைக் கவனிப்பார்கள்.",
    den: "Trained people handle desk setup and live moi management at your event.",
    glass: "border-[#7dd3a8]/45 bg-[linear-gradient(145deg,rgba(220,239,230,0.85),rgba(255,255,255,0.55))]",
    iconBg: "bg-[#0b3d2e]/10 text-[#0b3d2e]",
  },
  {
    icon: ReceiptIndianRupeeIcon,
    ta: "உடனடி ரசீது",
    en: "Instant guest receipts",
    dta: "விருந்தினருக்கு உடனே ரசீது - ஒவ்வொரு தொகைக்கும் தெளிவான ஆதாரம்.",
    den: "Guests get a receipt right away - clear proof for every contribution.",
    glass: "border-[#c4e34a]/50 bg-[linear-gradient(145deg,rgba(236,252,180,0.8),rgba(255,255,255,0.55))]",
    iconBg: "bg-[#3f4d1a]/12 text-[#3f4d1a]",
  },
  {
    icon: CheckListIcon,
    ta: "டிஜிட்டல் பதிவு",
    en: "Full digital records",
    dta: "பெயர், ஊர், தொகை உள்ளிட்ட விழா விவரங்கள் பாதுகாப்பாக டிஜிட்டலாகச் சேமிக்கப்படும்.",
    den: "Names, places, amounts and event details are saved securely in digital form.",
    glass: "border-[#6bb8a0]/45 bg-[linear-gradient(145deg,rgba(200,232,220,0.85),rgba(255,255,255,0.55))]",
    iconBg: "bg-[#145c44]/12 text-[#145c44]",
  },
  {
    icon: CustomerSupportIcon,
    ta: "24/7 ஆதரவு",
    en: "24/7 Support",
    dta: "வாடிக்கையாளர் சேவை எப்போதும் கிடைக்கும்.",
    den: "Customer support is always available.",
    glass: "border-[#8fd4ff]/45 bg-[linear-gradient(145deg,rgba(214,236,255,0.85),rgba(255,255,255,0.55))]",
    iconBg: "bg-[#1a4a6b]/12 text-[#1a4a6b]",
  },
  {
    icon: AnalyticsUpIcon,
    ta: "தொடர் வருமானம்",
    en: "Steady monthly income",
    dta: "மண்டபங்கள் மற்றும் சேவை வழங்குநர்கள் மொய் பதிவைச் சேர்த்து மாத வருவாயை வளர்க்கலாம்.",
    den: "Halls and partners can grow monthly income by offering moi recording.",
    glass: "border-[#f0c14a]/45 bg-[linear-gradient(145deg,rgba(255,243,200,0.85),rgba(255,255,255,0.55))]",
    iconBg: "bg-[#6b541a]/12 text-[#6b541a]",
  },
  {
    icon: ThumbsUpIcon,
    ta: "வாடிக்கையாளர் மனநிறைவு",
    en: "Customer satisfaction",
    dta: "துல்லியமான பதிவும் தெளிவான ரசீதும் வாடிக்கையாளர்களுக்கு நம்பிக்கையையும் சிறந்த அனுபவத்தையும் தரும்.",
    den: "Accurate entries and clear receipts build trust and a smoother guest experience.",
    glass: "border-[#a8d98a]/45 bg-[linear-gradient(145deg,rgba(226,245,210,0.85),rgba(255,255,255,0.55))]",
    iconBg: "bg-[#2d5a1a]/12 text-[#2d5a1a]",
  },
  {
    icon: TrophyIcon,
    ta: "போட்டித்தன்மை",
    en: "Competitive edge",
    dta: "நவீன மொய் பதிவு வசதியுடன் மற்ற விழா இடங்களிலிருந்து வேறுபட்டுத் தெரியுங்கள்.",
    den: "Offer modern moi recording and set your venue apart from nearby options.",
    glass: "border-[#d4a574]/45 bg-[linear-gradient(145deg,rgba(255,232,210,0.85),rgba(255,255,255,0.55))]",
    iconBg: "bg-[#6b3f1a]/12 text-[#6b3f1a]",
  },
] as const;

function TiltBenefit({
  icon,
  ta,
  en,
  dta,
  den,
  glass,
  iconBg,
  index,
}: {
  icon: IconSvgElement;
  ta: string;
  en: string;
  dta: string;
  den: string;
  glass: string;
  iconBg: string;
  index: number;
}) {
  const reduce = useReducedMotion();
  const x = useMotionValue(0);
  const y = useMotionValue(0);
  const sx = useSpring(x, { stiffness: 180, damping: 22 });
  const sy = useSpring(y, { stiffness: 180, damping: 22 });
  const rotateX = useTransform(sy, [-0.5, 0.5], ["6deg", "-6deg"]);
  const rotateY = useTransform(sx, [-0.5, 0.5], ["-6deg", "6deg"]);

  return (
    <motion.div
      initial={reduce ? false : { opacity: 0, scale: 0.94, filter: "blur(6px)" }}
      whileInView={{ opacity: 1, scale: 1, filter: "blur(0px)" }}
      viewport={{ once: true, amount: 0.25 }}
      transition={{ ...spring, delay: index * 0.04 }}
      onMouseMove={(e) => {
        if (reduce) return;
        const r = e.currentTarget.getBoundingClientRect();
        x.set((e.clientX - r.left) / r.width - 0.5);
        y.set((e.clientY - r.top) / r.height - 0.5);
      }}
      onMouseLeave={() => {
        x.set(0);
        y.set(0);
      }}
      style={
        reduce
          ? { transformStyle: "preserve-3d" }
          : { rotateX, rotateY, transformStyle: "preserve-3d" }
      }
      className={cn(
        "h-full rounded-[5px] border p-5 backdrop-blur-md sm:p-6",
        "shadow-[0_8px_28px_-12px_rgba(11,61,46,0.18)]",
        glass,
      )}
    >
      <div className="flex items-center gap-3">
        <span
          className={cn(
            "flex h-10 w-10 shrink-0 items-center justify-center rounded-[5px]",
            iconBg,
          )}
        >
          <HugeiconsIcon icon={icon} size={20} strokeWidth={1.5} />
        </span>
        <h3 className="font-display text-base font-bold tracking-tight text-[#0b3d2e] sm:text-lg">
          <T ta={ta} en={en} />
        </h3>
      </div>
      <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
        <T ta={dta} en={den} />
      </p>
    </motion.div>
  );
}

function Services() {
  const reduce = useReducedMotion();
  const [active, setActive] = useState(0);

  return (
    <div className="bg-[#f3f6f4] text-foreground">
      <section className="overflow-hidden border-b border-[#e5e7eb] bg-white">
        <div className="mx-auto max-w-[1400px] px-4 py-16 sm:px-6 lg:px-8 lg:py-24">
          <motion.div
            initial={reduce ? false : { clipPath: "inset(0 100% 0 0)", opacity: 0.4 }}
            animate={{ clipPath: "inset(0 0% 0 0)", opacity: 1 }}
            transition={{ duration: 0.9, ease: [0.16, 1, 0.3, 1] }}
            className="max-w-3xl"
          >
            <motion.h1
              initial={reduce ? false : { scale: 1.06, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              transition={{ ...spring, delay: 0.15 }}
              className="origin-left font-display text-4xl font-extrabold tracking-tighter text-[#0b3d2e] md:text-5xl lg:text-6xl lg:leading-none"
            >
              <T ta="அனைத்து மொய் சேவைகளும் ஒரே இடத்தில்" en="Every moi service in one place" />
            </motion.h1>
          </motion.div>

          <motion.p
            initial={reduce ? false : { opacity: 0, x: -24 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ ...spring, delay: 0.28 }}
            className="mt-5 max-w-[52ch] text-base leading-relaxed text-muted-foreground"
          >
            <T
              ta="நேரடி விழா பதிவு, பழைய நோட்டு புதுப்பிப்பு, கைபேசி ஆப் மற்றும் கூட்டாண்மை பலன்கள்."
              en="On-site event entry, old note updates, the mobile app, and partnership benefits."
            />
          </motion.p>

          <motion.div
            initial={reduce ? false : { opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ ...spring, delay: 0.4 }}
            className="mt-8"
          >
            <Link
              to="/contact"
              className="group inline-flex items-center gap-2 rounded-[5px] bg-[#0b3d2e] py-2.5 pr-2 pl-5 text-sm font-semibold text-white transition-transform duration-500 ease-[cubic-bezier(0.16,1,0.3,1)] hover:bg-black active:scale-[0.98]"
            >
              <T ta="சேவை முன்பதிவு" en="Book a service" />
              <span className="flex h-8 w-8 items-center justify-center rounded-[5px] bg-white/10 transition-transform duration-500 ease-[cubic-bezier(0.16,1,0.3,1)] group-hover:translate-x-0.5 group-hover:-translate-y-px">
                <HugeiconsIcon icon={ArrowUpRight01Icon} size={16} strokeWidth={1.5} />
              </span>
            </Link>
          </motion.div>
        </div>
      </section>

      <section className="border-b border-[#e5e7eb] bg-[#0b3d2e] py-20 text-white md:py-28">
        <div className="mx-auto max-w-[1400px] px-4 sm:px-6 lg:px-8">
          <motion.h2
            initial={reduce ? false : { opacity: 0, letterSpacing: "0.12em" }}
            whileInView={{ opacity: 1, letterSpacing: "-0.03em" }}
            viewport={{ once: true }}
            transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
            className="font-display text-3xl font-extrabold tracking-tighter md:text-4xl"
          >
            <T ta="முக்கிய சேவைகள்" en="Core services" />
          </motion.h2>
          <p className="mt-3 max-w-[42ch] text-sm text-white/65">
            <T
              ta="ஒரு சேவையைத் தேர்ந்தெடுத்து விரிவாகப் பாருங்கள்."
              en="Select a service to expand details."
            />
          </p>

          <LayoutGroup>
            <div className="mt-10 flex min-h-[340px] flex-col gap-3 md:min-h-[380px] md:flex-row md:gap-3">
              {coreServices.map((s, i) => {
                const open = active === i;
                return (
                  <motion.div
                    key={s.en}
                    layout
                    onClick={() => setActive(i)}
                    onMouseEnter={() => {
                      if (!reduce && window.matchMedia("(hover: hover)").matches) setActive(i);
                    }}
                    className={cn(
                      "relative cursor-pointer overflow-hidden rounded-[5px]",
                      "bg-gradient-to-br",
                      s.tone,
                      open ? "md:flex-[2.2]" : "md:flex-[0.7]",
                    )}
                    transition={spring}
                    style={{ flexGrow: open ? 2.2 : 0.7 }}
                  >
                    <Link
                      to={s.to}
                      className="flex h-full min-h-[120px] flex-col justify-between p-6 md:min-h-[380px] md:p-8"
                      onClick={(e) => {
                        if (!open) {
                          e.preventDefault();
                          setActive(i);
                        }
                      }}
                    >
                      <motion.span
                        layout
                        className="flex h-12 w-12 items-center justify-center rounded-[5px] bg-white/12"
                      >
                        <HugeiconsIcon icon={s.icon} size={24} strokeWidth={1.5} color="currentColor" />
                      </motion.span>

                      <div>
                        <motion.h3
                          layout="position"
                          className={cn(
                            "font-display font-bold tracking-tight",
                            open ? "text-2xl md:text-3xl" : "text-base md:text-lg",
                          )}
                        >
                          <T ta={s.ta} en={s.en} />
                        </motion.h3>

                        <AnimatePresence mode="wait">
                          {open && (
                            <motion.div
                              key="body"
                              initial={reduce ? false : { opacity: 0, y: 12 }}
                              animate={{ opacity: 1, y: 0 }}
                              exit={{ opacity: 0, y: 8 }}
                              transition={{ duration: 0.35, ease: [0.16, 1, 0.3, 1] }}
                            >
                              <p className="mt-3 max-w-md text-sm leading-relaxed text-white/75">
                                <T ta={s.dta} en={s.den} />
                              </p>
                              <span className="mt-5 inline-flex items-center gap-2 text-sm font-semibold text-lime">
                                <T ta="மேலும் பார்க்க" en="Open details" />
                                <HugeiconsIcon icon={ArrowUpRight01Icon} size={16} strokeWidth={1.5} />
                              </span>
                            </motion.div>
                          )}
                        </AnimatePresence>
                      </div>
                    </Link>
                  </motion.div>
                );
              })}
            </div>
          </LayoutGroup>

          <div className="mt-8 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            {coreHighlights.map((h, i) => (
              <motion.article
                key={h.en}
                initial={reduce ? false : { opacity: 0, y: 18 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, amount: 0.3 }}
                transition={{ ...spring, delay: i * 0.05 }}
                className="rounded-[5px] border border-[#e8ece9] border-t-[3px] border-t-lime bg-white p-5 shadow-[0_10px_28px_-16px_rgba(0,0,0,0.35)]"
              >
                <div className="flex items-center gap-3">
                  <span
                    className={cn(
                      "flex h-10 w-10 shrink-0 items-center justify-center rounded-[5px]",
                      h.accent ? "bg-lime text-ink" : "bg-[#eef6e4] text-[#0b3d2e]",
                    )}
                  >
                    <HugeiconsIcon icon={h.icon} size={20} strokeWidth={1.5} />
                  </span>
                  <div className="min-w-0">
                    <h3 className="font-display text-base font-bold tracking-tight text-[#0b3d2e]">
                      <T ta={h.ta} en={h.en} />
                    </h3>
                    <p className="mt-0.5 text-[11px] font-semibold tracking-[0.08em] text-[#5a6e24] uppercase">
                      {h.en}
                    </p>
                  </div>
                </div>
                <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
                  <T ta={h.dta} en={h.den} />
                </p>
              </motion.article>
            ))}
          </div>
        </div>
      </section>

      <section className="relative overflow-hidden py-20 md:py-28">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_20%_0%,rgba(196,227,74,0.18),transparent_50%),radial-gradient(ellipse_at_90%_40%,rgba(125,211,168,0.2),transparent_45%)]"
        />
        <div className="relative mx-auto max-w-[1400px] px-4 sm:px-6 lg:px-8">
          <div className="mb-12 flex flex-col gap-6 md:mb-16 md:flex-row md:items-end md:justify-between">
            <motion.div
              initial={reduce ? false : { opacity: 0, rotate: -2, x: -30 }}
              whileInView={{ opacity: 1, rotate: 0, x: 0 }}
              viewport={{ once: true }}
              transition={spring}
              className="max-w-xl"
            >
              <h2 className="font-display text-3xl font-extrabold tracking-tighter text-[#0b3d2e] md:text-4xl md:leading-none">
                <T ta="ஏன் எங்களுடன்" en="Why work with us" />
              </h2>
              <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
                <T
                  ta="விழா அமைப்பாளர்கள் மற்றும் மண்டபங்களுக்கு தெளிவான பலன்கள்."
                  en="Clear benefits for event hosts and venue partners."
                />
              </p>
            </motion.div>
            <motion.div
              initial={reduce ? false : { opacity: 0, x: 30 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={spring}
            >
              <Link
                to="/contact"
                className="inline-flex rounded-[5px] bg-lime px-5 py-2.5 text-sm font-semibold text-ink transition-colors duration-500 ease-[cubic-bezier(0.16,1,0.3,1)] hover:bg-lime-bright active:scale-[0.98]"
              >
                <T ta="இப்போதே தொடர்பு கொள்ளுங்கள்" en="Contact us now" />
              </Link>
            </motion.div>
          </div>

          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 [perspective:1200px]">
            {benefits.map((b, i) => (
              <TiltBenefit key={b.en} {...b} index={i} />
            ))}
          </div>
        </div>
      </section>
    </div>
  );
}
