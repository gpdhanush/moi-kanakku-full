import { createFileRoute, Link } from "@tanstack/react-router";
import { T } from "@/lib/lang";
import { EMAIL, PageHero } from "@/components/site";
import { buildPageHead } from "@/lib/seo";

export const Route = createFileRoute("/account-deletion")({
  head: () =>
    buildPageHead({
      title: "Account and Data Deletion | Moi Kanakku",
      description: "How to request account and data deletion for Moi Kanakku.",
      path: "/account-deletion",
    }),
  component: AccountDeletion,
});

function AccountDeletion() {
  return (
    <>
      <PageHero
        eyebrow={<T ta="கணக்கு" en="Account" />}
        title={<T ta="கணக்கு & தரவு நீக்கம்" en="Account & Data Deletion" />}
      />
      <section className="container-page max-w-3xl space-y-6 py-16 text-sm leading-relaxed text-slate-700">
        <p>
          <T
            ta="உங்கள் Moi Kanakku கணக்கையும் தொடர்புடைய தரவையும் நீக்கக் கோரலாம்."
            en="You can request deletion of your Moi Kanakku account and related data."
          />
        </p>
        <h2 className="text-xl font-bold text-teal-900">
          <T ta="எப்படி கோரலாம்" en="How to request deletion" />
        </h2>
        <ol className="list-decimal space-y-2 pl-5">
          <li>
            <T
              ta="செயலியில் பதிவு செய்த மின்னஞ்சல் முகவரியிலிருந்து எங்களுக்கு எழுதுங்கள்."
              en="Email us from the address registered in the app."
            />
          </li>
          <li>
            <T
              ta={`பொருள் வரியில் "Account Deletion Request" என குறிப்பிடுங்கள்.`}
              en={`Use the subject line "Account Deletion Request".`}
            />
          </li>
          <li>
            <T
              ta="கணக்கு பெயர் மற்றும் தொடர்பு எண்ணைச் சேர்க்கவும்."
              en="Include your account name and contact number."
            />
          </li>
        </ol>
        <p>
          <T ta="மின்னஞ்சல்:" en="Email:" />{" "}
          <a className="font-semibold text-teal-900 underline" href={`mailto:${EMAIL}`}>
            {EMAIL}
          </a>
        </p>
        <h2 className="text-xl font-bold text-teal-900">
          <T ta="என்ன நீக்கப்படும்" en="What will be deleted" />
        </h2>
        <p>
          <T
            ta="கணக்கு விவரங்கள், விழா பதிவுகள் மற்றும் மொய் தொகை தரவு — சட்டப்பூர்வ தேவைகள் இருந்தால் தவிர."
            en="Account details, celebration records, and moi amount data — unless retention is required by law."
          />
        </p>
        <p>
          <Link to="/contact" className="font-semibold text-gold-600 hover:underline">
            <T ta="தொடர்பு பக்கத்திற்குச் செல்லவும்" en="Go to Contact page" />
          </Link>
        </p>
      </section>
    </>
  );
}
