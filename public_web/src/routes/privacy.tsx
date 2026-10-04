import { createFileRoute } from "@tanstack/react-router";
import { T } from "@/lib/lang";
import { PageHero } from "@/components/site";
import { buildPageHead } from "@/lib/seo";

export const Route = createFileRoute("/privacy")({
  head: () =>
    buildPageHead({
      title: "Privacy Policy | Moi Kanakku",
      description: "Privacy Policy for the Moi Kanakku Android app and website.",
      path: "/privacy",
    }),
  component: Privacy,
});

function Privacy() {
  return (
    <>
      <PageHero
        eyebrow={<T ta="கொள்கைகள்" en="Policies" />}
        title={<T ta="தனியுரிமைக் கொள்கை" en="Privacy Policy" />}
      />
      <section className="container-page max-w-3xl space-y-6 py-16 text-sm leading-relaxed text-slate-700">
        <p>
          <T
            ta="Moi Kanakku செயலி உங்கள் மொய் பதிவுகளை நிர்வகிக்க உதவுகிறது. நாங்கள் உங்கள் தனிப்பட்ட தகவல்களை மதிக்கிறோம்."
            en="Moi Kanakku helps you manage moi records. We respect your personal information."
          />
        </p>
        <h2 className="text-xl font-bold text-teal-900">
          <T ta="நாங்கள் சேகரிக்கும் தகவல்" en="Information we collect" />
        </h2>
        <p>
          <T
            ta="கணக்கு விவரங்கள் (பெயர், மின்னஞ்சல்), நீங்கள் பதிவு செய்யும் விழா மற்றும் மொய் தொகை விவரங்கள், மற்றும் செயலி செயல்பாட்டிற்கு தேவையான தொழில்நுட்ப தரவு."
            en="Account details (name, email), celebration and moi amount records you enter, and technical data needed for the app to work."
          />
        </p>
        <h2 className="text-xl font-bold text-teal-900">
          <T ta="தகவலை எவ்வாறு பயன்படுத்துகிறோம்" en="How we use information" />
        </h2>
        <p>
          <T
            ta="உங்கள் மொய் கணக்குகளை வழங்கவும், சேவையை மேம்படுத்தவும், ஆதரவு அளிக்கவும் மட்டுமே பயன்படுத்துகிறோம். உங்கள் தரவை விற்கமாட்டோம்."
            en="We use your data only to provide moi accounts, improve the service, and offer support. We do not sell your data."
          />
        </p>
        <h2 className="text-xl font-bold text-teal-900">
          <T ta="தொடர்பு" en="Contact" />
        </h2>
        <p>
          <T
            ta="தனியுரிமை குறித்த கேள்விகளுக்கு support மின்னஞ்சல் வழியாக தொடர்புகொள்ளுங்கள்."
            en="For privacy questions, contact us via the support email listed on the Contact page."
          />
        </p>
      </section>
    </>
  );
}
