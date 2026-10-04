import { createFileRoute } from "@tanstack/react-router";
import { T } from "@/lib/lang";
import { PageHero } from "@/components/site";
import { buildPageHead } from "@/lib/seo";

export const Route = createFileRoute("/terms")({
  head: () =>
    buildPageHead({
      title: "Terms of Use | Moi Kanakku",
      description: "Terms of Use for the Moi Kanakku Android app and website.",
      path: "/terms",
    }),
  component: Terms,
});

function Terms() {
  return (
    <>
      <PageHero
        eyebrow={<T ta="கொள்கைகள்" en="Policies" />}
        title={<T ta="பயன்பாட்டு விதிகள்" en="Terms of Use" />}
      />
      <section className="container-page max-w-3xl space-y-6 py-16 text-sm leading-relaxed text-slate-700">
        <p>
          <T
            ta="Moi Kanakku செயலியைப் பயன்படுத்துவதன் மூலம் இந்த விதிகளை ஏற்கிறீர்கள். செயலி அனைவருக்கும் இலவசம்."
            en="By using the Moi Kanakku app, you agree to these terms. The app is free for everyone."
          />
        </p>
        <h2 className="text-xl font-bold text-teal-900">
          <T ta="பயன்பாடு" en="Use of the service" />
        </h2>
        <p>
          <T
            ta="செயலியை சட்டப்பூர்வமான குடும்ப மொய் பதிவு நோக்கங்களுக்காக மட்டும் பயன்படுத்த வேண்டும். தவறான அல்லது தீங்கு விளைவிக்கும் பயன்பாடு தடைசெய்யப்பட்டுள்ளது."
            en="Use the app only for lawful family moi record-keeping. Misuse or harmful activity is not allowed."
          />
        </p>
        <h2 className="text-xl font-bold text-teal-900">
          <T ta="உங்கள் பொறுப்பு" en="Your responsibility" />
        </h2>
        <p>
          <T
            ta="நீங்கள் உள்ளிடும் தொகை மற்றும் விவரங்களின் துல்லியத்திற்கு நீங்களே பொறுப்பு. முக்கியமான பதிவுகளின் காப்புப்பிரதியை வைத்திருங்கள்."
            en="You are responsible for the accuracy of amounts and details you enter. Keep backups of important records."
          />
        </p>
        <h2 className="text-xl font-bold text-teal-900">
          <T ta="மாற்றங்கள்" en="Changes" />
        </h2>
        <p>
          <T
            ta="தேவைப்படும்போது இந்த விதிகளைப் புதுப்பிக்கலாம். புதுப்பிப்புகள் இந்தப் பக்கத்தில் வெளியிடப்படும்."
            en="We may update these terms when needed. Updates will be posted on this page."
          />
        </p>
      </section>
    </>
  );
}
