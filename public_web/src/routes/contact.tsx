"use client";

import { createFileRoute } from "@tanstack/react-router";
import { useMemo, useState, type FormEvent, type ReactNode } from "react";
import { HugeiconsIcon } from "@hugeicons/react";
import type { IconSvgElement } from "@hugeicons/react";
import {
  Calendar03Icon,
  Call02Icon,
  Location01Icon,
  Mail01Icon,
  SentIcon,
  WhatsappIcon,
} from "@hugeicons/core-free-icons";
import { format, startOfDay } from "date-fns";
import {
  motion,
  useMotionValue,
  useReducedMotion,
  useSpring,
} from "framer-motion";
import { T, useLang, useT } from "@/lib/lang";
import { EMAIL, MAP_URL, PHONE, PHONE_RAW } from "@/components/site";
import { buildPageHead } from "@/lib/seo";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/contact")({
  head: () =>
    buildPageHead({
      title: "Contact - Book Moi Function Service | Moi Kanakku",
      description:
        "Book Moi @ Computer or note update for your function. Call or WhatsApp +91-78454 56609. Based in Dindigul, serving Tamil Nadu.",
      path: "/contact",
    }),
  component: Contact,
});

const spring = { type: "spring" as const, stiffness: 100, damping: 20 };

const eventTypes: [string, string][] = [
  ["திருமண விழா", "Wedding"],
  ["நிச்சயதார்த்தம்", "Engagement"],
  ["இல்ல விழா / புதுமனை புகு", "House Warming / New House Entry"],
  ["பிறந்தநாள் / குழந்தை விழா", "Birthday / Baby Ceremony"],
  ["மொய் விருந்து", "Moi Feast"],
  ["பிற விசேஷம்", "Other Event"],
];

const inputClass =
  "w-full rounded-[5px] border border-[#0b3d2e]/12 bg-white px-3.5 py-3 text-sm outline-none transition-[border-color,box-shadow] placeholder:text-muted-foreground focus:border-[#0b3d2e] focus:ring-3 focus:ring-[#0b3d2e]/12";

function sanitizeName(value: string) {
  return value.toUpperCase().replace(/[^A-Z .]/g, "");
}

function sanitizeMobile(value: string) {
  return value.replace(/\D/g, "").slice(0, 10);
}

function isValidName(value: string) {
  const v = value.trim();
  return /^[A-Z][A-Z .]*$/.test(v);
}

function isValidMobile(value: string) {
  return /^\d{10}$/.test(value);
}

function SpotlightForm({ children }: { children: ReactNode }) {
  const reduce = useReducedMotion();
  const x = useMotionValue(0);
  const y = useMotionValue(0);
  const sx = useSpring(x, { stiffness: 120, damping: 24 });
  const sy = useSpring(y, { stiffness: 120, damping: 24 });

  return (
    <motion.div
      onMouseMove={(e) => {
        if (reduce) return;
        const r = e.currentTarget.getBoundingClientRect();
        x.set(e.clientX - r.left);
        y.set(e.clientY - r.top);
      }}
      className="relative overflow-hidden rounded-[5px] border border-[#0b3d2e]/10 bg-white/80 p-7 shadow-[inset_0_1px_0_rgba(255,255,255,0.85),0_24px_50px_-30px_rgba(11,61,46,0.2)] backdrop-blur-md md:p-9"
    >
      {!reduce && (
        <motion.div
          aria-hidden
          className="pointer-events-none absolute h-56 w-56 -translate-x-1/2 -translate-y-1/2 rounded-full bg-lime/25 blur-3xl"
          style={{ left: sx, top: sy }}
        />
      )}
      <div className="relative">{children}</div>
    </motion.div>
  );
}

function ContactLink({
  href,
  icon,
  main,
  sub,
  index,
  accent,
}: {
  href: string;
  icon: IconSvgElement;
  main: string;
  sub: string;
  index: number;
  accent?: boolean;
}) {
  const reduce = useReducedMotion();
  return (
    <motion.a
      href={href}
      target={href.startsWith("http") ? "_blank" : undefined}
      rel="noreferrer"
      initial={reduce ? false : { opacity: 0, x: 20 }}
      whileInView={{ opacity: 1, x: 0 }}
      viewport={{ once: true }}
      transition={{ ...spring, delay: 0.08 + index * 0.06 }}
      whileHover={reduce ? {} : { y: -2 }}
      className={cn(
        "flex items-center gap-4 rounded-[5px] border p-5 transition-colors active:scale-[0.99]",
        accent
          ? "border-lime/40 bg-lime text-ink hover:bg-lime-bright"
          : "border-[#0b3d2e]/10 bg-white/75 backdrop-blur-sm hover:border-[#0b3d2e]/30",
      )}
    >
      <span
        className={cn(
          "flex h-11 w-11 shrink-0 items-center justify-center rounded-[5px]",
          accent ? "bg-ink/10 text-ink" : "bg-[#eef6e4] text-[#0b3d2e]",
        )}
      >
        <HugeiconsIcon icon={icon} size={20} strokeWidth={1.5} />
      </span>
      <span className="min-w-0">
        <span className="block truncate font-semibold">{main}</span>
        <span
          className={cn(
            "block text-sm",
            accent ? "text-ink/70" : "text-muted-foreground",
          )}
        >
          {sub}
        </span>
      </span>
    </motion.a>
  );
}

function Contact() {
  const t = useT();
  const { lang } = useLang();
  const reduce = useReducedMotion();
  const today = useMemo(() => startOfDay(new Date()), []);

  const [event, setEvent] = useState("Wedding");
  const [name, setName] = useState("");
  const [mobile, setMobile] = useState("");
  const [email, setEmail] = useState("");
  const [location, setLocation] = useState("");
  const [date, setDate] = useState<Date | undefined>();
  const [dateOpen, setDateOpen] = useState(false);
  const [touched, setTouched] = useState(false);
  const [errors, setErrors] = useState<{ name?: string; mobile?: string }>({});

  const validate = () => {
    const next: { name?: string; mobile?: string } = {};
    const trimmedName = name.trim();
    if (!trimmedName) {
      next.name = lang === "ta" ? "பெயர் தேவை" : "Name is required";
    } else if (!isValidName(trimmedName)) {
      next.name =
        lang === "ta"
          ? "பெயரில் ஆங்கில எழுத்துகள், இடைவெளி மற்றும் புள்ளி மட்டும் அனுமதி"
          : "Name may only use letters, spaces and a period (.)";
    }
    if (!mobile.trim()) {
      next.mobile = lang === "ta" ? "மொபைல் எண் தேவை" : "Mobile number is required";
    } else if (!isValidMobile(mobile)) {
      next.mobile =
        lang === "ta" ? "10 இலக்க மொபைல் எண்ணை உள்ளிடவும்" : "Enter a 10-digit mobile number";
    }
    setErrors(next);
    return Object.keys(next).length === 0;
  };

  const submit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setTouched(true);
    if (!validate()) return;

    const dateText = date ? format(date, "dd MMM yyyy") : "-";
    const msg = `Moi Kanakku service booking
Name: ${name.trim()}
Mobile: ${mobile.trim()}
Email: ${email.trim() || "-"}
Event: ${event}
Location: ${location.trim() || "-"}
Date: ${dateText}`;
    window.open(`https://wa.me/${PHONE_RAW}?text=${encodeURIComponent(msg)}`, "_blank");
  };

  return (
    <div className="bg-[#f4f7f5] text-foreground">
      {/* Hero */}
      <section className="relative overflow-hidden border-b border-[#e5e7eb] bg-white">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_80%_0%,rgba(144,208,31,0.16),transparent_45%),radial-gradient(ellipse_at_0%_100%,rgba(11,61,46,0.05),transparent_40%)]"
        />
        <div className="relative mx-auto max-w-[1400px] px-4 py-16 sm:px-6 lg:px-8 lg:py-24">
          <motion.h1
            initial={reduce ? false : { opacity: 0, y: 32 }}
            animate={{ opacity: 1, y: 0 }}
            transition={spring}
            className="max-w-[18ch] font-display text-4xl font-extrabold tracking-tighter text-[#0b3d2e] md:text-5xl lg:text-6xl lg:leading-none"
          >
            <T
              ta="உங்கள் நிகழ்ச்சிக்கான மொய் சேவைக்கு இங்கே முன்பதிவு செய்யுங்கள்."
              en="Book moi service for your event here."
            />
          </motion.h1>
          <motion.p
            initial={reduce ? false : { opacity: 0, y: 18 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ ...spring, delay: 0.12 }}
            className="mt-5 max-w-[48ch] text-base leading-relaxed text-muted-foreground"
          >
            <T
              ta="படிவத்தை நிரப்பி WhatsApp-ல் அனுப்புங்கள் — அல்லது நேரடியாக அழைக்கவும்."
              en="Fill the form and send via WhatsApp — or call us directly."
            />
          </motion.p>
        </div>
      </section>

      <section className="relative py-16 md:py-24">
        <div className="mx-auto grid max-w-[1400px] gap-8 px-4 sm:px-6 lg:grid-cols-[1.35fr_0.9fr] lg:gap-10 lg:px-8">
          <motion.div
            initial={reduce ? false : { opacity: 0, y: 24 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={spring}
          >
            <SpotlightForm>
              <form onSubmit={submit} noValidate>
                <div className="flex items-start justify-between gap-4">
                  <div>
                    <h2 className="font-display text-2xl font-extrabold tracking-tight text-[#0b3d2e]">
                      <T ta="தொடர்பு படிவம்" en="Contact form" />
                    </h2>
                    <p className="mt-2 text-sm text-muted-foreground">
                      <T
                        ta="உங்கள் விவரங்களை பகிர்ந்தால், எங்கள் குழு விரைவில் தொடர்பு கொள்கிறது."
                        en="Share your details and our team will contact you soon."
                      />
                    </p>
                  </div>
                  <span className="hidden h-11 w-11 shrink-0 items-center justify-center rounded-[5px] bg-[#eef6e4] text-[#0b3d2e] sm:flex">
                    <HugeiconsIcon icon={WhatsappIcon} size={22} strokeWidth={1.5} />
                  </span>
                </div>

                <div className="mt-8 grid gap-5 sm:grid-cols-2">
                  <label className="flex flex-col gap-2 text-sm font-semibold text-[#0b3d2e]">
                    <span>
                      <T ta="பெயர்" en="Name" /> <span className="text-destructive">*</span>
                    </span>
                    <input
                      name="name"
                      value={name}
                      onChange={(e) => {
                        setName(sanitizeName(e.target.value));
                        if (touched) validate();
                      }}
                      onBlur={() => {
                        setTouched(true);
                        setName((v) => v.trim());
                        validate();
                      }}
                      placeholder={t("உங்கள் பெயரை உள்ளிடவும்", "Enter your name")}
                      autoComplete="name"
                      autoCapitalize="characters"
                      spellCheck={false}
                      className={cn(
                        inputClass,
                        "uppercase",
                        errors.name && "border-destructive focus:border-destructive focus:ring-destructive/20",
                      )}
                      aria-invalid={!!errors.name}
                    />
                    {errors.name && (
                      <span className="text-xs font-medium text-destructive">{errors.name}</span>
                    )}
                  </label>

                  <label className="flex flex-col gap-2 text-sm font-semibold text-[#0b3d2e]">
                    <span>
                      <T ta="மொபைல் எண்" en="Mobile number" />{" "}
                      <span className="text-destructive">*</span>
                    </span>
                    <input
                      name="mobile"
                      type="tel"
                      value={mobile}
                      onChange={(e) => {
                        setMobile(sanitizeMobile(e.target.value));
                        if (touched) validate();
                      }}
                      onBlur={() => {
                        setTouched(true);
                        validate();
                      }}
                      placeholder={t("எ.கா. 9876543210", "e.g. 9876543210")}
                      autoComplete="tel"
                      inputMode="numeric"
                      maxLength={10}
                      pattern="\d{10}"
                      className={cn(
                        inputClass,
                        errors.mobile &&
                          "border-destructive focus:border-destructive focus:ring-destructive/20",
                      )}
                      aria-invalid={!!errors.mobile}
                    />
                    {errors.mobile && (
                      <span className="text-xs font-medium text-destructive">{errors.mobile}</span>
                    )}
                  </label>

                  <label className="flex flex-col gap-2 text-sm font-semibold text-[#0b3d2e] sm:col-span-2">
                    <T ta="மின்னஞ்சல் (விருப்பம்)" en="Email (optional)" />
                    <input
                      name="email"
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder={t("name@example.com", "name@example.com")}
                      autoComplete="email"
                      className={inputClass}
                    />
                  </label>
                </div>

                <p className="mt-6 mb-3 text-sm font-semibold text-[#0b3d2e]">
                  <T ta="நிகழ்ச்சி வகை" en="Event type" />
                </p>
                <div className="flex flex-wrap gap-2">
                  {eventTypes.map(([ta, en], i) => (
                    <motion.button
                      type="button"
                      key={en}
                      onClick={() => setEvent(en)}
                      initial={reduce ? false : { opacity: 0, scale: 0.94 }}
                      whileInView={{ opacity: 1, scale: 1 }}
                      viewport={{ once: true }}
                      transition={{ ...spring, delay: i * 0.03 }}
                      className={cn(
                        "rounded-[5px] border px-3.5 py-2 text-sm font-medium transition-colors active:scale-[0.98]",
                        event === en
                          ? "border-[#0b3d2e] bg-[#0b3d2e] text-white"
                          : "border-[#0b3d2e]/12 bg-white hover:border-[#0b3d2e]/40",
                      )}
                    >
                      {t(ta, en)}
                    </motion.button>
                  ))}
                </div>

                <div className="mt-6 grid gap-5 sm:grid-cols-2">
                  <label className="flex flex-col gap-2 text-sm font-semibold text-[#0b3d2e]">
                    <T ta="இடம்" en="Location" />
                    <input
                      name="location"
                      value={location}
                      onChange={(e) => setLocation(e.target.value.toUpperCase())}
                      onBlur={() => setLocation((v) => v.trim())}
                      placeholder={t("ஊர் / மண்டபம் / முகவரி", "Town / hall / address")}
                      autoCapitalize="characters"
                      spellCheck={false}
                      className={cn(inputClass, "uppercase")}
                    />
                  </label>

                  <div className="flex flex-col gap-2 text-sm font-semibold text-[#0b3d2e]">
                    <T ta="தேதி" en="Date" />
                    <Popover open={dateOpen} onOpenChange={setDateOpen}>
                      <PopoverTrigger asChild>
                        <button
                          type="button"
                          className={cn(
                            inputClass,
                            "inline-flex items-center justify-between text-left font-normal",
                            !date && "text-muted-foreground",
                          )}
                        >
                          <span>
                            {date
                              ? format(date, "dd MMM yyyy")
                              : t("தேதியைத் தேர்வு செய்யவும்", "Pick a date")}
                          </span>
                          <span className="shrink-0 text-muted-foreground">
                            <HugeiconsIcon
                              icon={Calendar03Icon}
                              size={16}
                              strokeWidth={1.5}
                              color="currentColor"
                            />
                          </span>
                        </button>
                      </PopoverTrigger>
                      <PopoverContent className="w-auto border-border p-0" align="start">
                        <Calendar
                          mode="single"
                          selected={date}
                          onSelect={(next) => {
                            setDate(next);
                            setDateOpen(false);
                          }}
                          disabled={{ before: today }}
                          startMonth={today}
                          initialFocus
                        />
                      </PopoverContent>
                    </Popover>
                  </div>
                </div>

                <button
                  type="submit"
                  className="mt-7 inline-flex w-full items-center justify-center gap-2 rounded-[5px] bg-[#0b3d2e] px-6 py-3.5 text-sm font-semibold text-white transition-colors hover:bg-black active:scale-[0.99]"
                >
                  <HugeiconsIcon icon={SentIcon} size={18} strokeWidth={1.5} />
                  <T ta="WhatsApp-ல் அனுப்பு" en="Send via WhatsApp" />
                </button>
              </form>
            </SpotlightForm>
          </motion.div>

          <aside className="flex flex-col gap-4">
            <motion.div
              initial={reduce ? false : { opacity: 0, scale: 0.96 }}
              whileInView={{ opacity: 1, scale: 1 }}
              viewport={{ once: true }}
              transition={spring}
              className="relative overflow-hidden rounded-[5px] bg-[#0b3d2e] p-7 text-white"
            >
              <h2 className="font-display text-xl font-extrabold tracking-tight">
                <T ta="நேரடி தொடர்பு" en="Direct contact" />
              </h2>
              <p className="mt-2 text-sm text-white/65">
                <T
                  ta="WhatsApp அல்லது கால் மூலம் பேசுங்கள்."
                  en="Reach us via WhatsApp or call."
                />
              </p>
              {!reduce && (
                <motion.div
                  aria-hidden
                  className="pointer-events-none absolute -right-8 -bottom-10 h-36 w-36 rounded-full bg-lime/30 blur-2xl"
                  animate={{ scale: [1, 1.12, 1], opacity: [0.4, 0.65, 0.4] }}
                  transition={{ duration: 5, repeat: Infinity, ease: "easeInOut" }}
                />
              )}
            </motion.div>

            <ContactLink
              href={`https://wa.me/${PHONE_RAW}`}
              icon={WhatsappIcon}
              main={PHONE}
              sub={t("WhatsApp", "WhatsApp")}
              index={0}
              accent
            />
            <ContactLink
              href={`tel:+${PHONE_RAW}`}
              icon={Call02Icon}
              main={PHONE}
              sub={t("அழைப்பு", "Call")}
              index={1}
            />
            <ContactLink
              href={`mailto:${EMAIL}`}
              icon={Mail01Icon}
              main={EMAIL}
              sub={t("மின்னஞ்சல்", "Email")}
              index={2}
            />
            <ContactLink
              href={MAP_URL}
              icon={Location01Icon}
              main="Moi Kanakku"
              sub="Dindigul, Tamil Nadu 624001, India"
              index={3}
            />
          </aside>
        </div>
      </section>
    </div>
  );
}
