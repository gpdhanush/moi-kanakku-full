"use client";

import { memo, useEffect, useState } from "react";
import { createFileRoute, Link } from "@tanstack/react-router";
import {
  ArrowUpRight,
  Bell,
  Download,
  FileSpreadsheet,
  Lock,
  MessageSquareText,
  Mic,
  PenLine,
  Search,
  Share2,
  Smartphone,
  UserRound,
  Wallet,
} from "lucide-react";
import { AnimatePresence, motion, useReducedMotion, type Variants } from "framer-motion";
import { T } from "@/lib/lang";
import { PlayButton } from "@/components/site";
import { cn } from "@/lib/utils";
import {
  breadcrumbSchema,
  buildPageHead,
  jsonLdScript,
  softwareAppSchema,
  webPageSchema,
} from "@/lib/seo";

export const Route = createFileRoute("/moi-app")({
  head: () => {
    const title = "Moi App - Free Android Moi Kanakku | மொய் கணக்கு ஆப்";
    const description =
      "Download Moi Kanakku moi app (moi tech): record moi gifts, guests and functions, export Excel. Free on Google Play. No ads, no subscription.";
    const head = buildPageHead({ title, description, path: "/moi-app" });
    return {
      ...head,
      scripts: [
        jsonLdScript([
          softwareAppSchema(),
          webPageSchema({ path: "/moi-app", name: title, description }),
          breadcrumbSchema([
            { name: "Home", path: "/" },
            { name: "Moi App", path: "/moi-app" },
          ]),
        ]),
      ],
    };
  },
  component: Page,
});

const spring = { type: "spring" as const, stiffness: 100, damping: 20 };
const easeOut = [0.32, 0.72, 0, 1] as const;

function greetingByTime() {
  const hour = new Date().getHours();
  if (hour < 12) {
    return { ta: "காலை வணக்கம்", en: "Good morning" };
  }
  if (hour < 17) {
    return { ta: "மதிய வணக்கம்", en: "Good afternoon" };
  }
  return { ta: "மாலை வணக்கம்", en: "Good evening" };
}

/* ---------- Isolated perpetual motion surfaces ---------- */

const HomeSurface = memo(function HomeSurface() {
  const reduce = useReducedMotion();
  const greeting = greetingByTime();
  return (
    <div className="flex h-full flex-col gap-3 rounded-[1.75rem] bg-white p-5 sm:p-6">
      <div className="flex items-center justify-between">
        <div>
          <span className="inline-flex rounded-full bg-[#dcefe6] px-2.5 py-0.5 text-[10px] font-semibold text-[#0b3d2e]">
            <T ta={greeting.ta} en={greeting.en} />
          </span>
          <p className="mt-2 font-display text-lg font-bold tracking-tight text-[#0b3d2e]">
            RENZO ROWAN G.K
          </p>
        </div>
        <span className="flex h-10 w-10 items-center justify-center rounded-full bg-[#dcefe6] text-[#0b3d2e]">
          <Bell className="h-4 w-4" strokeWidth={1.5} />
        </span>
      </div>

      <motion.div
        className="relative overflow-hidden rounded-2xl bg-[#0b3d2e] p-5 text-white"
        animate={reduce ? false : { scale: [1, 1.01, 1] }}
        transition={{ duration: 3.2, repeat: Infinity, ease: easeOut }}
      >
        <p className="text-xs font-medium text-[#9fd4b8]">
          <T ta="நிகர இருப்பு" en="Net Balance" />
        </p>
        <p className="mt-1 font-mono text-3xl font-bold tracking-tight">₹ 4,500.00</p>
        <div className="mt-4 flex items-center justify-between border-t border-white/15 pt-3 text-xs text-white/70">
          <T ta="அனைத்து பரிவர்த்தனைகள்" en="View all transactions" />
          <span className="flex h-6 w-6 items-center justify-center rounded-full bg-white/10">
            <ArrowUpRight className="h-3.5 w-3.5" strokeWidth={1.5} />
          </span>
        </div>
      </motion.div>

      <div className="grid grid-cols-2 gap-2.5">
        <div className="rounded-xl bg-[#d8f0e4] p-3">
          <p className="text-[11px] font-medium text-[#0b3d2e]/70">
            <T ta="பெற்ற மொய்" en="Moi Received" />
          </p>
          <p className="mt-1 font-mono text-sm font-bold text-[#0b3d2e]">₹ 5,000.00</p>
        </div>
        <div className="rounded-xl bg-[#fce8e8] p-3">
          <p className="text-[11px] font-medium text-rose-700/70">
            <T ta="கொடுத்த மொய்" en="Moi Given" />
          </p>
          <p className="mt-1 font-mono text-sm font-bold text-rose-700">₹ 500.00</p>
        </div>
      </div>
    </div>
  );
});

const OverviewSurface = memo(function OverviewSurface() {
  const reduce = useReducedMotion();
  const people = [
    { id: "1", name: "GNANA PRAKASAM A", meta: "DINDIGUL · 9876543210" },
    { id: "2", name: "KIRUBA THEPORAL J", meta: "DINDIGUL · 9876543211" },
    { id: "3", name: "ANITA S", meta: "CHENNAI · 9876543211" },
  ];
  const [order, setOrder] = useState(people.map((p) => p.id));

  useEffect(() => {
    if (reduce) return;
    const id = window.setInterval(() => {
      setOrder((prev) => {
        const next = [...prev];
        const a = next.pop();
        if (a) next.unshift(a);
        return next;
      });
    }, 2600);
    return () => window.clearInterval(id);
  }, [reduce]);

  const byId = Object.fromEntries(people.map((p) => [p.id, p]));

  return (
    <div className="flex h-full flex-col gap-3 rounded-[1.75rem] bg-white p-5 sm:p-6">
      <div className="flex items-center gap-2 rounded-full border border-[#d7ebe2] bg-[#f9fafb] px-3 py-2.5">
        <Search className="h-4 w-4 text-[#0b3d2e]/50" strokeWidth={1.5} />
        <TypewriterPlaceholder />
        <Mic className="ml-auto h-4 w-4 text-[#0b3d2e]" strokeWidth={1.5} />
      </div>

      <div className="grid grid-cols-2 gap-2">
        <button
          type="button"
          className="rounded-xl bg-[#0b3d2e] px-3 py-2.5 text-left text-[11px] font-semibold text-white active:scale-[0.98]"
        >
          <T ta="புதிய மொய் பெற்றது" en="New Moi Received" />
        </button>
        <button
          type="button"
          className="rounded-xl bg-rose-700 px-3 py-2.5 text-left text-[11px] font-semibold text-white active:scale-[0.98]"
        >
          <T ta="புதிய மொய் கொடுத்தது" en="New Moi Given" />
        </button>
      </div>

      <div className="flex flex-1 flex-col gap-2">
        <AnimatePresence initial={false}>
          {order.map((id) => {
            const p = byId[id]!;
            return (
              <motion.div
                key={p.id}
                layout={!reduce}
                className="flex items-center gap-3 rounded-xl border border-[#e8f2ec] bg-[#f9fafb] px-3 py-2.5"
              >
                <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-[#dcefe6] text-[#0b3d2e]">
                  <UserRound className="h-4 w-4" strokeWidth={1.5} />
                </span>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-bold text-[#0b3d2e]">{p.name}</p>
                  <p className="truncate text-[10px] text-muted-foreground">{p.meta}</p>
                </div>
              </motion.div>
            );
          })}
        </AnimatePresence>
      </div>
    </div>
  );
});

const TypewriterPlaceholder = memo(function TypewriterPlaceholder() {
  const reduce = useReducedMotion();
  const phrases = ["Search persons...", "DINDIGUL...", "GNANA PRAKASAM A..."];
  const [i, setI] = useState(0);
  const [text, setText] = useState("");

  useEffect(() => {
    if (reduce) {
      setText(phrases[0]!);
      return;
    }
    const phrase = phrases[i % phrases.length]!;
    let pos = 0;
    let deleting = false;
    const tick = window.setInterval(
      () => {
        if (!deleting) {
          pos += 1;
          setText(phrase.slice(0, pos));
          if (pos >= phrase.length) deleting = true;
        } else {
          pos -= 1;
          setText(phrase.slice(0, pos));
          if (pos <= 0) {
            deleting = false;
            setI((v) => v + 1);
          }
        }
      },
      deleting ? 40 : 70,
    );
    return () => window.clearInterval(tick);
  }, [i, reduce]);

  return (
    <span className="flex-1 truncate text-xs text-muted-foreground">
      {text}
      <motion.span
        className="ml-0.5 inline-block h-3 w-px bg-[#0b3d2e] align-middle"
        animate={reduce ? false : { opacity: [1, 0, 1] }}
        transition={{ duration: 0.9, repeat: Infinity }}
      />
    </span>
  );
});

const FeedbackSurface = memo(function FeedbackSurface() {
  const reduce = useReducedMotion();
  const [showBadge, setShowBadge] = useState(true);

  useEffect(() => {
    if (reduce) return;
    const id = window.setInterval(() => setShowBadge((v) => !v), 3400);
    return () => window.clearInterval(id);
  }, [reduce]);

  return (
    <div className="relative flex h-full flex-col gap-3 rounded-[1.75rem] bg-white p-5 sm:p-6">
      <div className="flex items-center gap-3 rounded-2xl bg-[#0b3d2e] p-4 text-white">
        <span className="flex h-10 w-10 items-center justify-center rounded-lg bg-white/10">
          <MessageSquareText className="h-5 w-5" strokeWidth={1.5} />
        </span>
        <div>
          <p className="text-sm font-bold">
            <T ta="புதிய கருத்து" en="New Feedback" />
          </p>
          <p className="text-[11px] text-white/65">
            <T ta="உங்கள் கருத்தைப் பகிரவும்" en="Share your feedback" />
          </p>
        </div>
      </div>

      <div className="rounded-xl border border-[#e8f2ec] bg-[#f9fafb] p-3">
        <p className="text-xs font-semibold text-[#0b3d2e]">
          <T ta="உங்கள் கருத்து" en="Your Feedback" />
        </p>
        <p className="mt-2 rounded-lg bg-[#dcefe6] px-3 py-2 text-sm text-[#0b3d2e]">
          <T ta="ஆப் மிகவும் எளிது" en="The app is very easy to use" />
        </p>
      </div>

      <AnimatePresence>
        {showBadge && (
          <motion.div
            initial={reduce ? false : { opacity: 0, y: 10, scale: 0.94 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -8, scale: 0.96 }}
            transition={spring}
            className="mt-auto flex items-center gap-2 rounded-xl bg-[#fff1e6] px-3 py-2.5"
          >
            <span className="rounded-full bg-[#ffd9b8] px-2 py-0.5 text-[10px] font-bold text-[#9a4b00]">
              <T ta="நிலுவை" en="Pending" />
            </span>
            <p className="text-[11px] font-medium text-[#9a4b00]">
              <T ta="விரைவில் பதில் வரும்" en="A reply will be provided soon" />
            </p>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
});

const MoreSurface = memo(function MoreSurface() {
  const reduce = useReducedMotion();
  const items = [
    {
      icon: Wallet,
      ta: "வரவிருக்கும் விழாக்கள்",
      en: "Upcoming Functions",
      tone: "bg-[#dcefe6] text-[#0b3d2e]",
    },
    { icon: UserRound, ta: "சுயவிவரம்", en: "Profile", tone: "bg-[#dcefe6] text-[#0b3d2e]" },
    { icon: FileSpreadsheet, ta: "ஏற்றுமதி", en: "Export", tone: "bg-[#e8e4f5] text-[#4c3d7a]" },
    { icon: Lock, ta: "ஆப் பூட்டு", en: "App Lock", tone: "bg-[#dcefe6] text-[#0b3d2e]" },
  ];

  return (
    <div className="flex h-full flex-col justify-center gap-2.5 rounded-[1.75rem] bg-white p-5 sm:p-6">
      {items.map((item, i) => (
        <motion.div
          key={item.en}
          initial={false}
          animate={reduce ? false : { x: [0, 3, 0] }}
          transition={{ duration: 2.8, delay: i * 0.35, repeat: Infinity, ease: easeOut }}
          className="flex items-center gap-3 rounded-xl border border-[#e8f2ec] bg-[#f9fafb] px-3 py-2.5"
        >
          <span className={cn("flex h-9 w-9 items-center justify-center rounded-lg", item.tone)}>
            <item.icon className="h-4 w-4" strokeWidth={1.5} />
          </span>
          <p className="text-sm font-semibold text-[#0b3d2e]">
            <T ta={item.ta} en={item.en} />
          </p>
        </motion.div>
      ))}
    </div>
  );
});

const featureBlocks = [
  {
    id: "home",
    icon: Wallet,
    titleTa: "முகப்பு",
    titleEn: "Home",
    bodyTa: "நிகர இருப்பு, பெற்ற / கொடுத்த மொய் மற்றும் விழா வாரியான மொத்தம் ஒரே பார்வையில்.",
    bodyEn: "Net balance, moi received / given, and function-wise totals in one view.",
    Surface: HomeSurface,
  },
  {
    id: "overview",
    icon: Search,
    titleTa: "கண்ணோட்டம்",
    titleEn: "Overview",
    bodyTa: "நபர்களைத் தேடி புதிய மொய் பெற்றது அல்லது கொடுத்தது பதிவு செய்யுங்கள்.",
    bodyEn: "Search persons and log new moi received or given in seconds.",
    Surface: OverviewSurface,
  },
  {
    id: "feedback",
    icon: MessageSquareText,
    titleTa: "கருத்துகள்",
    titleEn: "Feedback",
    bodyTa: "கருத்தை அனுப்பி நிலுவை நிலையைப் பாருங்கள்.",
    bodyEn: "Send feedback and track pending replies.",
    Surface: FeedbackSurface,
  },
  {
    id: "more",
    icon: Lock,
    titleTa: "மேலும்",
    titleEn: "More",
    bodyTa: "சுயவிவரம், ஏற்றுமதி, ஆப் பூட்டு, மொழி மற்றும் நிற விருப்பங்கள்.",
    bodyEn: "Profile, export, app lock, language and accent preferences.",
    Surface: MoreSurface,
  },
] as const;

const installSteps = [
  {
    icon: Download,
    titleTa: "நிறுவுங்கள்",
    titleEn: "Install",
    bodyTa: "Play Store-ல் Moi Kanakku | GK Tech தேடி நிறுவுங்கள்.",
    bodyEn: "Search Moi Kanakku | GK Tech on Play Store and install.",
  },
  {
    icon: UserRound,
    titleTa: "சுயவிவரம்",
    titleEn: "Profile",
    bodyTa: "ஆப்பில் சுயவிவரம் உருவாக்கி விவரங்களை அமைக்கவும்.",
    bodyEn: "Create your profile and set your details in the app.",
  },
  {
    icon: PenLine,
    titleTa: "பதிவு",
    titleEn: "Record",
    bodyTa: "நிகழ்ச்சி சேர்த்து மொய் விவரங்களைப் பதிவு செய்யவும்.",
    bodyEn: "Add an event and record moi details as they come in.",
  },
  {
    icon: Share2,
    titleTa: "ஏற்றுமதி",
    titleEn: "Export",
    bodyTa: "விழா முடிவில் அறிக்கையை ஏற்றுமதி / பகிரவும்.",
    bodyEn: "Export or share the report when the function ends.",
  },
] as const;

const revealParent: Variants = {
  hidden: {},
  show: { transition: { staggerChildren: 0.1 } },
};

const revealChild: Variants = {
  hidden: { opacity: 0, y: 22 },
  show: { opacity: 1, y: 0, transition: spring },
};

function Page() {
  const reduce = useReducedMotion();

  return (
    <div className="bg-[#f9fafb] text-foreground">
      {/* Product header */}
      <section className="border-b border-[#e5e7eb] bg-white">
        <div className="mx-auto grid max-w-[1400px] gap-10 px-4 py-14 sm:px-6 lg:grid-cols-[1.1fr_0.9fr] lg:items-center lg:gap-16 lg:px-8 lg:py-20">
          <motion.div
            initial={reduce ? false : { opacity: 0, y: 18 }}
            animate={{ opacity: 1, y: 0 }}
            transition={spring}
            className="max-w-xl"
          >
            {/* <div className="mb-6 flex items-center gap-4">
              <img
                src="/logo.png"
                alt=""
                className="h-16 w-16 rounded-[5px] border border-[#e5e7eb] bg-[#f9fafb] object-contain p-2"
              />
              <div>
                <p className="font-display text-xl font-bold tracking-tight">Moi Kanakku</p>
                <p className="text-sm text-muted-foreground">GK Tech · Android</p>
              </div>
            </div> */}

            <h1 className="font-display text-4xl font-extrabold tracking-tighter text-[#0b3d2e] md:text-5xl lg:text-6xl lg:leading-none">
              <T ta="மொய் கணக்குகள் உங்கள் உள்ளங்கையில்" en="Moi accounts in your palm" />
            </h1>
            <p className="mt-5 max-w-[52ch] text-base leading-relaxed text-muted-foreground">
              <T
                ta="முகப்பு இருப்பு முதல் ஏற்றுமதி வரை - ஆப்பில் உள்ளவை இங்கே."
                en="From home balance to export - see what lives inside the app."
              />
            </p>
            <PlayButton />

            <div className="mt-8 flex flex-wrap items-center gap-4"></div>

            <ul className="mt-8 flex flex-wrap gap-x-5 gap-y-2 text-xs font-medium text-muted-foreground">
              <li className="inline-flex items-center gap-1.5">
                <Smartphone className="h-3.5 w-3.5 text-[#0b3d2e]" strokeWidth={1.5} />
                Android 7.0+
              </li>
              <li>
                <T ta="100% இலவசம்" en="100% free" />
              </li>
              <li>
                <T ta="விளம்பரம் இல்லை" en="No ads" />
              </li>
            </ul>
          </motion.div>

          <motion.div
            initial={reduce ? false : { opacity: 0, y: 24 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ ...spring, delay: 0.08 }}
            className="mx-auto w-full max-w-md"
          >
            <div className="rounded-[2.5rem] border border-slate-200/50 bg-[#f9fafb] p-2 shadow-[0_20px_40px_-15px_rgba(0,0,0,0.05)]">
              <div className="h-[340px] overflow-hidden rounded-[2rem] sm:h-[380px]">
                <HomeSurface />
              </div>
            </div>
          </motion.div>
        </div>
      </section>

      {/* What the app includes - sticky scroll like How to start */}
      <section className="border-t border-[#e5e7eb] bg-white">
        <div className="mx-auto max-w-[1400px] px-4 py-24 sm:px-6 md:py-28 lg:px-8">
          <div className="grid gap-12 lg:grid-cols-[0.9fr_1.1fr] lg:gap-16 xl:gap-24">
            <div className="lg:sticky lg:top-28 lg:self-start">
              <motion.div
                initial={reduce ? false : { opacity: 0, y: 16 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, amount: 0.4 }}
                transition={{ duration: 0.7, ease: easeOut }}
              >
                <h2 className="font-display text-3xl font-extrabold tracking-tighter text-[#0b3d2e] md:text-4xl md:leading-none">
                  <T ta="ஆப்பில் உள்ளவை" en="What the app includes" />
                </h2>
                <p className="mt-4 max-w-[40ch] text-sm leading-relaxed text-muted-foreground">
                  <T
                    ta="முகப்பு, கண்ணோட்டம், கருத்துகள் மற்றும் அமைப்புகள் - உருட்டும்போது ஒவ்வொன்றும் தெரியும்."
                    en="Home, Overview, Feedback and More - each surface reveals as you scroll."
                  />
                </p>
                <div className="mt-8">
                  <PlayButton />
                </div>
              </motion.div>
            </div>

            <motion.div
              variants={revealParent}
              initial={reduce ? false : "hidden"}
              whileInView="show"
              viewport={{ once: true, amount: 0.08 }}
              className="space-y-8"
            >
              {featureBlocks.map((block) => (
                <motion.article
                  key={block.id}
                  variants={revealChild}
                  className="scroll-mt-28 border-t border-[#e8f2ec] pt-8 first:border-t-0 first:pt-0"
                >
                  <div className="mb-4 flex items-start gap-3">
                    <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-[5px] bg-[#dcefe6] text-[#0b3d2e]">
                      <block.icon className="h-5 w-5" strokeWidth={1.5} />
                    </span>
                    <div>
                      <h3 className="font-display text-xl font-bold tracking-tight text-[#0b3d2e]">
                        <T ta={block.titleTa} en={block.titleEn} />
                      </h3>
                      <p className="mt-1 max-w-[42ch] text-sm leading-relaxed text-muted-foreground">
                        <T ta={block.bodyTa} en={block.bodyEn} />
                      </p>
                    </div>
                  </div>

                  <div className="rounded-[2.5rem] border border-slate-200/50 bg-[#f9fafb] p-2 shadow-[0_20px_40px_-15px_rgba(0,0,0,0.05)]">
                    <div className="h-[300px] overflow-hidden rounded-[2rem] sm:h-[320px]">
                      <block.Surface />
                    </div>
                  </div>
                </motion.article>
              ))}
            </motion.div>
          </div>
        </div>
      </section>

      {/* How to start - sticky scroll */}
      <section className="border-t border-[#e5e7eb] bg-[#f9fafb]">
        <div className="mx-auto max-w-[1400px] px-4 py-24 sm:px-6 md:py-28 lg:px-8">
          <div className="grid gap-12 lg:grid-cols-[0.85fr_1.15fr] lg:gap-20">
            <div className="lg:sticky lg:top-28 lg:self-start">
              <h2 className="font-display text-3xl font-extrabold tracking-tight text-[#0b3d2e] md:text-4xl">
                <T ta="ஆப்பை எப்படி தொடங்குவது" en="How to start in the app" />
              </h2>
              <p className="mt-3 max-w-[40ch] text-sm leading-relaxed text-muted-foreground">
                <T
                  ta="நிறுவல் முதல் ஏற்றுமதி வரை - நான்கு படிகள்."
                  en="From install to export in four steps."
                />
              </p>
              <div className="mt-8">
                <PlayButton />
              </div>
            </div>

            <ol>
              {installSteps.map((step, i) => (
                <li
                  key={step.titleEn}
                  className={cn(
                    "grid grid-cols-[auto_1fr] gap-5 border-t border-[#e5e7eb] py-7",
                    i === installSteps.length - 1 && "border-b",
                  )}
                >
                  <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-[5px] bg-[#dcefe6] text-[#0b3d2e]">
                    <step.icon className="h-5 w-5" strokeWidth={1.5} />
                  </span>
                  <div>
                    <h3 className="font-display text-xl font-bold tracking-tight text-[#0b3d2e]">
                      <T ta={step.titleTa} en={step.titleEn} />
                    </h3>
                    <p className="mt-1.5 text-sm leading-relaxed text-muted-foreground">
                      <T ta={step.bodyTa} en={step.bodyEn} />
                    </p>
                  </div>
                </li>
              ))}
            </ol>
          </div>
        </div>
      </section>

      <section className="border-t border-[#0b3d2e]/20 bg-[#0b3d2e] text-white">
        <div className="mx-auto flex max-w-[1400px] flex-col gap-8 px-4 py-14 sm:flex-row sm:items-center sm:justify-between sm:px-6 lg:px-8">
          <div>
            <p className="font-display text-2xl font-bold tracking-tight">
              <T ta="இப்போதே நிறுவுங்கள்" en="Install now" />
            </p>
            <p className="mt-2 text-sm text-white/65">
              <T ta="Google Play-ல் இலவசம்" en="Free on Google Play" />
            </p>
          </div>
          <PlayButton />
        </div>
      </section>
    </div>
  );
}
