import { createFileRoute } from "@tanstack/react-router";
import { Check } from "lucide-react";
import { T } from "@/lib/lang";
import { PageHero, PlayButton, Steps } from "@/components/site";
import { buildPageHead } from "@/lib/seo";

export const Route = createFileRoute("/moi-at-hand")({
  head: () =>
    buildPageHead({
      title: "Moi at Hand - Phone Moi Gift Records | Moi Kanakku",
      description:
        "Record and review moi given and received on your phone with the free Moi Kanakku app.",
      path: "/moi-at-hand",
    }),
  component: Page,
});

export const howTo = [
  { ta: "Play Store-ல் Moi Kanakku | GK Tech தேடி install செய்யவும்", en: "Search Moi Kanakku | GK Tech on Play Store and install" },
  { ta: "ஆப்பில் profile உருவாக்கி உங்கள் விவரங்களை அமைக்கவும்", en: "Create your profile in the app and set your details" },
  { ta: "நிகழ்ச்சி சேர்த்து, மொய் செய்தவர்களின் விவரங்களை பதிவு செய்யவும்", en: "Add events and record who gave moi" },
  { ta: "விழா முடிந்ததும் report export / share செய்யவும்", en: "After the event, export or share the report" },
];

const feats = [
  ["கணக்கு வாரியான (உங்கள் பெயர் / குடும்பம்) மொய் பதிவு", "Account-wise (your name / family) moi records"],
  ["செய்த / பெற்ற மொய் பட்டியல் — தொகை, தேதி, நிகழ்ச்சி", "List of moi given/received — amount, date, event"],
  ["விசேஷங்கள் வரலாறு — என்ன மொய் வந்தது, எங்கு, எப்போது", "Event history — what moi came, where, when"],
  ["Encrypted data transfer & privacy controls", "Encrypted data transfer & privacy controls"],
];

function Page() {
  return (
    <>
      <PageHero eyebrow={<T ta="சேவை" en="Service" />} title={<T ta="மொய் — உங்களது கைகளில் அடக்கம்" en="Moi — in your hands" />}>
        <T ta="தினசரி நீங்கள் செய்த / வாங்கிய மொய் விவரங்களை நேரடியாக உங்கள் கைப்பேசியில் பதிவு செய்யவும், மீண்டும் பார்க்கவும், backup எடுக்கவும் உருவாக்கப்பட்ட Android பயன்பாடு." en="A dedicated Android app to record, review and back up the moi you give and receive, right on your phone." />
        <div className="mt-8"><PlayButton /></div>
      </PageHero>
      <section className="container-page grid gap-16 py-24 md:grid-cols-2">
        <div>
          <h2 className="mb-6 text-2xl font-extrabold"><T ta="முக்கிய வசதிகள்" en="Key features" /></h2>
          <ul className="space-y-4">
            {feats.map(([ta, en]) => (
              <li key={en} className="flex gap-3 rounded-md border border-border p-4">
                <Check size={20} className="shrink-0 text-primary" /> <T ta={ta} en={en} />
              </li>
            ))}
          </ul>
        </div>
        <div>
          <h2 className="mb-6 text-2xl font-extrabold"><T ta="எப்படி பயன்படுத்தலாம்?" en="How to use" /></h2>
          <Steps items={howTo} />
        </div>
      </section>
    </>
  );
}
