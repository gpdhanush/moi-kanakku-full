import { createFileRoute } from "@tanstack/react-router";
import { Receipt, ShieldAlert, Calculator, Printer } from "lucide-react";
import { T } from "@/lib/lang";
import { CtaBand, PageHero } from "@/components/site";
import { buildPageHead } from "@/lib/seo";

export const Route = createFileRoute("/moi-at-computer")({
  head: () =>
    buildPageHead({
      title: "Moi @ Computer - Live Function Moi Entry | Moi Kanakku",
      description:
        "Live moi entry at your function with receipts, SMS and printed notes. Moi function service from Dindigul across Tamil Nadu.",
      path: "/moi-at-computer",
    }),
  component: Page,
});

const items = [
  [Receipt, "ரசீது மற்றும் SMS", "Receipt and SMS", "மொய் செய்த அடுத்த கணமே உடனடி ரசீது மற்றும் குறுஞ்செய்தி அனுப்பப்படும்.", "Immediately after moi is given, a receipt and SMS are sent."],
  [ShieldAlert, "கள்ள நோட்டு கண்டறிதல்", "Fake note detection", "கள்ள ரூபாய் நோட்டுகள் இருந்தால் உடனடியாக கண்டறியப்படும்.", "Counterfeit notes are detected promptly when present."],
  [Calculator, "துல்லிய கணக்கீடு", "Accurate calculation", "மொய் பணத்தை அதிவேகமாகவும் துல்லியமாகவும் கணக்கிட்டு தரப்படும்.", "Moi amounts are calculated quickly and accurately."],
  [Printer, "மொய் நோட்டாக வழங்குதல்", "Moi as printed notes", "விசேஷம் முடிந்தவுடன் ஊர்வாரி, அகர வரிசையில் பிரித்து பிரிண்ட் எடுத்து நோட்டு வழங்கப்படும். CD / memory card-லும் ஏற்றப்படும்.", "After the event, details are sorted village-wise and alphabetically, printed as notes, and also copied to CD / memory card."],
] as const;

function Page() {
  return (
    <>
      <PageHero eyebrow={<T ta="சேவை" en="Service" />} title={<T ta="மொய் @ கம்ப்யூட்டர்" en="Moi @ Computer" />}>
        <T ta="உங்கள் இல்லங்களில் நடைபெறும் அனைத்து சுப நிகழ்ச்சிகளுக்கும் நேரடியாக வந்து கம்ப்யூட்டர் வழியாக மொய் டைப் செய்து தரப்படும்." en="For auspicious events at your home, we come on-site and type moi on a computer." />
      </PageHero>
      <section className="container-page py-24">
        <p className="mb-12 max-w-3xl text-xl font-medium leading-relaxed">
          <T ta="செய்த மற்றும் வாங்கிய மொய்களை ஒரே LOGIN-ல் SYSTEM-ல் பதிவு செய்யலாம். விழா முடியும் வரை துல்லியமாக கணக்கிட்டு நோட்டாக வழங்குகிறோம்." en="Given and received moi can be recorded in the system with one login. We calculate accurately until the function ends and hand it over as notes." />
        </p>
        <div className="grid gap-5 md:grid-cols-2">
          {items.map(([Icon, ta, en, dta, den]) => (
            <div key={en} className="rounded-xl border border-border p-7 transition-colors hover:border-primary">
              <span className="mb-5 flex h-12 w-12 items-center justify-center rounded-md bg-accent"><Icon size={22} /></span>
              <h3 className="text-lg font-bold"><T ta={ta} en={en} /></h3>
              <p className="mt-2 text-muted-foreground"><T ta={dta} en={den} /></p>
            </div>
          ))}
        </div>
      </section>
      <CtaBand title={<T ta="உங்கள் தேதியை முன்பதிவு செய்யுங்கள்" en="Reserve your date" />} sub={<T ta="நேரடி மொய் பதிவுக்கு எங்கள் குழு வரும்." en="Our team will come for live moi entry." />} label={<T ta="முன்பதிவு செய்ய" en="Book now" />} />
    </>
  );
}
