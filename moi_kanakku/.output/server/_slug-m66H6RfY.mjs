import { r as getProductBySlug } from "./_ssr/products-Dse4j5hE.mjs";
import { f as lazyRouteComponent, p as createFileRoute } from "./_libs/@tanstack/react-router+[...].mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/_slug-m66H6RfY.js
var $$splitNotFoundComponentImporter = () => import("./_slug-wMzCjR9-.mjs");
var $$splitComponentImporter = () => import("./_slug-CwnywppR.mjs");
var Route = createFileRoute("/products/$slug")({
	loader: ({ params }) => getProductBySlug(params.slug),
	head: ({ loaderData }) => ({ meta: [{ title: loaderData ? `${loaderData.name} | G.K Tech` : "Product | G.K Tech" }, {
		name: "description",
		content: loaderData?.longDescription ?? "Explore products built by G.K Tech."
	}] }),
	component: lazyRouteComponent($$splitComponentImporter, "component"),
	notFoundComponent: lazyRouteComponent($$splitNotFoundComponentImporter, "notFoundComponent")
});
//#endregion
export { Route as t };
