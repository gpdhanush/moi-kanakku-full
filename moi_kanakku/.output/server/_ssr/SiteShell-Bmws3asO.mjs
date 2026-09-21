import { n as __toESM } from "../_runtime.mjs";
import { n as require_react } from "../_libs/@radix-ui/react-compose-refs+[...].mjs";
import { n as require_jsx_runtime } from "../_libs/react+tanstack__react-query.mjs";
import { a as useTheme, i as products } from "./products-Dse4j5hE.mjs";
import { a as Sun, b as Bot, c as Send, d as Moon, f as Monitor, g as Mail, h as MapPin, l as Plus, m as Menu, p as MessageCircle, t as X, u as Phone, v as Calendar } from "../_libs/lucide-react.mjs";
import { t as Slot } from "../_libs/radix-ui__react-slot.mjs";
import { n as clsx, t as cva } from "../_libs/class-variance-authority+clsx.mjs";
import { t as twMerge } from "../_libs/tailwind-merge.mjs";
import { t as Lenis } from "../_libs/lenis.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/SiteShell-Bmws3asO.js
var import_react = /* @__PURE__ */ __toESM(require_react());
var import_jsx_runtime = require_jsx_runtime();
var logoSources = {
	light: {
		icon: "/images/light-logo.png",
		wordmark: "/images/label-dark.png"
	},
	dark: {
		icon: "/images/dark-logo.png",
		wordmark: "/images/light-text.png"
	}
};
function AppLogo({ variant = "full", className = "", priority = false }) {
	const [isDark, setIsDark] = (0, import_react.useState)(false);
	(0, import_react.useEffect)(() => {
		const root = document.documentElement;
		const updateTheme = () => setIsDark(root.classList.contains("dark"));
		updateTheme();
		const observer = new MutationObserver(updateTheme);
		observer.observe(root, {
			attributes: true,
			attributeFilter: ["class"]
		});
		return () => observer.disconnect();
	}, []);
	const theme = isDark ? logoSources.dark : logoSources.light;
	if (variant === "icon") return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
		src: theme.icon,
		alt: "Moi Kanakku",
		className,
		loading: priority ? "eager" : "lazy"
	});
	if (variant === "wordmark") return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
		src: theme.wordmark,
		alt: "Moi Kanakku",
		className,
		loading: priority ? "eager" : "lazy"
	});
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
		className: `inline-flex items-center gap-3 ${className}`,
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
			src: theme.icon,
			alt: "",
			"aria-hidden": "true",
			className: "size-9 object-contain",
			loading: priority ? "eager" : "lazy"
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
			src: theme.wordmark,
			alt: "Moi Kanakku",
			className: "h-7 w-auto max-w-[10rem] object-contain",
			loading: priority ? "eager" : "lazy"
		})]
	});
}
function cn(...inputs) {
	return twMerge(clsx(inputs));
}
var buttonVariants = cva("inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium cursor-pointer transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 disabled:cursor-not-allowed [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0", {
	variants: {
		variant: {
			default: "bg-primary text-primary-foreground shadow hover:bg-primary/90",
			destructive: "bg-destructive text-destructive-foreground shadow-sm hover:bg-destructive/90",
			outline: "border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground",
			secondary: "bg-secondary text-secondary-foreground shadow-sm hover:bg-secondary/80",
			ghost: "hover:bg-accent hover:text-accent-foreground",
			link: "text-primary underline-offset-4 hover:underline"
		},
		size: {
			default: "h-9 px-4 py-2",
			sm: "h-8 rounded-md px-3 text-xs",
			lg: "h-10 rounded-md px-8",
			icon: "h-9 w-9"
		}
	},
	defaultVariants: {
		variant: "default",
		size: "default"
	}
});
var Button = import_react.forwardRef(({ className, variant, size, asChild = false, ...props }, ref) => {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(asChild ? Slot : "button", {
		className: cn(buttonVariants({
			variant,
			size,
			className
		})),
		ref,
		...props
	});
});
Button.displayName = "Button";
var Input = import_react.forwardRef(({ className, type, ...props }, ref) => {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
		type,
		className: cn("flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-base shadow-sm transition-colors file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-foreground placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50 md:text-sm", className),
		ref,
		...props
	});
});
Input.displayName = "Input";
var services = [
	{
		id: "web-development",
		index: "01",
		title: "WEB\nEXPERIENCES",
		label: "Web Development",
		description: "Performance-led websites, portals, dashboards and commerce experiences designed for conversion and trust.",
		technologies: [
			"React",
			"Next.js",
			"TypeScript",
			"APIs"
		],
		cta: "Discuss a website",
		whatsappKey: "website"
	},
	{
		id: "mobile-apps",
		index: "02",
		title: "MOBILE\nAPPLICATIONS",
		label: "Mobile Application Development",
		description: "Cross-platform mobile apps with practical workflows, polished interfaces and reliable backend integration.",
		technologies: [
			"Flutter",
			"Android",
			"iOS",
			"Cloud"
		],
		cta: "Plan an app",
		whatsappKey: "mobile"
	},
	{
		id: "custom-software",
		index: "03",
		title: "CUSTOM\nSOFTWARE",
		label: "Custom Software Development",
		description: "Business software, internal tools, automations and product platforms built around real operational needs.",
		technologies: [
			"Node.js",
			"MySQL",
			"REST APIs",
			"Security"
		],
		cta: "Build software",
		whatsappKey: "software"
	},
	{
		id: "ai-automation",
		index: "04",
		title: "AI &\nAUTOMATION",
		label: "AI Solutions & Automation",
		description: "AI assistants, workflow automation and intelligent tools that reduce repetitive work and speed up decisions.",
		technologies: [
			"AI",
			"Automation",
			"Integrations",
			"Data"
		],
		cta: "Explore AI",
		whatsappKey: "ai"
	},
	{
		id: "ui-ux-design",
		index: "05",
		title: "UI / UX\nDESIGN",
		label: "UI/UX Design",
		description: "Human-friendly product design systems, prototypes and interfaces that make complex software feel simple.",
		technologies: [
			"UX Strategy",
			"Design Systems",
			"Prototypes",
			"Testing"
		],
		cta: "Design with us",
		whatsappKey: "general"
	}
];
var serviceOptions = [
	"Web Development",
	"Mobile Application Development",
	"Custom Software Development",
	"UI/UX Design",
	"Backend & API Development",
	"AI Solutions",
	"AI Automation",
	"Business Automation",
	"Cloud Solutions",
	"Database Solutions",
	"Maintenance & Support",
	"Digital Product Development"
];
var company = {
	name: "G.K Tech",
	brand: "G.K TECH",
	contactPerson: "Kiruba",
	phone: "+91 95978 83290",
	whatsappNumber: "919597883290",
	email: "jkirena@gmail.com",
	address: "Velachery, Chennai - 600042, Tamil Nadu, India",
	shortAddress: "Velachery, Chennai - 600042",
	tagline: "We build digital products that move businesses forward.",
	subline: "Web. Mobile. Software. AI.",
	googleMeetUrl: "https://meet.google.com/new"
};
var navigationItems = [
	{
		label: "Services",
		href: "/#services"
	},
	{
		label: "Products",
		href: "/#products"
	},
	{
		label: "Work",
		href: "/#work"
	},
	{
		label: "About",
		href: "/#about"
	},
	{
		label: "Testimonials",
		href: "/#testimonials"
	},
	{
		label: "Contact",
		href: "/#contact"
	}
];
var whatsappMessages = {
	general: "Hi G.K Tech, I would like to know more about your services.",
	website: "Hi G.K Tech, I am interested in developing a website.",
	mobile: "Hi G.K Tech, I am interested in developing a mobile application.",
	software: "Hi G.K Tech, I am interested in developing custom software.",
	ai: "Hi G.K Tech, I am interested in AI and automation solutions.",
	product: "Hi G.K Tech, I would like to know more about Moi Kanakku."
};
function AIButton({ onClick }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
		type: "button",
		size: "icon",
		className: "size-12 rounded-full bg-primary text-primary-foreground shadow-cinematic",
		onClick,
		"aria-label": "Open G.K Tech AI assistant",
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Bot, { "aria-hidden": "true" })
	});
}
function AIInput({ onSend }) {
	const [value, setValue] = (0, import_react.useState)("");
	const submit = (event) => {
		event.preventDefault();
		const message = value.trim();
		if (!message) return;
		onSend(message);
		setValue("");
	};
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("form", {
		onSubmit: submit,
		className: "flex gap-2",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
			value,
			onChange: (event) => setValue(event.target.value),
			placeholder: "Ask G.K Tech AI",
			"aria-label": "Ask G.K Tech AI"
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
			type: "submit",
			size: "icon",
			className: "shrink-0",
			"aria-label": "Send message",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Send, { "aria-hidden": "true" })
		})]
	});
}
function AIMessage({ message }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		className: cn("flex", message.role === "user" ? "justify-end" : "justify-start"),
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
			className: cn("max-w-[85%] rounded-lg px-4 py-3 text-sm leading-6", message.role === "user" ? "bg-primary text-primary-foreground" : "bg-secondary text-secondary-foreground"),
			children: message.content
		})
	});
}
function AIQuickAction({ label, onSelect }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
		type: "button",
		variant: "secondary",
		size: "sm",
		className: "rounded-full",
		onClick: () => onSelect(label),
		children: label
	});
}
var quickActions = [
	"Build a website",
	"Build a mobile app",
	"Develop custom software",
	"AI & automation",
	"Learn about our products",
	"Get a project estimate",
	"Book a meeting",
	"Talk to G.K Tech"
];
function getMockResponse(message) {
	const lower = message.toLowerCase();
	if (lower.includes("moi") || lower.includes("product")) return "Moi Kanakku is G.K Tech’s function-gift money tracking product. You can explore it on the product page or start a WhatsApp conversation for details.";
	if (lower.includes("meeting") || lower.includes("book")) return "You can use the Book Meeting action to choose a service, date and time. This prototype shows the meeting confirmation flow.";
	if (lower.includes("mobile")) return "G.K Tech builds mobile applications for business workflows, digital products and customer-facing experiences.";
	if (lower.includes("ai") || lower.includes("automation")) return "G.K Tech can design AI assistants, automation flows and practical AI solutions connected to your business process.";
	return "G.K Tech can help with websites, mobile apps, custom software, UI/UX, backend APIs, cloud, databases, AI and automation. Share your idea and we can guide the next step.";
}
function AIChat({ onClose }) {
	const initialMessages = (0, import_react.useMemo)(() => [{
		id: "intro",
		role: "assistant",
		content: "G.K Tech AI — How can we help? Choose a quick action or ask about services, products, estimates or meetings."
	}], []);
	const [messages, setMessages] = (0, import_react.useState)(initialMessages);
	const send = (content) => {
		const userMessage = {
			id: `user-${Date.now()}`,
			role: "user",
			content
		};
		const assistantMessage = {
			id: `assistant-${Date.now()}`,
			role: "assistant",
			content: getMockResponse(content)
		};
		setMessages((current) => [
			...current,
			userMessage,
			assistantMessage
		]);
	};
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
		className: "fixed bottom-24 right-4 z-50 flex h-[32rem] w-[calc(100vw-2rem)] max-w-md flex-col rounded-lg border border-border bg-popover shadow-cinematic sm:right-6",
		"aria-label": "G.K Tech AI assistant",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("header", {
				className: "flex items-center justify-between border-b border-border p-4",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex items-center gap-3",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "flex size-10 items-center justify-center rounded-full bg-primary text-primary-foreground",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Bot, { "aria-hidden": "true" })
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
						className: "font-semibold text-popover-foreground",
						children: "G.K Tech AI"
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-xs text-muted-foreground",
						children: "Frontend prototype"
					})] })]
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
					type: "button",
					variant: "ghost",
					size: "icon",
					onClick: onClose,
					"aria-label": "Close AI assistant",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { "aria-hidden": "true" })
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "flex-1 space-y-3 overflow-y-auto p-4",
				children: messages.map((message) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(AIMessage, { message }, message.id))
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "border-t border-border p-4",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "mb-3 flex flex-wrap gap-2",
					children: quickActions.slice(0, 4).map((action) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(AIQuickAction, {
						label: action,
						onSelect: send
					}, action))
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(AIInput, { onSend: send })]
			})
		]
	});
}
function getWhatsAppUrl(message) {
	return `https://wa.me/${company.whatsappNumber}?text=${encodeURIComponent(message)}`;
}
function WhatsAppButton({ message = whatsappMessages.general, compact = false }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
		asChild: true,
		size: compact ? "icon" : "default",
		className: compact ? "size-12 rounded-full bg-whatsapp text-whatsapp-foreground shadow-cinematic" : "rounded-full bg-whatsapp text-whatsapp-foreground hover:bg-whatsapp/90",
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("a", {
			href: getWhatsAppUrl(message),
			target: "_blank",
			rel: "noreferrer",
			"aria-label": "Start WhatsApp chat with G.K Tech",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(MessageCircle, { "aria-hidden": "true" }), !compact && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: "WhatsApp" })]
		})
	});
}
function FloatingActions() {
	const [assistantOpen, setAssistantOpen] = (0, import_react.useState)(false);
	const [mobileOpen, setMobileOpen] = (0, import_react.useState)(false);
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [
		assistantOpen && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(AIChat, { onClose: () => setAssistantOpen(false) }),
		/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "fixed bottom-6 right-6 z-40 hidden flex-col gap-3 md:flex",
			"aria-label": "Quick actions",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)(AIButton, { onClick: () => setAssistantOpen((open) => !open) }),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)(WhatsAppButton, { compact: true }),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
					asChild: true,
					size: "icon",
					className: "size-12 rounded-full bg-secondary text-secondary-foreground shadow-cinematic",
					"aria-label": "Book a meeting",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
						href: "#meeting",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Calendar, { "aria-hidden": "true" })
					})
				})
			]
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "fixed bottom-5 right-5 z-40 md:hidden",
			children: [mobileOpen && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "mb-3 grid gap-3",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(AIButton, { onClick: () => setAssistantOpen((open) => !open) }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(WhatsAppButton, { compact: true }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
						asChild: true,
						size: "icon",
						className: "size-12 rounded-full bg-secondary text-secondary-foreground shadow-cinematic",
						"aria-label": "Book a meeting",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
							href: "#meeting",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Calendar, { "aria-hidden": "true" })
						})
					})
				]
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
				type: "button",
				size: "icon",
				className: "size-13 rounded-full bg-primary text-primary-foreground shadow-cinematic",
				onClick: () => setMobileOpen((open) => !open),
				"aria-label": "Toggle quick actions",
				children: mobileOpen ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { "aria-hidden": "true" }) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Plus, { "aria-hidden": "true" })
			})]
		})
	] });
}
function PageContainer({ children, className }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		className: cn("mx-auto w-full max-w-7xl px-5 sm:px-6 lg:px-8", className),
		children
	});
}
function Section({ id, eyebrow, title, description, children, className, containerClassName }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("section", {
		id,
		className: cn("relative py-20 sm:py-28", className),
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(PageContainer, {
			className: containerClassName,
			children: [(eyebrow || title || description) && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "mb-12 max-w-3xl",
				"data-reveal": true,
				children: [
					eyebrow && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "mb-4 text-xs font-semibold uppercase tracking-[0.24em] text-accent",
						children: eyebrow
					}),
					title && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
						className: "font-display text-4xl font-semibold leading-tight text-foreground sm:text-6xl",
						children: title
					}),
					description && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "mt-5 text-base leading-8 text-muted-foreground sm:text-lg",
						children: description
					})
				]
			}), children]
		})
	});
}
function Footer() {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("footer", {
		className: "border-t border-border bg-surface py-14",
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(PageContainer, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "grid gap-10 lg:grid-cols-[1.3fr_0.7fr_0.7fr_0.8fr]",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
					href: "/",
					"aria-label": `${company.name} home`,
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(AppLogo, {
						variant: "wordmark",
						className: "h-8 w-auto max-w-[11rem] object-contain"
					})
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "mt-5 max-w-sm font-display text-3xl font-semibold leading-tight text-foreground",
					children: "We build digital products that move businesses forward."
				})] }),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
					className: "text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground",
					children: "Services"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("ul", {
					className: "mt-5 space-y-3 text-sm text-muted-foreground",
					children: services.slice(0, 5).map((service) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
						href: `/#services`,
						className: "hover:text-foreground",
						children: service.label
					}) }, service.id))
				})] }),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
					className: "text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground",
					children: "Explore"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("ul", {
					className: "mt-5 space-y-3 text-sm text-muted-foreground",
					children: [navigationItems.map((item) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
						href: item.href,
						className: "hover:text-foreground",
						children: item.label
					}) }, item.label)), products.map((product) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
						href: `/products/${product.slug}`,
						className: "hover:text-foreground",
						children: product.name
					}) }, product.id))]
				})] }),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("address", {
					className: "not-italic",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
						className: "text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground",
						children: "Contact"
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "mt-5 space-y-4 text-sm text-muted-foreground",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("a", {
								className: "flex items-center gap-3 hover:text-foreground",
								href: getWhatsAppUrl(whatsappMessages.general),
								target: "_blank",
								rel: "noreferrer",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(MessageCircle, {
									className: "size-4 text-accent",
									"aria-hidden": "true"
								}), " WhatsApp"]
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("a", {
								className: "flex items-center gap-3 hover:text-foreground",
								href: `mailto:${company.email}`,
								children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Mail, {
										className: "size-4 text-accent",
										"aria-hidden": "true"
									}),
									" ",
									company.email
								]
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("a", {
								className: "flex items-center gap-3 hover:text-foreground",
								href: `tel:${company.phone.replace(/\s/g, "")}`,
								children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Phone, {
										className: "size-4 text-accent",
										"aria-hidden": "true"
									}),
									" ",
									company.phone
								]
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
								className: "flex items-start gap-3",
								children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)(MapPin, {
										className: "mt-0.5 size-4 text-accent",
										"aria-hidden": "true"
									}),
									" Velachery,",
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("br", {}),
									"Chennai - 600042"
								]
							})
						]
					})]
				})
			]
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "mt-12 flex flex-col justify-between gap-3 border-t border-border pt-6 text-sm text-muted-foreground sm:flex-row",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { children: "© G.K Tech. All rights reserved." }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { children: "Premium digital products, software and AI solutions." })]
		})] })
	});
}
function MobileMenu({ open, onClose }) {
	if (!open) return null;
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "fixed inset-0 z-50 bg-background/95 backdrop-blur-2xl lg:hidden",
		role: "dialog",
		"aria-modal": "true",
		"aria-label": "Mobile navigation",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex h-20 items-center justify-between px-5",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
					href: "/",
					onClick: onClose,
					"aria-label": `${company.name} home`,
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(AppLogo, {
						variant: "wordmark",
						className: "h-7 w-auto max-w-[9rem] object-contain",
						priority: true
					})
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
					type: "button",
					variant: "ghost",
					size: "icon",
					onClick: onClose,
					"aria-label": "Close menu",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { "aria-hidden": "true" })
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("nav", {
				className: "grid px-5 pt-10",
				children: navigationItems.map((item) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
					href: item.href,
					onClick: onClose,
					className: "border-t border-border py-6 font-display text-4xl font-semibold text-foreground",
					children: item.label
				}, item.label))
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "absolute inset-x-5 bottom-8 grid gap-3",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
					asChild: true,
					className: "h-12 rounded-full bg-primary text-primary-foreground",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
						href: "#contact",
						onClick: onClose,
						children: "Start a Project"
					})
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
					asChild: true,
					variant: "secondary",
					className: "h-12 rounded-full",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
						href: getWhatsAppUrl(whatsappMessages.general),
						target: "_blank",
						rel: "noreferrer",
						onClick: onClose,
						children: "WhatsApp G.K Tech"
					})
				})]
			})
		]
	});
}
function ThemeToggle() {
	const { theme, resolvedTheme, setTheme } = useTheme();
	const nextTheme = theme === "system" ? resolvedTheme === "dark" ? "light" : "dark" : theme === "dark" ? "light" : "system";
	const Icon = theme === "system" ? Monitor : resolvedTheme === "dark" ? Moon : Sun;
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
		type: "button",
		variant: "ghost",
		size: "icon",
		className: "size-10 rounded-full",
		onClick: () => setTheme(nextTheme),
		"aria-label": `Use ${nextTheme} theme`,
		title: `Use ${nextTheme} theme`,
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Icon, {
			"aria-hidden": "true",
			className: "size-4"
		})
	});
}
function Navbar() {
	const [scrolled, setScrolled] = (0, import_react.useState)(false);
	const [open, setOpen] = (0, import_react.useState)(false);
	(0, import_react.useEffect)(() => {
		const handleScroll = () => setScrolled(window.scrollY > 40);
		handleScroll();
		window.addEventListener("scroll", handleScroll, { passive: true });
		return () => window.removeEventListener("scroll", handleScroll);
	}, []);
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("header", {
		className: scrolled ? "fixed inset-x-0 top-0 z-40 border-b border-border bg-background/78 backdrop-blur-2xl transition-all duration-500" : "fixed inset-x-0 top-0 z-40 bg-transparent transition-all duration-500",
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: scrolled ? "mx-auto flex h-16 max-w-7xl items-center justify-between px-5 transition-all sm:px-6 lg:px-8" : "mx-auto flex h-20 max-w-7xl items-center justify-between px-5 transition-all sm:px-6 lg:px-8",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
					href: "/",
					"aria-label": `${company.name} home`,
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(AppLogo, {
						variant: "wordmark",
						className: "h-7 w-auto max-w-[9rem] object-contain",
						priority: true
					})
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("nav", {
					className: "hidden items-center gap-7 lg:flex",
					"aria-label": "Main navigation",
					children: navigationItems.map((item) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
						href: item.href,
						className: "text-sm text-muted-foreground transition-colors hover:text-foreground",
						children: item.label
					}, item.label))
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex items-center gap-2",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ThemeToggle, {}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "hidden lg:block",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
							asChild: true,
							className: "h-10 rounded-full bg-primary px-5 text-primary-foreground hover:bg-primary/90",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
								href: "#contact",
								children: "Start a Project"
							})
						})
					})]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
					type: "button",
					variant: "ghost",
					size: "icon",
					className: "lg:hidden",
					onClick: () => setOpen(true),
					"aria-label": "Open menu",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Menu, { "aria-hidden": "true" })
				})
			]
		})
	}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(MobileMenu, {
		open,
		onClose: () => setOpen(false)
	})] });
}
function useSmoothScroll() {
	(0, import_react.useEffect)(() => {
		if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
		const lenis = new Lenis({
			duration: 1.05,
			easing: (time) => Math.min(1, 1.001 - Math.pow(2, -10 * time)),
			smoothWheel: true
		});
		let rafId = 0;
		const raf = (time) => {
			lenis.raf(time);
			rafId = requestAnimationFrame(raf);
		};
		rafId = requestAnimationFrame(raf);
		return () => {
			cancelAnimationFrame(rafId);
			lenis.destroy();
		};
	}, []);
}
function SiteShell({ children }) {
	useSmoothScroll();
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "min-h-screen bg-background text-foreground selection:bg-primary selection:text-primary-foreground",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Navbar, {}),
			children,
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Footer, {})
		]
	});
}
//#endregion
export { PageContainer as a, cn as c, serviceOptions as d, services as f, Input as i, company as l, Button as n, Section as o, whatsappMessages as p, FloatingActions as r, SiteShell as s, AppLogo as t, getWhatsAppUrl as u };
