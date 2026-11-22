#!/usr/bin/env node
// Refreshes src/data/play-reviews.json from the public Google Play listing.
//
//   node scripts/fetch-play-reviews.mjs
//
// Play has no public reviews API. This reads the reviews Play shows on the
// listing page (usually the top 3 "most relevant") plus the overall rating.
// New reviews are MERGED into the existing JSON (hand-added reviews are kept),
// and the list is sorted newest first. Commit the regenerated JSON.
// The site never calls Play at runtime.
import { readFile, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";

const APP_ID = "com.renzo.moi";
const PAGE = `https://play.google.com/store/apps/details?id=${APP_ID}&hl=en_IN&gl=IN`;
const OUT = fileURLToPath(new URL("../src/data/play-reviews.json", import.meta.url));

// Reviews from the team itself are not shown as customer testimonials.
const EXCLUDE_AUTHORS = new Set(["gnana prakasam a"]);
const MIN_STARS = 4;

const decode = (s) =>
  s
    .replace(/&#(\d+);/g, (_, n) => String.fromCodePoint(Number(n)))
    .replace(/&#x([0-9a-f]+);/gi, (_, n) => String.fromCodePoint(parseInt(n, 16)))
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&amp;/g, "&")
    .trim();

const res = await fetch(PAGE, {
  headers: { "User-Agent": "Mozilla/5.0", "Accept-Language": "en-IN" },
});
if (!res.ok) throw new Error(`Play listing returned ${res.status}`);
const html = await res.text();

/** "16 September 2026" / "September 16, 2026" -> "2026-09-16" (null if unparseable). */
const toIsoDate = (raw) => {
  const d = new Date(`${raw} UTC`);
  return Number.isNaN(d.getTime()) ? null : d.toISOString().slice(0, 10);
};

const fetched = [];
for (const block of html.split('<div class="EGFGHd"').slice(1)) {
  const author = block.match(/class="X5PpBb">([^<]+)</)?.[1];
  const stars = Number(block.match(/aria-label="Rated (\d) stars? out of five stars"/)?.[1]);
  const date = block.match(/class="bp9Aid">([^<]+)</)?.[1];
  const text = block.match(/class="h3YV2d">([^<]+)</)?.[1];
  if (!author || !text || !stars) continue;
  const name = decode(author);
  if (EXCLUDE_AUTHORS.has(name.toLowerCase()) || stars < MIN_STARS) continue;
  fetched.push({
    author: name,
    stars,
    date: date ? toIsoDate(decode(date)) : null,
    text: decode(text),
  });
}

let existing = [];
try {
  existing = JSON.parse(await readFile(OUT, "utf8")).reviews ?? [];
} catch {
  // first run
}

const key = (r) => `${r.author.toLowerCase()}|${r.text.toLowerCase()}`;
const merged = new Map(existing.map((r) => [key(r), r]));
for (const r of fetched) {
  const prev = merged.get(key(r));
  // Fresh data wins, but keep a known star rating / date if Play omitted it.
  merged.set(key(r), {
    ...prev,
    ...r,
    stars: r.stars ?? prev?.stars ?? null,
    date: r.date ?? prev?.date ?? null,
  });
}
const reviews = [...merged.values()]
  .filter((r) => !EXCLUDE_AUTHORS.has(r.author.toLowerCase()))
  .sort((a, b) => (b.date ?? "").localeCompare(a.date ?? ""));

const rating = Number(html.match(/"ratingValue":"?([0-9.]+)/)?.[1]);
const ratingCount = Number(html.match(/"ratingCount":"?(\d+)/)?.[1]);

const data = {
  source: `https://play.google.com/store/apps/details?id=${APP_ID}`,
  fetchedAt: new Date().toISOString().slice(0, 10),
  rating: Number.isFinite(rating) ? Math.round(rating * 10) / 10 : null,
  ratingCount: Number.isFinite(ratingCount) ? ratingCount : null,
  reviews,
};

await writeFile(OUT, JSON.stringify(data, null, 2) + "\n");
console.log(
  `Fetched ${fetched.length}, wrote ${reviews.length} reviews (rating ${data.rating}, ${data.ratingCount} ratings) to ${OUT}`,
);
