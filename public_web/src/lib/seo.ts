/**
 * Moi Kanakku SEO foundation (claude-seo: technical, schema, local, page, agentic).
 * Set VITE_SITE_URL in production (e.g. https://moikanakku.com).
 */

export const SITE_URL = (
  (typeof import.meta !== "undefined" &&
    (import.meta.env?.["VITE_SITE_URL"] as string | undefined)) ||
  "https://moikanakku.com"
).replace(/\/$/, "");

export const SITE_NAME = "Moi Kanakku";
export const ORG_NAME = "GK Tech";
export const BRAND_ALIASES = [
  "Moi Kanakku",
  "மொய் கணக்கு",
  "Moi App",
  "Moi Tech",
  "மொய் ஆப்",
] as const;

export const DEFAULT_OG_IMAGE = `${SITE_URL}/logo.png`;
export const PHONE_E164 = "+917845456609";
export const CONTACT_EMAIL = "agprakash406@gmail.com";
export const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.renzo.moi";

/** Primary keyword clusters for content + titles (not stuffed into meta keywords). */
export const KEYWORD_CLUSTERS = {
  brand: [
    "Moi Kanakku",
    "மொய் கணக்கு",
    "moi app",
    "moi tech",
    "moi kanakku app",
  ],
  intent: [
    "moi functions",
    "moi gift",
    "moi gift register",
    "digital moi ledger",
    "wedding moi record",
    "மொய் பதிவு",
    "மொய் கணக்கு செயலி",
  ],
  local: [
    "moi dindigul",
    "moi madurai",
    "moi theni",
    "moi usilampatti",
    "moi service tamil nadu",
  ],
} as const;

export type ServiceCity = {
  slug: string;
  nameEn: string;
  nameTa: string;
  districtEn: string;
  districtTa: string;
  /** Unique local angle for E-E-A-T / thin-content gate */
  focusEn: string;
  focusTa: string;
  bodyEn: string;
  bodyTa: string;
};

/**
 * Curated service-area pages only (under the 30-page soft warning in seo-local).
 * Each city must keep unique body copy - do not clone templates.
 */
export const SERVICE_CITIES: ServiceCity[] = [
  {
    slug: "dindigul",
    nameEn: "Dindigul",
    nameTa: "திண்டுக்கல்",
    districtEn: "Dindigul district",
    districtTa: "திண்டுக்கல் மாவட்டம்",
    focusEn: "Home base for Moi Kanakku on-site function service and app support.",
    focusTa: "மொய் கணக்கு ஆன்-சைட் சேவை மற்றும் ஆப் ஆதரவின் தாய் இடம்.",
    bodyEn:
      "Families in Dindigul use Moi Kanakku to record wedding moi, puberty ceremony gifts, housewarming contributions, and engagement notes without paper confusion. Our team is based in Dindigul and can join your function for live computer entry, SMS receipts, and alphabet-wise guest lists. Search for moi in Dindigul, moi function register, or moi gift book and you will find Moi Kanakku built for Tamil family customs.",
    bodyTa:
      "திண்டுக்கல் குடும்பங்கள் திருமண மொய், பூப்புனித நீராட்டு பரிசு, கிருகப்பிரவேசம் மற்றும் நிச்சயதார்த்த குறிப்புகளை காகித குழப்பமின்றி மொய் கணக்கு ஆப் மூலம் பதிவு செய்கின்றனர். எங்கள் குழு திண்டுக்கல்லில் உள்ளது. விழாவில் நேரடி கணினி பதிவு, SMS ரசீது மற்றும் அகர வரிசை விருந்தினர் பட்டியல் உதவும்.",
  },
  {
    slug: "madurai",
    nameEn: "Madurai",
    nameTa: "மதுரை",
    districtEn: "Madurai district",
    districtTa: "மதுரை மாவட்டம்",
    focusEn: "Temple-city weddings and large guest lists need clear moi ledgers.",
    focusTa: "கோயில் நகர திருமணங்கள் மற்றும் பெரிய விருந்தினர் பட்டியலுக்கு தெளிவான மொய் கணக்கு தேவை.",
    bodyEn:
      "Madurai functions often bring relatives from many villages. Moi Kanakku helps Madurai hosts track moi given and moi received by name, place, and amount, then export a clean note later. Whether you need the free Android moi app or on-site moi @ computer help for a Madurai wedding hall, GK Tech supports moi gift and moi function recording across the city and nearby towns.",
    bodyTa:
      "மதுரை விழாக்களில் பல ஊர்களிலிருந்து உறவினர்கள் வருவர். மொய் கணக்கு பெயர், ஊர், தொகை வாரியாக கொடுத்த மொய் மற்றும் பெற்ற மொய்யைப் பின்பற்ற உதவும். இலவச Android மொய் ஆப் அல்லது மதுரை திருமண மண்டபத்தில் மொய் @ கம்ப்யூட்டர் சேவை தேவைப்பட்டால் GK Tech உதவும்.",
  },
  {
    slug: "theni",
    nameEn: "Theni",
    nameTa: "தேனி",
    districtEn: "Theni district",
    districtTa: "தேனி மாவட்டம்",
    focusEn: "Hill-district families keep village-wise moi history on phone.",
    focusTa: "மலை மாவட்ட குடும்பங்கள் ஊர்வாரி மொய் வரலாற்றை போனில் வைக்கின்றனர்.",
    bodyEn:
      "In Theni and nearby towns, moi is still a family duty across marriages and puberty ceremonies. Moi Kanakku is a simple digital moi ledger for Theni users who want Tamil-friendly entry, offline-friendly habits, and zero subscription cost. Book moi function support when you want staff to record gifts live, or use the Moi App yourself for everyday moi gift notes.",
    bodyTa:
      "தேனி மற்றும் அருகிலுள்ள ஊர்களில் திருமணம், பூப்புனித நீராட்டு போன்ற விழாக்களில் மொய் இன்னும் குடும்ப கடமையாக உள்ளது. மொய் கணக்கு தேனி பயனர்களுக்கான எளிய டிஜிட்டல் மொய் கணக்கு. தமிழ் உள்ளீடு, சந்தா இல்லாத இலவச ஆப். நேரடி பதிவு சேவை வேண்டுமானால் முன்பதிவு செய்யுங்கள்.",
  },
  {
    slug: "usilampatti",
    nameEn: "Usilampatti",
    nameTa: "உசிலம்பட்டி",
    districtEn: "Madurai district",
    districtTa: "மதுரை மாவட்டம்",
    focusEn: "Town and village functions around Usilampatti get the same clear records.",
    focusTa: "உசிலம்பட்டி சுற்று வட்டார விழாக்களுக்கும் அதே தெளிவான பதிவு.",
    bodyEn:
      "Usilampatti families often balance town guests and village relatives in one celebration. Moi Kanakku keeps moi gift amounts organised by person and place so return visits stay fair. Search moi Usilampatti, moi gift register, or moi tech app to reach the free Moi Kanakku Android app and local booking for function-day entry.",
    bodyTa:
      "உசிலம்பட்டி குடும்பங்கள் நகர விருந்தினர்களையும் ஊர் உறவினர்களையும் ஒரே விழாவில் சந்திக்கின்றனர். மொய் கணக்கு நபர் மற்றும் ஊர் வாரியாக மொய் பரிசுத் தொகைகளை ஒழுங்குபடுத்தி திரும்பக் கொடுக்கும் போது நியாயம் காக்க உதவும்.",
  },
  {
    slug: "trichy",
    nameEn: "Trichy",
    nameTa: "திருச்சி",
    districtEn: "Tiruchirappalli district",
    districtTa: "திருச்சிராப்பள்ளி மாவட்டம்",
    focusEn: "Central Tamil Nadu weddings need fast, accurate moi entry.",
    focusTa: "மத்திய தமிழ்நாடு திருமணங்களுக்கு வேகமான, துல்லியமான மொய் பதிவு தேவை.",
    bodyEn:
      "Tiruchirappalli (Trichy) hosts large community weddings where paper books get messy by evening. Moi Kanakku digitises moi functions for Trichy families: guest name, native place, amount, and notes in one place. Use the free moi app after the event, or request Moi @ Computer service when you want live receipts during the function.",
    bodyTa:
      "திருச்சியில் பெரிய சமூக திருமணங்களில் மாலைக்குள் காகித புத்தகங்கள் குழப்பமாகிவிடும். மொய் கணக்கு விருந்தினர் பெயர், ஊர், தொகை மற்றும் குறிப்புகளை ஒரே இடத்தில் வைக்கும். விழாவுக்குப் பிறகு இலவச மொய் ஆப் பயன்படுத்தலாம் அல்லது நேரடி ரசீதுக்கு மொய் @ கம்ப்யூட்டர் சேவை கேட்கலாம்.",
  },
  {
    slug: "coimbatore",
    nameEn: "Coimbatore",
    nameTa: "கோவை",
    districtEn: "Coimbatore district",
    districtTa: "கோயம்புத்தூர் மாவட்டம்",
    focusEn: "City halls and NRIs need shareable digital moi notes.",
    focusTa: "நகர மண்டபங்கள் மற்றும் வெளிநாட்டு உறவினர்களுக்கு பகிரக்கூடிய டிஜிட்டல் மொய் குறிப்புகள் தேவை.",
    bodyEn:
      "Coimbatore celebrations mix local guests and relatives from abroad. Moi Kanakku stores moi gift records you can revisit before the next function, without ads or paid plans. For Coimbatore wedding moi, puberty ceremony gifts, or housewarming contributions, start with the Android app or contact GK Tech for on-site support.",
    bodyTa:
      "கோவை விழாக்களில் உள்ளூர் விருந்தினர்களும் வெளிநாட்டு உறவினர்களும் கலந்துகொள்வர். மொய் கணக்கு அடுத்த விழாவுக்கு முன் பார்க்கக்கூடிய மொய் பரிசு பதிவுகளை விளம்பரம் அல்லது கட்டணத் திட்டமின்றி சேமிக்கும்.",
  },
  {
    slug: "chennai",
    nameEn: "Chennai",
    nameTa: "சென்னை",
    districtEn: "Chennai district",
    districtTa: "சென்னை மாவட்டம்",
    focusEn: "Metro families keep tradition with a modern moi ledger.",
    focusTa: "பெருநகர குடும்பங்கள் நவீன மொய் கணக்குடன் பாரம்பரியத்தை காக்கின்றனர்.",
    bodyEn:
      "Chennai hosts often manage multiple halls and tight schedules. Moi Kanakku is the free moi tech app for recording moi given and received across weddings and family occasions. If you searched moi Chennai, moi functions app, or digital moi gift book, Moi Kanakku is built for Tamil households who want clarity without complexity.",
    bodyTa:
      "சென்னை விழாக்களில் பல மண்டபங்கள் மற்றும் நேர அட்டவணை இருக்கும். மொய் கணக்கு திருமணம் மற்றும் குடும்ப விழாக்களில் கொடுத்த/பெற்ற மொய்யைப் பதிவு செய்யும் இலவச மொய் டெக் ஆப். தெளிவு வேண்டும், சிக்கல் வேண்டாம் என்ற குடும்பங்களுக்காக உருவாக்கப்பட்டது.",
  },
  {
    slug: "salem",
    nameEn: "Salem",
    nameTa: "சேலம்",
    districtEn: "Salem district",
    districtTa: "சேலம் மாவட்டம்",
    focusEn: "North-west Tamil Nadu families track return moi fairly.",
    focusTa: "வடமேற்கு தமிழ்நாடு குடும்பங்கள் திரும்பக் கொடுக்கும் மொய்யை நியாயமாக கணக்கிடுகின்றனர்.",
    bodyEn:
      "Salem and nearby towns still follow careful moi return customs. Moi Kanakku helps you see who gave what at past functions so your next gift stays respectful. Download the free Moi App, or ask about moi function day service when you want dedicated entry help in Salem.",
    bodyTa:
      "சேலம் மற்றும் அருகிலுள்ள ஊர்களில் திரும்பக் கொடுக்கும் மொய் வழக்கம் இன்னும் கவனமாக பின்பற்றப்படுகிறது. மொய் கணக்கு முந்தைய விழாக்களில் யார் என்ன கொடுத்தார்கள் என்பதைக் காட்டி அடுத்த பரிசை மரியாதையுடன் வைக்க உதவும்.",
  },
];

export function absoluteUrl(path = "/"): string {
  if (!path || path === "/") return SITE_URL;
  return `${SITE_URL}${path.startsWith("/") ? path : `/${path}`}`;
}

export function getCity(slug: string): ServiceCity | undefined {
  return SERVICE_CITIES.find((c) => c.slug === slug);
}

type PageSeoInput = {
  title: string;
  description: string;
  path: string;
  /** Override OG image */
  image?: string;
  type?: "website" | "article";
  noIndex?: boolean;
};

export function buildPageHead({
  title,
  description,
  path,
  image = DEFAULT_OG_IMAGE,
  type = "website",
  noIndex = false,
}: PageSeoInput) {
  const url = absoluteUrl(path);
  const meta: Array<Record<string, string>> = [
    { title },
    { name: "description", content: description },
    { name: "author", content: "GNANA PRAKASAM A" },
    { name: "robots", content: noIndex ? "noindex, nofollow" : "index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1" },
    { property: "og:type", content: type },
    { property: "og:site_name", content: SITE_NAME },
    { property: "og:locale", content: "ta_IN" },
    { property: "og:locale:alternate", content: "en_IN" },
    { property: "og:title", content: title },
    { property: "og:description", content: description },
    { property: "og:url", content: url },
    { property: "og:image", content: image },
    { property: "og:image:alt", content: `${SITE_NAME} - digital moi ledger` },
    { name: "twitter:card", content: "summary_large_image" },
    { name: "twitter:title", content: title },
    { name: "twitter:description", content: description },
    { name: "twitter:image", content: image },
    { name: "geo.region", content: "IN-TN" },
    { name: "geo.placename", content: "Dindigul, Tamil Nadu" },
  ];

  const links: Array<Record<string, string>> = [
    { rel: "canonical", href: url },
    { rel: "alternate", hrefLang: "ta", href: `${url}?lang=ta` },
    { rel: "alternate", hrefLang: "en", href: `${url}?lang=en` },
    { rel: "alternate", hrefLang: "x-default", href: url },
  ];

  return { meta, links };
}

export function jsonLdScript(data: Record<string, unknown> | Record<string, unknown>[]) {
  return {
    type: "application/ld+json",
    children: JSON.stringify(data),
  };
}

export function organizationSchema() {
  return {
    "@context": "https://schema.org",
    "@type": "Organization",
    "@id": `${SITE_URL}/#organization`,
    name: SITE_NAME,
    alternateName: [...BRAND_ALIASES],
    url: SITE_URL,
    logo: {
      "@type": "ImageObject",
      url: `${SITE_URL}/logo.png`,
    },
    email: CONTACT_EMAIL,
    telephone: PHONE_E164,
    address: {
      "@type": "PostalAddress",
      addressLocality: "Dindigul",
      addressRegion: "Tamil Nadu",
      postalCode: "624001",
      addressCountry: "IN",
    },
    areaServed: SERVICE_CITIES.map((c) => ({
      "@type": "City",
      name: c.nameEn,
    })),
    sameAs: [PLAY_STORE_URL],
    founder: {
      "@type": "Person",
      name: "GNANA PRAKASAM A",
    },
    parentOrganization: {
      "@type": "Organization",
      name: ORG_NAME,
    },
  };
}

export function websiteSchema() {
  return {
    "@context": "https://schema.org",
    "@type": "WebSite",
    "@id": `${SITE_URL}/#website`,
    name: SITE_NAME,
    alternateName: ["மொய் கணக்கு", "Moi App", "Moi Tech"],
    url: SITE_URL,
    inLanguage: ["ta", "en"],
    publisher: { "@id": `${SITE_URL}/#organization` },
  };
}

export function softwareAppSchema() {
  return {
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    "@id": `${SITE_URL}/moi-app#app`,
    name: SITE_NAME,
    alternateName: ["மொய் கணக்கு", "Moi App", "Moi Tech"],
    applicationCategory: "FinanceApplication",
    applicationSubCategory: "Gift and event ledger",
    operatingSystem: "Android",
    offers: {
      "@type": "Offer",
      price: "0",
      priceCurrency: "INR",
    },
    downloadUrl: PLAY_STORE_URL,
    installUrl: PLAY_STORE_URL,
    url: absoluteUrl("/moi-app"),
    description:
      "Free Android app to record moi given and moi received for Tamil family functions. No ads, no subscription.",
    inLanguage: ["ta", "en"],
    author: { "@id": `${SITE_URL}/#organization` },
  };
}

export function localBusinessSchema() {
  return {
    "@context": "https://schema.org",
    "@type": "ProfessionalService",
    "@id": `${SITE_URL}/#localbusiness`,
    name: `${SITE_NAME} Function Service`,
    image: `${SITE_URL}/logo.png`,
    url: SITE_URL,
    telephone: PHONE_E164,
    email: CONTACT_EMAIL,
    priceRange: "Free app / paid on-site service",
    address: {
      "@type": "PostalAddress",
      addressLocality: "Dindigul",
      addressRegion: "Tamil Nadu",
      postalCode: "624001",
      addressCountry: "IN",
    },
    geo: {
      "@type": "GeoCoordinates",
      latitude: 10.3673,
      longitude: 77.9803,
    },
    areaServed: SERVICE_CITIES.map((c) => ({
      "@type": "City",
      name: c.nameEn,
    })),
    serviceType: [
      "Moi function recording",
      "Moi gift register",
      "On-site moi computer entry",
      "Old moi note update",
    ],
    parentOrganization: { "@id": `${SITE_URL}/#organization` },
  };
}

export function breadcrumbSchema(items: { name: string; path: string }[]) {
  return {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: items.map((item, i) => ({
      "@type": "ListItem",
      position: i + 1,
      name: item.name,
      item: absoluteUrl(item.path),
    })),
  };
}

export function webPageSchema(opts: {
  path: string;
  name: string;
  description: string;
}) {
  return {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "@id": `${absoluteUrl(opts.path)}#webpage`,
    url: absoluteUrl(opts.path),
    name: opts.name,
    description: opts.description,
    isPartOf: { "@id": `${SITE_URL}/#website` },
    about: { "@id": `${SITE_URL}/#organization` },
    inLanguage: ["ta", "en"],
  };
}

export function serviceCitySchema(city: ServiceCity) {
  return {
    "@context": "https://schema.org",
    "@type": "Service",
    name: `Moi recording in ${city.nameEn}`,
    alternateName: `${city.nameTa} மொய் பதிவு`,
    serviceType: "Moi function and moi gift recording",
    provider: { "@id": `${SITE_URL}/#localbusiness` },
    areaServed: {
      "@type": "City",
      name: city.nameEn,
      containedInPlace: {
        "@type": "AdministrativeArea",
        name: city.districtEn,
      },
    },
    url: absoluteUrl(`/locations/${city.slug}`),
    description: city.bodyEn,
  };
}

export function sitemapPaths(): { path: string; priority: string; changefreq: string }[] {
  const staticPages = [
    { path: "/", priority: "1.0", changefreq: "weekly" },
    { path: "/moi-app", priority: "0.95", changefreq: "weekly" },
    { path: "/services", priority: "0.9", changefreq: "monthly" },
    { path: "/moi-at-computer", priority: "0.85", changefreq: "monthly" },
    { path: "/moi-at-hand", priority: "0.8", changefreq: "monthly" },
    { path: "/ex-rupees", priority: "0.8", changefreq: "monthly" },
    { path: "/about", priority: "0.7", changefreq: "monthly" },
    { path: "/contact", priority: "0.85", changefreq: "monthly" },
    { path: "/locations", priority: "0.9", changefreq: "weekly" },
    { path: "/privacy", priority: "0.3", changefreq: "yearly" },
    { path: "/terms", priority: "0.3", changefreq: "yearly" },
    { path: "/account-deletion", priority: "0.3", changefreq: "yearly" },
  ];
  const cities = SERVICE_CITIES.map((c) => ({
    path: `/locations/${c.slug}`,
    priority: "0.8",
    changefreq: "monthly",
  }));
  return [...staticPages, ...cities];
}
