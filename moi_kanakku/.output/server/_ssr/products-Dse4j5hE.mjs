import { n as __toESM } from "../_runtime.mjs";
import { n as require_react } from "../_libs/@radix-ui/react-compose-refs+[...].mjs";
import { n as require_jsx_runtime } from "../_libs/react+tanstack__react-query.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/products-Dse4j5hE.js
var import_react = /* @__PURE__ */ __toESM(require_react());
var import_jsx_runtime = require_jsx_runtime();
var ThemeContext = (0, import_react.createContext)(null);
function ThemeProvider({ children }) {
	const [theme, setThemeState] = (0, import_react.useState)("system");
	const [resolvedTheme, setResolvedTheme] = (0, import_react.useState)("light");
	(0, import_react.useEffect)(() => {
		const savedTheme = window.localStorage.getItem("moi-kanakku-theme");
		setThemeState(savedTheme === "light" || savedTheme === "dark" || savedTheme === "system" ? savedTheme : "system");
	}, []);
	(0, import_react.useEffect)(() => {
		const mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");
		const applyTheme = () => {
			const nextResolvedTheme = theme === "system" ? mediaQuery.matches ? "dark" : "light" : theme;
			document.documentElement.classList.toggle("dark", nextResolvedTheme === "dark");
			document.documentElement.style.colorScheme = nextResolvedTheme;
			setResolvedTheme(nextResolvedTheme);
		};
		applyTheme();
		mediaQuery.addEventListener("change", applyTheme);
		return () => mediaQuery.removeEventListener("change", applyTheme);
	}, [theme]);
	const setTheme = (nextTheme) => {
		setThemeState(nextTheme);
		window.localStorage.setItem("moi-kanakku-theme", nextTheme);
	};
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ThemeContext.Provider, {
		value: {
			theme,
			resolvedTheme,
			setTheme
		},
		children
	});
}
function useTheme() {
	const context = (0, import_react.useContext)(ThemeContext);
	if (!context) throw new Error("useTheme must be used within ThemeProvider");
	return context;
}
function getInitialThemeScript() {
	return `(() => { try { const saved = localStorage.getItem("moi-kanakku-theme"); const dark = saved === "dark" || (saved !== "light" && matchMedia("(prefers-color-scheme: dark)").matches); document.documentElement.classList.toggle("dark", dark); document.documentElement.style.colorScheme = dark ? "dark" : "light"; } catch {} })()`;
}
var products = [{
	id: "moi-kanakku",
	slug: "moi-kanakku",
	name: "Moi Kanakku",
	description: "A simple and powerful way to record, manage and track function gifts and money given or received.",
	longDescription: "Moi Kanakku helps families keep a clear personal record of money given and received during weddings, birthdays, housewarming ceremonies, festivals and other family functions. It is designed for quick entry, clean tracking and confident follow-up.",
	category: "Personal Finance / Family Functions",
	status: "In development",
	features: [
		"Record money given and received",
		"Organize entries by family function",
		"Track people, dates and amounts",
		"Review balances with simple summaries",
		"Designed for Tamil Nadu family occasions"
	],
	technologies: [
		"Mobile App",
		"Secure Data",
		"Reports",
		"Family Workflows"
	]
}];
function getProductBySlug(slug) {
	return products.find((product) => product.slug === slug);
}
//#endregion
export { useTheme as a, products as i, getInitialThemeScript as n, getProductBySlug as r, ThemeProvider as t };
