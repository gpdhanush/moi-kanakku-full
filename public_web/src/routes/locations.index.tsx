import { Link, createFileRoute } from "@tanstack/react-router";
import { T } from "@/lib/lang";
import {
  SERVICE_CITIES,
  breadcrumbSchema,
  buildPageHead,
  jsonLdScript,
  localBusinessSchema,
  webPageSchema,
} from "@/lib/seo";

const title = "Moi Service Areas in Tamil Nadu | Moi Kanakku";
const description =
  "Moi Kanakku serves Dindigul, Madurai, Theni, Usilampatti, Trichy, Coimbatore, Chennai, Salem and nearby towns. Free moi app plus on-site moi function recording.";

export const Route = createFileRoute("/locations/")({
  head: () => {
    const head = buildPageHead({
      title,
      description,
      path: "/locations",
    });
    return {
      ...head,
      scripts: [
        jsonLdScript([
          webPageSchema({ path: "/locations", name: title, description }),
          localBusinessSchema(),
          breadcrumbSchema([
            { name: "Home", path: "/" },
            { name: "Locations", path: "/locations" },
          ]),
        ]),
      ],
    };
  },
  component: LocationsIndex,
});

function LocationsIndex() {
  return (
    <div className="bg-[linear-gradient(180deg,#f7faf8_0%,#ffffff_40%,#eef6e4_100%)]">
      <section className="mx-auto max-w-[1400px] px-4 py-14 sm:px-6 lg:px-8 md:py-20">
        <p className="text-sm font-semibold text-[#0b3d2e]/60">
          <T ta="சேவை பகுதிகள்" en="Service areas" />
        </p>
        <h1 className="mt-2 max-w-[20ch] font-display text-3xl font-extrabold tracking-tighter text-[#0b3d2e] sm:text-4xl md:text-5xl">
          <T
            ta="தமிழ்நாடு முழுவதும் மொய் பதிவு"
            en="Moi recording across Tamil Nadu"
          />
        </h1>
        <p className="mt-4 max-w-[60ch] text-base leading-relaxed text-[#0b3d2e]/75">
          <T
            ta="மொய் கணக்கு இலவச Android ஆப் மற்றும் விழா நாள் மொய் @ கம்ப்யூட்டர் சேவை. திண்டுக்கல் தளத்தில் இருந்து மதுரை, தேனி, உசிலம்பட்டி மற்றும் பிற நகரங்களுக்கு உதவுகிறோம். மொய், மொய் டெக், மொய் பரிசு, மொய் விழா என தேடினாலும் இங்கே தொடங்கலாம்."
            en="Moi Kanakku is the free Android moi app plus function-day Moi @ Computer service. Based in Dindigul, we support Madurai, Theni, Usilampatti and more. If you searched moi, moi tech, moi gift, or moi functions near you, start here."
          />
        </p>

        <ul className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {SERVICE_CITIES.map((city) => (
            <li key={city.slug}>
              <Link
                to="/locations/$city"
                params={{ city: city.slug }}
                className="block rounded-[5px] border border-[#0b3d2e]/10 bg-white/90 p-5 transition-colors hover:border-[#0b3d2e]/25 hover:bg-[#eef6e4]/50"
              >
                <h2 className="font-display text-xl font-bold tracking-tight text-[#0b3d2e]">
                  <T ta={city.nameTa} en={city.nameEn} />
                </h2>
                <p className="mt-1 text-xs font-medium text-[#0b3d2e]/50">
                  <T ta={city.districtTa} en={city.districtEn} />
                </p>
                <p className="mt-3 text-sm leading-relaxed text-[#0b3d2e]/70">
                  <T ta={city.focusTa} en={city.focusEn} />
                </p>
              </Link>
            </li>
          ))}
        </ul>

        <div className="mt-12 flex flex-wrap gap-3">
          <Link
            to="/moi-app"
            className="inline-flex h-11 items-center rounded-[5px] bg-lime px-5 text-sm font-semibold text-ink hover:bg-lime-bright active:scale-[0.98]"
          >
            <T ta="மொய் ஆப் பதிவிறக்கம்" en="Get the Moi App" />
          </Link>
          <Link
            to="/contact"
            className="inline-flex h-11 items-center rounded-[5px] bg-[#0b3d2e] px-5 text-sm font-semibold text-white hover:bg-black active:scale-[0.98]"
          >
            <T ta="விழா சேவை முன்பதிவு" en="Book function service" />
          </Link>
        </div>
      </section>
    </div>
  );
}
