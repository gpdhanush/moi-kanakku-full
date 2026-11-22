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

const footerLegal = [
  { to: "/privacy" as const, ta: "தனியுரிமைக் கொள்கை", en: "Privacy Policy" },
  { to: "/terms" as const, ta: "பயன்பாட்டு விதிகள்", en: "Terms of Use" },
  { to: "/account-deletion" as const, ta: "கணக்கு & தரவு நீக்கம்", en: "Account & Data Deletion" },
];

const footerLinkClass =
  "group inline-flex items-center gap-1 text-sm text-white/65 transition-colors hover:text-lime";

function FooterHeading({ children }: { children: ReactNode }) {
  return (
    // <p role="heading"> so the site-wide Tamil h3 size rule doesn't enlarge these labels.
    <p
      role="heading"
      aria-level={3}
      className="mb-4 text-xs font-semibold tracking-[0.16em] text-lime uppercase in-[.lang-ta]:text-sm in-[.lang-ta]:tracking-normal"
    >
      {children}
    </p>
  );
}

export function Footer() {
  const year = new Date().getFullYear();
  return (
    <footer className="relative isolate overflow-hidden bg-[#0b3d2e] text-white">
      {/* soft lime glow + grid texture */}
      <div
        aria-hidden
        className="pointer-events-none absolute -top-40 left-1/2 -z-10 h-[28rem] w-[56rem] -translate-x-1/2 rounded-full bg-lime/15 blur-3xl"
      />
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 -z-10 bg-[linear-gradient(to_right,rgba(255,255,255,0.04)_1px,transparent_1px),linear-gradient(to_bottom,rgba(255,255,255,0.04)_1px,transparent_1px)] [mask-image:radial-gradient(ellipse_at_top,black,transparent_70%)] bg-[size:48px_48px]"
      />

      <div className="mx-auto max-w-[1400px] px-4 pt-16 sm:px-6 lg:px-8 lg:pt-20">
        {/* CTA */}
        <div className="flex flex-col items-start justify-between gap-6 rounded-2xl border border-white/10 bg-white/[0.04] p-6 backdrop-blur-sm sm:p-8 md:flex-row md:items-center">
          <div>
            <p className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
              <T ta="ஒவ்வொரு மொய்யும் பத்திரமாக." en="Every moi, kept safe." />
            </p>
            <p className="mt-2 max-w-[48ch] text-sm text-white/65">
              <T
                ta="100% இலவசம். விளம்பரம் இல்லை, சந்தா இல்லை. இன்றே பதிவிறக்குங்கள்."
                en="100% free. No ads, no subscriptions. Download it today."
              />
            </p>
          </div>
          <PlayButton />
        </div>

        {/* Columns */}
        <div className="grid grid-cols-2 gap-x-6 gap-y-10 py-14 md:grid-cols-12 lg:py-16">
          <div className="col-span-2 md:col-span-5">
            <Link to="/" className="inline-flex items-center gap-3">
              <span className="flex h-11 w-11 items-center justify-center overflow-hidden rounded-xl bg-white p-1 shadow-sm">
                <img src={LOGO_SRC} alt="" className="h-full w-full object-contain" />
              </span>
              <span className="font-display text-xl font-bold tracking-tight">Moi Kanakku</span>
            </Link>
            <p className="mt-4 max-w-sm text-sm leading-relaxed text-white/65">
              <T
                ta="தமிழ் குடும்பங்களின் விசேஷ மொய் கணக்குகளைப் பாதுகாப்பாகப் பதிவு செய்யும் Android செயலி."
                en="A simple Android app that keeps your family's moi records safe, for every celebration."
              />
            </p>
            <ul className="mt-6 flex flex-wrap gap-2">
              {[
                { ta: "100% இலவசம்", en: "100% free" },
                { ta: "தமிழ் & English", en: "Tamil & English" },
                { ta: "விளம்பரம் இல்லை", en: "No ads" },
              ].map((b) => (
                <li
                  key={b.en}
                  className="rounded-full border border-lime/25 bg-lime/10 px-3 py-1 text-xs font-medium text-lime"
                >
                  <T ta={b.ta} en={b.en} />
                </li>
              ))}
            </ul>
          </div>

          <nav aria-label="Footer" className="md:col-span-2">
            <FooterHeading>
              <T ta="மேலும்" en="Explore" />
            </FooterHeading>
            <ul className="space-y-3">
              {mainNav.map((item) => (
                <li key={item.to}>
                  <Link to={item.to} className={footerLinkClass}>
                    <T ta={item.ta} en={item.en} />
                  </Link>
                </li>
              ))}
              <li>
                <Link to="/locations" className={footerLinkClass}>
                  <T ta="சேவை இடங்கள்" en="Service locations" />
                </Link>
              </li>
            </ul>
          </nav>

          <div className="md:col-span-2">
            <FooterHeading>
              <T ta="சட்டம்" en="Legal" />
            </FooterHeading>
            <ul className="space-y-3">
              {footerLegal.map((p) => (
                <li key={p.to}>
                  <Link to={p.to} className={footerLinkClass}>
                    <T ta={p.ta} en={p.en} />
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          <div className="col-span-2 md:col-span-3">
            <FooterHeading>
              <T ta="தொடர்புக்கு" en="Contact" />
            </FooterHeading>
            <ul className="space-y-3">
              {[
                { href: `mailto:${EMAIL}`, icon: Mail, label: EMAIL, external: false },
                { href: `tel:+${PHONE_RAW}`, icon: Phone, label: PHONE, external: false },
                { href: MAP_URL, icon: MapPin, label: "Dindigul, Tamil Nadu", external: true },
              ].map(({ href, icon: Icon, label, external }) => (
                <li key={href}>
                  <a
                    href={href}
                    {...(external ? { target: "_blank", rel: "noreferrer" } : {})}
                    className="group flex items-center gap-3 text-sm text-white/65 transition-colors hover:text-white"
                  >
                    <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg border border-white/10 bg-white/5 text-lime transition-colors group-hover:border-lime/40 group-hover:bg-lime/10">
                      <Icon className="h-4 w-4" />
                    </span>
                    <span className="min-w-0 break-all">{label}</span>
                  </a>
                </li>
              ))}
            </ul>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="flex flex-col gap-3 border-t border-white/10 py-6 text-xs text-white/50 sm:flex-row sm:items-center sm:justify-between">
          <p>
            © {year} Moi Kanakku · GK Tech.{" "}
            <T ta="அனைத்து உரிமைகளும் பாதுகாக்கப்பட்டவை." en="All rights reserved." />
          </p>
          <p>
            <T ta="திண்டுக்கல்லில் அன்புடன் உருவாக்கப்பட்டது" en="Made with care in Dindigul" />{" "}
            <span className="text-lime">♥</span>
          </p>
        </div>
      </div>

      {/* Oversized wordmark */}
      <p
        aria-hidden
        className="pointer-events-none -mb-[0.22em] text-center font-display text-[18vw] leading-none font-bold tracking-tighter text-white/[0.05] select-none lg:text-[13rem]"
      >
        moi kanakku
      </p>
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
