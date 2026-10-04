import { Link, useRouterState } from "@tanstack/react-router";
import { useEffect, useState, type ReactNode } from "react";
import { HugeiconsIcon } from "@hugeicons/react";
import {
  Cancel01Icon,
  Menu01Icon,
} from "@hugeicons/core-free-icons";
import {
  ArrowRight,
  Phone,
  Mail,
  MapPin,
  X,
  Play,
  ArrowUp,
} from "lucide-react";
import { useMotionValueEvent, useScroll } from "framer-motion";
import { T, useLang } from "@/lib/lang";
import { cn } from "@/lib/utils";
import labelDark from "@/assets/label-dark.png";
import googlePlayLogo from "@/assets/google-play-logo.webp";

const LOGO_SRC = "/logo.png";

export const PHONE = "+91-78454 56609";
export const PHONE_RAW = "917845456609";
export const EMAIL = "agprakash406@gmail.com";
export const PLAY_URL = "https://play.google.com/store/apps/details?id=com.renzo.moi";
export const MAP_URL = "https://maps.google.com/?q=Dindigul,Tamil+Nadu,624001";

type NavItem =
  | { kind: "route"; to: "/"; ta: string; en: string }
  | { kind: "route"; to: "/moi-app"; ta: string; en: string }
  | { kind: "route"; to: "/services"; ta: string; en: string }
  | { kind: "route"; to: "/about"; ta: string; en: string }
  | { kind: "route"; to: "/contact"; ta: string; en: string };

const mainNav: NavItem[] = [
  { kind: "route", to: "/", ta: "முகப்பு", en: "Home" },
  { kind: "route", to: "/moi-app", ta: "மொய் ஆப்", en: "Moi App" },
  { kind: "route", to: "/services", ta: "சேவைகள்", en: "Services" },
  { kind: "route", to: "/about", ta: "எங்களைப் பற்றி", en: "About Us" },
  { kind: "route", to: "/contact", ta: "தொடர்புக்கு", en: "Contact Us" },
];

const footerPolicies = [
  { to: "/locations" as const, ta: "சேவை இடங்கள்", en: "Service locations" },
  { to: "/moi-app" as const, ta: "மொய் ஆப்", en: "Moi App" },
  { to: "/privacy" as const, ta: "தனியுரிமைக் கொள்கை", en: "Privacy Policy" },
  { to: "/terms" as const, ta: "பயன்பாட்டு விதிகள்", en: "Terms of Use" },
  { to: "/account-deletion" as const, ta: "கணக்கு & தரவு நீக்கம்", en: "Account & Data Deletion" },
];

function LangSwitch({ compact = false }: { compact?: boolean }) {
  const { lang, setLang } = useLang();
  const nextLabel = lang === "ta" ? (compact ? "EN" : "English") : "தமிழ்";
  return (
    <button
      type="button"
      onClick={() => setLang(lang === "ta" ? "en" : "ta")}
      aria-label={lang === "ta" ? "Switch to English" : "Switch to Tamil"}
      className={cn(
        "inline-flex items-center justify-center rounded-[5px] bg-lime font-semibold text-ink transition-colors hover:bg-lime-bright active:scale-[0.98]",
        compact ? "h-9 px-2.5 text-xs" : "h-9 px-3.5 text-xs",
      )}
    >
      {nextLabel}
    </button>
  );
}

export function DownloadModal({ open, onClose }: { open: boolean; onClose: () => void }) {
  const { lang } = useLang();

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/70 p-4 backdrop-blur-sm"
      onClick={onClose}
      role="presentation"
    >
      <div
        className="relative w-full max-w-sm space-y-4 rounded-2xl border border-gold-500/30 bg-white p-6 text-center shadow-2xl"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-labelledby="download-modal-title"
      >
        <button
          type="button"
          onClick={onClose}
          className="absolute top-3 right-3 text-slate-400 hover:text-slate-600"
          aria-label="Close"
        >
          <X className="h-5 w-5" />
        </button>
        <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-lime-soft text-ink">
          <Play className="h-6 w-6 fill-ink" />
        </div>
        <h3 id="download-modal-title" className="font-tamil text-lg font-bold text-teal-900">
          <T ta="Android செயலியைப் பதிவிறக்கவும்" en="Download Moi Kanakku for Android" />
        </h3>
        <p className="text-xs leading-relaxed text-slate-600">
          <T
            ta="Google Play Store மூலம் Moi Kanakku செயலியை இலவசமாக நிறுவலாம் — விளம்பரம் இல்லை, சந்தா இல்லை."
            en="Get official Moi Kanakku free on Google Play — no ads, no subscriptions."
          />
        </p>
        <a
          href={PLAY_URL}
          target="_blank"
          rel="noreferrer"
          onClick={onClose}
          className="mx-auto flex w-full max-w-[220px] items-center justify-center"
          aria-label="Get it on Google Play"
        >
          <img
            src={googlePlayLogo}
            alt="Get it on Google Play"
            className="h-14 w-auto object-contain"
          />
        </a>
        <p className="text-[10px] text-slate-400">
          {lang === "ta" ? "புதிய தாவலில் திறக்கும்" : "Opens in a new tab"}
        </p>
      </div>
    </div>
  );
}

function BrandMark({ className = "" }: { className?: string }) {
  return (
    <Link
      to="/"
      className={cn("group flex shrink-0 items-center gap-2.5", className)}
    >
      <span className="flex h-9 w-9 shrink-0 items-center justify-center overflow-hidden rounded-[5px] border border-[#0b3d2e]/10 bg-white p-1 transition-transform group-hover:scale-[1.03] sm:h-10 sm:w-10">
        <img src={LOGO_SRC} alt="" className="h-full w-full object-contain" />
      </span>
      <img
        src={labelDark}
        alt="Moi Kanakku"
        className="h-8 w-auto object-contain sm:h-9"
      />
    </Link>
  );
}

function NavLink({
  to,
  ta,
  en,
  onNavigate,
  mobile = false,
}: {
  to: NavItem["to"];
  ta: string;
  en: string;
  onNavigate?: () => void;
  mobile?: boolean;
}) {
  return (
    <Link
      to={to}
      activeOptions={{ exact: true }}
      onClick={onNavigate}
      className={cn(
        "site-nav-link font-medium text-[#0b3d2e]/65 transition-colors hover:text-[#0b3d2e]",
        mobile
          ? "block border-b border-[#0b3d2e]/08 py-3.5 text-[0.95rem] last:border-b-0"
          : "relative px-1 py-1 text-sm after:absolute after:inset-x-0 after:-bottom-1 after:h-0.5 after:origin-left after:scale-x-0 after:bg-lime after:transition-transform after:duration-200 hover:after:scale-x-100",
      )}
      activeProps={{
        className: cn(
          "site-nav-link font-semibold text-[#0b3d2e]",
          mobile
            ? "block border-b border-[#0b3d2e]/08 py-3.5 text-[0.95rem] last:border-b-0"
            : "relative px-1 py-1 text-sm after:absolute after:inset-x-0 after:-bottom-1 after:h-0.5 after:origin-left after:scale-x-100 after:bg-lime",
        ),
      }}
    >
      <T ta={ta} en={en} />
    </Link>
  );
}

export function Header() {
  const [open, setOpen] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [hidden, setHidden] = useState(false);
  const pathname = useRouterState({ select: (s) => s.location.pathname });
  const { scrollY } = useScroll();

  useEffect(() => {
    setOpen(false);
    setHidden(false);
  }, [pathname]);

  useEffect(() => {
    if (!open) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = prev;
    };
  }, [open]);

  useMotionValueEvent(scrollY, "change", (latest) => {
    if (open) {
      setHidden(false);
      return;
    }
    const previous = scrollY.getPrevious() ?? 0;
    if (latest < 24) {
      setHidden(false);
      return;
    }
    if (latest > previous + 4) setHidden(true);
    else if (latest < previous - 2) setHidden(false);
  });

  return (
    <>
      <header
        className={cn(
          "sticky top-0 z-50 border-b border-[#0b3d2e]/08 bg-white/90 backdrop-blur-xl transition-transform duration-300 ease-[cubic-bezier(0.16,1,0.3,1)] will-change-transform",
          hidden && !open ? "-translate-y-full" : "translate-y-0",
        )}
      >
        <div className="mx-auto max-w-[1400px] px-4 sm:px-6 lg:px-8">
          {/* Desktop */}
          <div className="hidden h-16 items-center justify-between gap-8 lg:flex">
            <BrandMark />
            <nav
              className="site-nav flex items-center gap-6 xl:gap-8"
              aria-label="Primary"
            >
              {mainNav.map((n) => (
                <NavLink key={n.to} to={n.to} ta={n.ta} en={n.en} />
              ))}
            </nav>
            <LangSwitch />
          </div>

          {/* Mobile */}
          <div className="flex h-16 items-center justify-between gap-3 lg:hidden">
            <BrandMark />
            <div className="flex items-center gap-2">
              <LangSwitch compact />
              <button
                type="button"
                className="flex h-9 w-9 items-center justify-center text-[#0b3d2e] transition-opacity hover:opacity-70 active:scale-[0.98]"
                onClick={() => setOpen((v) => !v)}
                aria-expanded={open}
                aria-controls="mobile-nav"
                aria-label="Toggle Navigation"
              >
                <HugeiconsIcon
                  icon={open ? Cancel01Icon : Menu01Icon}
                  size={22}
                  strokeWidth={1.5}
                />
              </button>
            </div>
          </div>
        </div>

        {/* Mobile panel */}
        <div
          id="mobile-nav"
          className={cn(
            "border-t border-[#0b3d2e]/08 bg-white lg:hidden",
            open ? "block" : "hidden",
          )}
        >
          <nav className="site-nav mx-auto max-w-[1400px] px-4 py-2 sm:px-6" aria-label="Mobile">
            {mainNav.map((n) => (
              <NavLink
                key={n.to}
                to={n.to}
                ta={n.ta}
                en={n.en}
                mobile
                onNavigate={() => setOpen(false)}
              />
            ))}
            <div className="py-5">
              <button
                type="button"
                onClick={() => {
                  setOpen(false);
                  setModalOpen(true);
                }}
                className="mx-auto flex w-full max-w-[220px] items-center justify-center"
                aria-label="Get it on Google Play"
              >
                <img
                  src={googlePlayLogo}
                  alt="Get it on Google Play"
                  className="h-12 w-auto object-contain"
                />
              </button>
            </div>
          </nav>
        </div>
      </header>
      <DownloadModal open={modalOpen} onClose={() => setModalOpen(false)} />
    </>
  );
}

export function Footer() {
  return (
    <footer className="border-t border-gold-500/20 bg-teal-950 py-12 text-slate-300">
      <div className="container-page space-y-8 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 gap-8 md:grid-cols-12">
          <div className="space-y-3 md:col-span-6">
            <div className="flex items-center gap-2">
              <div className="flex h-9 w-9 items-center justify-center overflow-hidden rounded-lg border border-gold-500/30 bg-white p-0.5">
                <img src={LOGO_SRC} alt="" className="h-full w-full object-contain" />
              </div>
              <span className="text-lg font-bold text-white">Moi Kanakku</span>
            </div>
            <p className="max-w-sm text-xs leading-relaxed text-slate-400">
              <T
                ta="தமிழ் குடும்பங்களின் விசேஷ மொய் கணக்குகளைப் பாதுகாப்பாகப் பதிவு செய்யும் Android செயலி. அனைவருக்கும் 100% இலவசம். விளம்பரம் / சந்தா இல்லை."
                en="A simple Android app for your family's moi records. 100% free for everyone - no ads, no subscriptions."
              />
            </p>
          </div>

          <div className="space-y-2 text-xs md:col-span-3">
            <h4 className="mb-2 font-bold tracking-wider text-gold-400 uppercase">
              <T ta="தொடர்புக்கு" en="SUPPORT CONTACT" />
            </h4>
            <a href={`mailto:${EMAIL}`} className="flex items-center gap-2 hover:text-gold-400">
              <Mail className="h-3.5 w-3.5 text-gold-500" /> {EMAIL}
            </a>
            <a href={`tel:+${PHONE_RAW}`} className="flex items-center gap-2 hover:text-gold-400">
              <Phone className="h-3.5 w-3.5 text-gold-500" /> {PHONE}
            </a>
            <a
              href={MAP_URL}
              target="_blank"
              rel="noreferrer"
              className="flex items-center gap-2 hover:text-gold-400"
            >
              <MapPin className="h-3.5 w-3.5 text-gold-500" /> Dindigul, Tamil Nadu
            </a>
          </div>

          <div className="space-y-2 text-xs md:col-span-3">
            <h4 className="mb-2 font-bold tracking-wider text-gold-400 uppercase">
              <T ta="மேலும்" en="EXPLORE" />
            </h4>
            <ul className="flex flex-col gap-2 text-slate-400">
              {footerPolicies.map((p) => (
                <li key={p.to}>
                  <Link to={p.to} className="transition-colors hover:text-gold-400">
                    • <T ta={p.ta} en={p.en} />
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        </div>

        <div className="border-t border-teal-900 pt-6 text-center text-[11px] text-slate-500">
          <p>
            © 2026 Moi Kanakku | GK Tech.{" "}
            <T ta="அனைத்து உரிமைகளும் பாதுகாக்கப்பட்டவை." en="All Rights Reserved." />
          </p>
        </div>
      </div>
    </footer>
  );
}

export function ScrollTopButton() {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const onScroll = () => setVisible(window.scrollY > 280);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <button
      type="button"
      onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
      aria-label="Scroll to top"
      className={`fixed right-4 bottom-4 z-40 flex h-11 w-11 items-center justify-center rounded-full border border-lime/40 bg-ink text-lime shadow-[0_12px_32px_-12px_rgba(9,9,11,0.45)] transition-all duration-500 ease-[cubic-bezier(0.16,1,0.3,1)] hover:bg-black hover:text-lime-bright active:scale-[0.96] sm:right-6 sm:bottom-6 sm:h-12 sm:w-12 ${
        visible ? "translate-y-0 opacity-100" : "pointer-events-none translate-y-8 opacity-0"
      }`}
    >
      <ArrowUp className="h-5 w-5" strokeWidth={1.75} />
    </button>
  );
}

export function PageHero({
  eyebrow,
  title,
  children,
}: {
  eyebrow: ReactNode;
  title: ReactNode;
  children?: ReactNode;
}) {
  return (
    <section className="relative overflow-hidden bg-teal-900 text-ivory-50">
      <div className="container-page relative py-20 md:py-28 fade-up">
        <p className="mb-5 inline-block rounded-md border border-gold-500/30 bg-gold-500/20 px-2.5 py-1 text-xs font-bold tracking-wider text-gold-400 uppercase">
          {eyebrow}
        </p>
        <h1 className="max-w-3xl text-4xl leading-[1.15] font-extrabold tracking-tight md:text-6xl">
          {title}
        </h1>
        {children && <div className="mt-6 max-w-2xl text-lg text-teal-100">{children}</div>}
      </div>
    </section>
  );
}

export function SectionHead({
  eyebrow,
  title,
  sub,
}: {
  eyebrow?: ReactNode;
  title: ReactNode;
  sub?: ReactNode;
}) {
  return (
    <div className="mx-auto mb-12 max-w-3xl space-y-3 text-center">
      {eyebrow ? (
        <span className="text-xs font-bold tracking-widest text-gold-600 uppercase">{eyebrow}</span>
      ) : null}
      <h2 className="text-2xl leading-tight font-extrabold text-teal-900 sm:text-3xl md:text-4xl">
        {title}
      </h2>
      {sub && <p className="text-slate-600">{sub}</p>}
    </div>
  );
}

export function CtaBand({
  title,
  sub,
  to = "/contact",
  label,
}: {
  title: ReactNode;
  sub: ReactNode;
  to?: "/contact";
  label: ReactNode;
}) {
  return (
    <section className="container-page py-20">
      <div className="flex flex-col items-start justify-between gap-6 rounded-2xl border border-gold-500/30 bg-teal-900 p-10 md:flex-row md:items-center md:p-14">
        <div>
          <h2 className="text-2xl font-extrabold tracking-tight text-white md:text-3xl">{title}</h2>
          <p className="mt-2 text-teal-100">{sub}</p>
        </div>
        <Link
          to={to}
          className="inline-flex shrink-0 items-center gap-2 rounded-xl bg-slate-950 px-6 py-3 font-semibold text-white transition-transform hover:-translate-y-0.5"
        >
          {label} <ArrowRight size={18} />
        </Link>
      </div>
    </section>
  );
}

export function Steps({ items }: { items: { ta: string; en: string }[] }) {
  return (
    <ol className="grid gap-6 md:grid-cols-3">
      {items.map((s, i) => (
        <li
          key={i}
          className="custom-shadow space-y-4 rounded-2xl border border-gold-500/30 bg-white p-8 text-center"
        >
          <span className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-teal-800 text-lg font-extrabold text-gold-400 shadow-md">
            {i + 1}
          </span>
          <span className="font-tamil block font-bold text-teal-900">
            <T ta={s.ta} en={s.en} />
          </span>
        </li>
      ))}
    </ol>
  );
}

export function PlayButton({
  onClick,
  className = "",
}: {
  onClick?: () => void;
  className?: string;
}) {
  const badge = (
    <img
      src={googlePlayLogo}
      alt="Get it on Google Play"
      className="h-12 w-auto object-contain transition-transform group-hover:scale-[1.03] sm:h-14"
    />
  );
  const classes = `group inline-flex shrink-0 items-center justify-center transition-opacity hover:opacity-90 active:scale-[0.98] ${className}`;

  if (onClick) {
    return (
      <button type="button" onClick={onClick} className={classes} aria-label="Get it on Google Play">
        {badge}
      </button>
    );
  }

  return (
    <a
      href={PLAY_URL}
      target="_blank"
      rel="noreferrer"
      className={classes}
      aria-label="Get it on Google Play"
    >
      {badge}
    </a>
  );
}
