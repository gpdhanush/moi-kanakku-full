import { n as require_jsx_runtime } from "./_libs/react+tanstack__react-query.mjs";
import { h as Link } from "./_libs/@tanstack/react-router+[...].mjs";
import { t as Route } from "./_slug-m66H6RfY.mjs";
import { S as ArrowLeft, _ as Check, x as ArrowUpRight } from "./_libs/lucide-react.mjs";
import { o as Section, r as FloatingActions, s as SiteShell, t as AppLogo } from "./_ssr/SiteShell-Bmws3asO.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/_slug-CwnywppR.js
var import_jsx_runtime = require_jsx_runtime();
function ProductPage() {
	const product = Route.useLoaderData();
	if (!product) return null;
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(SiteShell, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("main", { children: [
		/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
			className: "relative overflow-hidden border-b border-border pt-36 pb-20 sm:pt-44 sm:pb-28",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "absolute inset-0 -z-10 bg-hero-grid",
				"aria-hidden": "true"
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "mx-auto grid max-w-7xl gap-12 px-5 sm:px-6 lg:grid-cols-[1fr_0.8fr] lg:items-center lg:px-8",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Link, {
						to: "/",
						className: "inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ArrowLeft, { className: "size-4" }), " Back to G.K Tech"]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
						className: "mt-12 text-xs font-semibold uppercase tracking-[0.24em] text-accent",
						children: [
							product.category,
							" / ",
							product.status
						]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
						className: "mt-5 font-display text-6xl font-semibold leading-none text-foreground sm:text-8xl",
						children: product.name
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "mt-7 max-w-2xl text-lg leading-8 text-muted-foreground",
						children: product.longDescription
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "mt-9 flex flex-wrap gap-3",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("a", {
							href: "#contact",
							className: "inline-flex h-12 items-center gap-2 rounded-full bg-primary px-6 text-sm font-semibold text-primary-foreground",
							children: ["Talk about the product ", /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ArrowUpRight, { className: "size-4" })]
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
							href: "https://wa.me/919597883290?text=Hi%20G.K%20Tech%2C%20I%20would%20like%20to%20know%20more%20about%20Moi%20Kanakku.",
							target: "_blank",
							rel: "noreferrer",
							className: "inline-flex h-12 items-center rounded-full border border-border px-6 text-sm font-semibold text-foreground",
							children: "WhatsApp G.K Tech"
						})]
					})
				] }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "flex aspect-square items-center justify-center rounded-[2.5rem] border border-border bg-card p-10 shadow-cinematic",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(AppLogo, {
						variant: "icon",
						className: "size-64 max-w-full object-contain motion-safe:animate-float",
						priority: true
					})
				})]
			})]
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			eyebrow: "What it helps with",
			title: "A clearer record for important occasions.",
			description: "Moi Kanakku is designed for the moments where remembering who gave what, when and why matters.",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "grid gap-4 sm:grid-cols-2 lg:grid-cols-3",
				children: product.features.map((feature) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex gap-3 border-t border-border pt-5 text-base text-muted-foreground",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Check, { className: "mt-0.5 size-5 shrink-0 text-accent" }), feature]
				}, feature))
			})
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)("section", {
			id: "contact",
			className: "border-t border-border bg-surface py-20 sm:py-28",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "mx-auto max-w-7xl px-5 sm:px-6 lg:px-8",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "max-w-2xl",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "text-xs font-semibold uppercase tracking-[0.24em] text-accent",
							children: "Built by G.K Tech"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
							className: "mt-4 font-display text-5xl font-semibold text-foreground sm:text-7xl",
							children: "Useful software starts with a real problem."
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "mt-6 leading-8 text-muted-foreground",
							children: "Want to learn more about Moi Kanakku or discuss a product of your own? Start a conversation with the team."
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("a", {
							href: "mailto:jkirena@gmail.com",
							className: "mt-8 inline-flex items-center gap-2 rounded-full bg-primary px-6 py-3 text-sm font-semibold text-primary-foreground",
							children: ["Contact G.K Tech ", /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ArrowUpRight, { className: "size-4" })]
						})
					]
				})
			})
		})
	] }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(FloatingActions, {})] });
}
//#endregion
export { ProductPage as component };
