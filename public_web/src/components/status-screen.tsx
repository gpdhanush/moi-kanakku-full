import { Link } from "@tanstack/react-router";
import { HugeiconsIcon } from "@hugeicons/react";
import {
  Home01Icon,
  RefreshIcon,
  Alert02Icon,
  Search01Icon,
} from "@hugeicons/core-free-icons";
import { T, LangProvider } from "@/lib/lang";
import labelDark from "@/assets/label-dark.png";

const LOGO_SRC = "/logo.png";

type StatusScreenProps = {
  kind: "error" | "not-found";
  onRetry?: () => void;
};

function StatusBody({ kind, onRetry }: StatusScreenProps) {
  const isError = kind === "error";

  return (
    <div className="relative flex min-h-[100dvh] items-center justify-center overflow-hidden px-4 py-16">
      {/* Atmosphere */}
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_80%_60%_at_50%_-10%,rgba(144,208,31,0.18),transparent_55%),radial-gradient(ellipse_70%_50%_at_100%_100%,rgba(11,61,46,0.08),transparent_50%),linear-gradient(180deg,#f7faf8_0%,#ffffff_45%,#eef6e4_100%)]"
      />
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 opacity-[0.35]"
        style={{
          backgroundImage:
            "radial-gradient(rgba(11,61,46,0.06) 1px, transparent 1px)",
          backgroundSize: "22px 22px",
        }}
      />

      <div className="relative z-[1] mx-auto w-full max-w-lg text-center">
        <Link
          to="/"
          className="group mx-auto mb-10 inline-flex items-center gap-2.5"
        >
          <span className="flex h-11 w-11 items-center justify-center overflow-hidden rounded-[5px] border border-[#0b3d2e]/10 bg-white p-1.5 shadow-[0_10px_30px_-18px_rgba(11,61,46,0.45)] transition-transform group-hover:scale-[1.03]">
            <img src={LOGO_SRC} alt="" className="h-full w-full object-contain" />
          </span>
          <img
            src={labelDark}
            alt="Moi Kanakku"
            className="h-9 w-auto object-contain"
          />
        </Link>

        <div className="mx-auto mb-6 flex h-14 w-14 items-center justify-center rounded-[5px] bg-[#0b3d2e] text-lime">
          <HugeiconsIcon
            icon={isError ? Alert02Icon : Search01Icon}
            size={28}
            strokeWidth={1.5}
          />
        </div>

        <h1 className="font-display text-3xl font-extrabold tracking-tighter text-[#0b3d2e] sm:text-4xl">
          {isError ? (
            <T ta="பக்கம் ஏற்றப்படவில்லை" en="This page didn't load" />
          ) : (
            <T ta="பக்கம் கிடைக்கவில்லை" en="Page not found" />
          )}
        </h1>

        <p className="mx-auto mt-3 max-w-[36ch] text-sm leading-relaxed text-[#0b3d2e]/70 sm:text-base">
          {isError ? (
            <T
              ta="எங்கள் பக்கத்தில் ஏதோ தவறு நடந்துவிட்டது. மீண்டும் முயலவும் அல்லது முகப்பிற்குச் செல்லவும்."
              en="Something went wrong on our end. Try refreshing, or head back home."
            />
          ) : (
            <T
              ta="நீங்கள் தேடிய பக்கம் இல்லை அல்லது மாற்றப்பட்டுள்ளது."
              en="The page you're looking for doesn't exist or has been moved."
            />
          )}
        </p>

        <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
          {isError && onRetry ? (
            <button
              type="button"
              onClick={onRetry}
              className="inline-flex h-11 items-center gap-2 rounded-[5px] bg-lime px-5 text-sm font-semibold text-ink transition-colors hover:bg-lime-bright active:scale-[0.98]"
            >
              <HugeiconsIcon icon={RefreshIcon} size={18} strokeWidth={1.5} />
              <T ta="மீண்டும் முயலவும்" en="Try again" />
            </button>
          ) : null}
          <Link
            to="/"
            className="inline-flex h-11 items-center gap-2 rounded-[5px] bg-[#0b3d2e] px-5 text-sm font-semibold text-white transition-colors hover:bg-black active:scale-[0.98]"
          >
            <HugeiconsIcon icon={Home01Icon} size={18} strokeWidth={1.5} />
            <T ta="முகப்புக்குச் செல்ல" en="Go home" />
          </Link>
        </div>
      </div>
    </div>
  );
}

export function StatusScreen(props: StatusScreenProps) {
  return (
    <LangProvider>
      <StatusBody {...props} />
    </LangProvider>
  );
}
