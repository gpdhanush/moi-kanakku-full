import { createFileRoute } from "@tanstack/react-router";
import { ShieldCheck } from "lucide-react";
import { T } from "@/lib/lang";
import { CtaBand, PageHero, Steps } from "@/components/site";
import { buildPageHead } from "@/lib/seo";

export const Route = createFileRoute("/ex-rupees")({
  head: () =>
    buildPageHead({
      title: "Ex Rupees - Old Moi Note Update | Moi Kanakku",
      description:
        "Old and torn moi notes retyped village-wise and alphabetically into fresh digital and printed records.",
      path: "/ex-rupees",
    }),
  component: Page,
});

function Page() {
  return (
    <>
      <PageHero eyebrow={<T ta="சேவை" en="Service" />} title={<T ta="பழைய மொய் நோட்டுகளை புதுப்பித்தல்" en="Ex Rupees — updating old moi notes" />}>
        <T ta="நீங்கள் வாங்கிய அல்லது செய்த மொய் நோட்டுகளை ஊர்வாரியாக அகர வரிசைப்படி பிரித்து புதிதாக டைப் செய்து நோட்டாக வழங்கப்படும்." en="Moi notes you received or gave are separated village-wise and alphabetically, newly typed and provided as notes." />
      </PageHero>
      <section className="container-page grid gap-16 py-24 md:grid-cols-2">
        <div>
          <p className="text-xl font-medium leading-relaxed">
            <T ta="பழைய கிழிந்த மொய் நோட்டுகளையும் புதிதாக டைப் செய்து நோட்டாக வழங்குகிறோம். உங்கள் பழைய நோட்டுகளை பாதுகாப்பாக வைத்துக் கொள்ளலாம்." en="Even old torn notes can be freshly typed. You can keep your original notes safely." />
          </p>
          <div className="mt-10 rounded-xl bg-accent p-7">
            <h3 className="mb-4 flex items-center gap-2 text-lg font-bold"><ShieldCheck className="text-primary" /> <T ta="பாதுகாப்பு" en="Safety" /></h3>
            <ul className="space-y-2 text-muted-foreground">
              <li>— <T ta="உங்கள் பழைய நோட்டுகள் பாதுகாப்பாக வைக்கப்படும்" en="Your old notes are kept safely" /></li>
              <li>— <T ta="டிஜிட்டல் பதிவு செய்யப்படும்" en="A digital record is made" /></li>
              <li>— <T ta="எப்போது வேண்டுமானாலும் பார்க்கலாம்" en="Can be viewed anytime" /></li>
            </ul>
          </div>
        </div>
        <div>
          <h2 className="mb-6 text-2xl font-extrabold"><T ta="எப்படி செயல்படுகிறது?" en="How it works" /></h2>
          <Steps items={[
            { ta: "பழைய மொய் நோட்டுகளை எங்களிடம் கொடுங்கள்", en: "Give us your old moi notes" },
            { ta: "ஊர்வாரியாக பிரித்து அகர வரிசைப்படி வரிசைப்படுத்தப்படும்", en: "Separated village-wise and sorted alphabetically" },
            { ta: "புதிதாக டைப் செய்து நோட்டாக வழங்கப்படும்", en: "Newly typed and provided as notes" },
          ]} />
        </div>
      </section>
      <CtaBand title={<T ta="பழைய நோட்டுகள் இருக்கிறதா?" en="Have old notes?" />} sub={<T ta="இன்றே புதுப்பிக்க எங்களை தொடர்புகொள்ளுங்கள்." en="Get in touch to update them today." />} label={<T ta="தொடர்புகொள்ள" en="Contact us" />} />
    </>
  );
}
