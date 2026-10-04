import { Link, createFileRoute, notFound } from "@tanstack/react-router";
import { T } from "@/lib/lang";
import {
  SERVICE_CITIES,
  breadcrumbSchema,
  buildPageHead,
  getCity,
  jsonLdScript,
  serviceCitySchema,
  webPageSchema,
} from "@/lib/seo";

export const Route = createFileRoute("/locations/$city")({
  beforeLoad: ({ params }) => {
    if (!getCity(params.city)) throw notFound();
  },
  head: ({ params }) => {
    const city = getCity(params.city);
    if (!city) return {};
    const title = `Moi in ${city.nameEn} | Moi Kanakku மொய் கணக்கு`;
    const description = `Digital moi ledger and moi function service in ${city.nameEn}, ${city.districtEn}. Free Moi App for moi gift records. ${city.focusEn}`;
    const path = `/locations/${city.slug}`;
    const head = buildPageHead({ title, description, path });
    return {
      ...head,
      scripts: [
        jsonLdScript([
          webPageSchema({ path, name: title, description }),
          serviceCitySchema(city),
          breadcrumbSchema([
            { name: "Home", path: "/" },
            { name: "Locations", path: "/locations" },
            { name: city.nameEn, path },
          ]),
        ]),
      ],
    };
  },
  component: LocationCityPage,
});

function LocationCityPage() {
  const { city: slug } = Route.useParams();
  const city = getCity(slug);
  if (!city) return null;

  const others = SERVICE_CITIES.filter((c) => c.slug !== city.slug).slice(0, 4);

  return (
    <div className="bg-[linear-gradient(180deg,#f7faf8_0%,#ffffff_50%,#eef6e4_100%)]">
      <article className="mx-auto max-w-[900px] px-4 py-14 sm:px-6 lg:px-8 md:py-20">
        <nav aria-label="Breadcrumb" className="text-sm text-[#0b3d2e]/55">
          <Link to="/" className="hover:text-[#0b3d2e]">
            <T ta="முகப்பு" en="Home" />
          </Link>
          <span className="mx-2">/</span>
          <Link to="/locations" className="hover:text-[#0b3d2e]">
            <T ta="இடங்கள்" en="Locations" />
          </Link>
          <span className="mx-2">/</span>
          <span className="text-[#0b3d2e]">
            <T ta={city.nameTa} en={city.nameEn} />
          </span>
        </nav>

        <h1 className="mt-4 font-display text-3xl font-extrabold tracking-tighter text-[#0b3d2e] sm:text-4xl md:text-5xl">
          <T
            ta={`${city.nameTa}வில் மொய் கணக்கு`}
            en={`Moi Kanakku in ${city.nameEn}`}
          />
        </h1>
        <p className="mt-3 text-sm font-semibold text-[#0b3d2e]/55">
          <T ta={city.districtTa} en={city.districtEn} />
        </p>
        <p className="mt-4 text-lg font-medium leading-relaxed text-[#0b3d2e]">
          <T ta={city.focusTa} en={city.focusEn} />
        </p>
        <p className="mt-6 text-base leading-relaxed text-[#0b3d2e]/75">
          <T ta={city.bodyTa} en={city.bodyEn} />
        </p>

        <section className="mt-10 space-y-4 border-t border-[#0b3d2e]/10 pt-8">
          <h2 className="font-display text-2xl font-bold tracking-tight text-[#0b3d2e]">
            <T
              ta={`${city.nameTa}வில் எப்படி தொடங்குவது`}
              en={`How to start in ${city.nameEn}`}
            />
          </h2>
          <ol className="list-decimal space-y-3 pl-5 text-sm leading-relaxed text-[#0b3d2e]/75">
            <li>
              <T
                ta="Google Play இல் Moi Kanakku (மொய் கணக்கு) ஆப்பை இலவசமாக நிறுவுங்கள்."
                en="Install the free Moi Kanakku app from Google Play."
              />
            </li>
            <li>
              <T
                ta="திருமணம், நிச்சயதார்த்தம் அல்லது பிற விழாவுக்கான மொய் பரிசுகளைப் பதிவு செய்யுங்கள்."
                en="Record moi gifts for weddings, engagements, and other family functions."
              />
            </li>
            <li>
              <T
                ta="விழா நாளில் நேரடி பதிவு வேண்டுமானால் தொடர்பு பக்கத்தில் முன்பதிவு செய்யுங்கள்."
                en="Need live entry on function day? Book from the contact page."
              />
            </li>
          </ol>
        </section>

        <div className="mt-10 flex flex-wrap gap-3">
          <Link
            to="/moi-app"
            className="inline-flex h-11 items-center rounded-[5px] bg-lime px-5 text-sm font-semibold text-ink hover:bg-lime-bright active:scale-[0.98]"
          >
            <T ta="மொய் ஆப்" en="Moi App" />
          </Link>
          <Link
            to="/contact"
            className="inline-flex h-11 items-center rounded-[5px] bg-[#0b3d2e] px-5 text-sm font-semibold text-white hover:bg-black active:scale-[0.98]"
          >
            <T ta="தொடர்பு" en="Contact" />
          </Link>
          <Link
            to="/services"
            className="inline-flex h-11 items-center rounded-[5px] border border-[#0b3d2e]/20 px-5 text-sm font-semibold text-[#0b3d2e] hover:bg-[#eef6e4] active:scale-[0.98]"
          >
            <T ta="சேவைகள்" en="Services" />
          </Link>
        </div>

        <section className="mt-14">
          <h2 className="font-display text-xl font-bold text-[#0b3d2e]">
            <T ta="பிற பகுதிகள்" en="Other areas" />
          </h2>
          <ul className="mt-4 flex flex-wrap gap-2">
            {others.map((c) => (
              <li key={c.slug}>
                <Link
                  to="/locations/$city"
                  params={{ city: c.slug }}
                  className="inline-flex rounded-[5px] border border-[#0b3d2e]/12 bg-white px-3 py-1.5 text-sm font-medium text-[#0b3d2e] hover:bg-[#eef6e4]"
                >
                  <T ta={c.nameTa} en={c.nameEn} />
                </Link>
              </li>
            ))}
            <li>
              <Link
                to="/locations"
                className="inline-flex rounded-[5px] border border-[#0b3d2e]/12 bg-white px-3 py-1.5 text-sm font-medium text-[#0b3d2e] hover:bg-[#eef6e4]"
              >
                <T ta="அனைத்தும்" en="All areas" />
              </Link>
            </li>
          </ul>
        </section>
      </article>
    </div>
  );
}
