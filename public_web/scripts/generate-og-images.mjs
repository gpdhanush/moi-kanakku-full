#!/usr/bin/env node
// Generates 1200x630 Open Graph images into public/og/*.jpg.
//
//   node scripts/generate-og-images.mjs            # all images
//   node scripts/generate-og-images.mjs default    # one image by key
//
// Renders an HTML template with a locally installed Chrome (headless), then
// converts to JPEG with macOS `sips`. Set CHROME_PATH to use another browser.
// Keep keys in sync with OG_IMAGES in src/lib/seo.ts.
import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const ROOT = fileURLToPath(new URL("..", import.meta.url));
const OUT_DIR = join(ROOT, "public", "og");
const LOGO = join(ROOT, "public", "logo.png");
const PHOTOS = {
  wedding: join(ROOT, "src", "assets", "home", "wedding.webp"),
  engagements: join(ROOT, "src", "assets", "home", "engagements.webp"),
  grihapravesam: join(ROOT, "src", "assets", "home", "grihapravesam.webp"),
  ear: join(ROOT, "src", "assets", "home", "ear.webp"),
  family: join(ROOT, "src", "assets", "home", "other-family-occasions.webp"),
  baby: join(ROOT, "src", "assets", "home", "baby-showers.webp"),
};

const CITIES = [
  ["dindigul", "திண்டுக்கல்", "Dindigul", "wedding"],
  ["madurai", "மதுரை", "Madurai", "engagements"],
  ["theni", "தேனி", "Theni", "ear"],
  ["usilampatti", "உசிலம்பட்டி", "Usilampatti", "family"],
  ["trichy", "திருச்சி", "Trichy", "grihapravesam"],
  ["coimbatore", "கோவை", "Coimbatore", "baby"],
  ["chennai", "சென்னை", "Chennai", "wedding"],
  ["salem", "சேலம்", "Salem", "engagements"],
];

/** key -> { ta, en, photo } */
const IMAGES = {
  default: {
    ta: "மொய் கணக்கு இனி உங்கள் கையில்!",
    en: "Free moi app from Dindigul",
    photo: "wedding",
  },
  "moi-app": {
    ta: "மொய் கணக்குகள் உங்கள் உள்ளங்கையில்",
    en: "Free Android moi app",
    photo: "engagements",
  },
  services: { ta: "மொய் விழா சேவைகள்", en: "Moi function services", photo: "grihapravesam" },
  "moi-at-computer": {
    ta: "விழாவில் நேரடி மொய் பதிவு",
    en: "Moi @ Computer: live entry",
    photo: "wedding",
  },
  "moi-at-hand": { ta: "போனிலேயே மொய் பதிவு", en: "Moi at Hand: phone records", photo: "ear" },
  "ex-rupees": { ta: "பழைய மொய் நோட்டு புதுப்பிப்பு", en: "Old moi note update", photo: "family" },
  about: {
    ta: "நமது கலாச்சாரம், நவீன முறையில்",
    en: "About Moi Kanakku · GK Tech",
    photo: "family",
  },
  contact: {
    ta: "உங்கள் விழாவுக்கு முன்பதிவு செய்யுங்கள்",
    en: "Book moi function service",
    photo: "baby",
  },
  locations: {
    ta: "திண்டுக்கல் முதல் தமிழ்நாடு வரை",
    en: "Moi service across Tamil Nadu",
    photo: "grihapravesam",
  },
  ...Object.fromEntries(
    CITIES.map(([slug, ta, en, photo]) => [
      `city-${slug}`,
      { ta: `${ta} மொய் கணக்கு`, en: `Moi Kanakku ${en}`, photo, place: `${en}, Tamil Nadu` },
    ]),
  ),
};

const esc = (s) =>
  s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);

function template({ ta, en, photo, place = "Dindigul, Tamil Nadu" }) {
  // Long Tamil headlines wrap to 4 lines at 60px; step down so they clear the logo.
  const size = ta.length > 30 ? 48 : ta.length > 22 ? 54 : 60;
  const logo = pathToFileURL(LOGO).href;
  const img = pathToFileURL(PHOTOS[photo]).href;
  return `<!doctype html><html><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Anek+Tamil:wght@600;700;800&family=Space+Grotesk:wght@500;700&family=Plus+Jakarta+Sans:wght@500;600;700&display=block" rel="stylesheet">
<style>
  *{box-sizing:border-box;margin:0;padding:0}
  html,body{width:1200px;height:630px;overflow:hidden}
  body{position:relative;background:#0b3d2e;color:#fff;font-family:"Plus Jakarta Sans",sans-serif}
  .glow{position:absolute;left:-160px;top:-220px;width:760px;height:620px;border-radius:50%;
    background:radial-gradient(closest-side,rgba(144,208,31,.30),rgba(144,208,31,0));}
  .grid{position:absolute;inset:0;
    background-image:linear-gradient(rgba(255,255,255,.045) 1px,transparent 1px),linear-gradient(90deg,rgba(255,255,255,.045) 1px,transparent 1px);
    background-size:48px 48px;-webkit-mask-image:linear-gradient(90deg,#000 0%,transparent 75%)}
  .left{position:absolute;left:72px;top:64px;bottom:60px;width:610px;display:flex;flex-direction:column}
  .brand{display:flex;align-items:center;gap:16px}
  .chip{width:64px;height:64px;border-radius:16px;background:#fff;padding:6px;display:flex}
  .chip img{width:100%;height:100%;object-fit:contain}
  .name{font-family:"Space Grotesk";font-weight:700;font-size:34px;letter-spacing:-.5px}
  .name small{display:block;font-family:"Anek Tamil";font-weight:600;font-size:20px;color:rgba(255,255,255,.7);letter-spacing:0;margin-top:-2px}
  h1{margin-top:auto;font-family:"Anek Tamil";font-weight:800;font-size:60px;line-height:1.18}
  .en{margin-top:14px;font-family:"Space Grotesk";font-weight:700;font-size:36px;color:#90d01f;letter-spacing:-.5px}
  .pills{margin-top:34px;display:flex;gap:10px;flex-wrap:wrap}
  .pill{border:1.5px solid rgba(144,208,31,.45);background:rgba(144,208,31,.12);color:#c8f06b;
    border-radius:999px;padding:8px 18px;font-weight:600;font-size:20px}
  .photo{position:absolute;right:56px;top:56px;width:420px;height:518px;border-radius:28px;overflow:hidden;
    border:3px solid rgba(144,208,31,.6);box-shadow:0 30px 60px -20px rgba(0,0,0,.6);transform:rotate(2deg)}
  .photo img{width:100%;height:100%;object-fit:cover}
  .photo::after{content:"";position:absolute;inset:0;background:linear-gradient(to top,rgba(11,61,46,.55),transparent 45%)}
  .url{position:absolute;right:80px;bottom:76px;z-index:2;font-family:"Space Grotesk";font-weight:700;font-size:22px;
    background:#90d01f;color:#0b3d2e;padding:8px 16px;border-radius:12px;transform:rotate(2deg)}
</style></head><body>
<div class="glow"></div><div class="grid"></div>
<div class="left">
  <div class="brand"><div class="chip"><img src="${logo}"></div>
    <div class="name">Moi Kanakku<small>மொய் கணக்கு</small></div></div>
  <h1 style="font-size:${size}px">${esc(ta)}</h1>
  <div class="en">${esc(en)}</div>
  <div class="pills"><span class="pill">100% Free · No ads</span><span class="pill">Android</span><span class="pill">${esc(place)}</span></div>
</div>
<div class="photo"><img src="${img}"></div>
<div class="url">moikanakku.com</div>
</body></html>`;
}

const CHROME =
  process.env.CHROME_PATH ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
if (!existsSync(CHROME)) throw new Error(`Chrome not found at ${CHROME}. Set CHROME_PATH.`);

const only = process.argv.slice(2);
const keys = only.length ? only : Object.keys(IMAGES);
mkdirSync(OUT_DIR, { recursive: true });
const work = mkdtempSync(join(tmpdir(), "moi-og-"));

try {
  for (const key of keys) {
    const spec = IMAGES[key];
    if (!spec) throw new Error(`Unknown OG image key: ${key}`);
    const html = join(work, `${key}.html`);
    const png = join(work, `${key}.png`);
    writeFileSync(html, template(spec));
    execFileSync(
      CHROME,
      [
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--allow-file-access-from-files",
        "--force-device-scale-factor=1",
        "--window-size=1200,630",
        "--virtual-time-budget=8000",
        `--user-data-dir=${join(work, "profile")}`,
        `--screenshot=${png}`,
        pathToFileURL(html).href,
      ],
      { stdio: "ignore" },
    );
    const jpg = join(OUT_DIR, `${key}.jpg`);
    execFileSync("sips", ["-s", "format", "jpeg", "-s", "formatOptions", "82", png, "--out", jpg], {
      stdio: "ignore",
    });
    console.log(`og/${key}.jpg  ${(readFileSync(jpg).length / 1024).toFixed(0)} KB`);
  }
} finally {
  rmSync(work, { recursive: true, force: true });
}
