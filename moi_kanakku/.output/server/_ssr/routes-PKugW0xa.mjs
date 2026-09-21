import { n as __toESM } from "../_runtime.mjs";
import { n as require_react } from "../_libs/@radix-ui/react-compose-refs+[...].mjs";
import { n as require_jsx_runtime } from "../_libs/react+tanstack__react-query.mjs";
import { i as products } from "./products-Dse4j5hE.mjs";
import { h as Link } from "../_libs/@tanstack/react-router+[...].mjs";
import { C as ArrowDown, c as Send, i as UsersRound, n as WalletCards, o as Star, r as Video, s as Smartphone, x as ArrowUpRight, y as CalendarPlus } from "../_libs/lucide-react.mjs";
import { a as PageContainer, c as cn, d as serviceOptions, f as services, i as Input, l as company, n as Button, o as Section, p as whatsappMessages, r as FloatingActions, s as SiteShell, t as AppLogo, u as getWhatsAppUrl } from "./SiteShell-Bmws3asO.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/routes-PKugW0xa.js
var import_react = /* @__PURE__ */ __toESM(require_react());
var import_jsx_runtime = require_jsx_runtime();
var Textarea = import_react.forwardRef(({ className, ...props }, ref) => {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("textarea", {
		className: cn("flex min-h-[60px] w-full rounded-md border border-input bg-transparent px-3 py-2 text-base shadow-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50 md:text-sm", className),
		ref,
		...props
	});
});
Textarea.displayName = "Textarea";
function ContactForm() {
	const [submitted, setSubmitted] = (0, import_react.useState)(false);
	const handleSubmit = (event) => {
		event.preventDefault();
		setSubmitted(true);
	};
	if (submitted) return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "rounded-lg border border-primary bg-primary/10 p-8",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
				className: "text-xs font-semibold uppercase tracking-[0.2em] text-accent",
				children: "Enquiry sent"
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
				className: "mt-4 font-display text-3xl font-semibold text-foreground",
				children: "Thank you. G.K Tech will contact you shortly."
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
				className: "mt-4 leading-7 text-muted-foreground",
				children: "Your project details are saved in this session preview. Backend delivery can connect this form to an API later."
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
				type: "button",
				className: "mt-6 rounded-full",
				onClick: () => setSubmitted(false),
				children: "Send another enquiry"
			})
		]
	});
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("form", {
		onSubmit: handleSubmit,
		className: "grid gap-4",
		"aria-label": "Contact enquiry form",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "grid gap-4 sm:grid-cols-2",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
					required: true,
					name: "name",
					placeholder: "Name",
					"aria-label": "Name"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
					name: "company",
					placeholder: "Company",
					"aria-label": "Company"
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "grid gap-4 sm:grid-cols-2",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
					required: true,
					type: "email",
					name: "email",
					placeholder: "Email",
					"aria-label": "Email"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
					required: true,
					type: "tel",
					name: "phone",
					placeholder: "Phone",
					"aria-label": "Phone"
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "grid gap-4 sm:grid-cols-2",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("select", {
					required: true,
					name: "service",
					"aria-label": "Service",
					className: "h-11 rounded-md border border-input bg-background px-3 text-sm text-foreground focus:outline-none focus:ring-1 focus:ring-ring",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("option", {
						value: "",
						children: "Service"
					}), serviceOptions.map((service) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("option", {
						value: service,
						children: service
					}, service))]
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("select", {
					name: "projectType",
					"aria-label": "Project type",
					className: "h-11 rounded-md border border-input bg-background px-3 text-sm text-foreground focus:outline-none focus:ring-1 focus:ring-ring",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("option", {
							value: "",
							children: "Project type"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("option", { children: "New project" }),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("option", { children: "Existing project improvement" }),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("option", { children: "Maintenance and support" }),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("option", { children: "Product development" })
					]
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("select", {
				name: "budget",
				"aria-label": "Budget",
				className: "h-11 rounded-md border border-input bg-background px-3 text-sm text-foreground focus:outline-none focus:ring-1 focus:ring-ring",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("option", {
						value: "",
						children: "Budget"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("option", { children: "Under ₹50,000" }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("option", { children: "₹50,000 - ₹1,50,000" }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("option", { children: "₹1,50,000 - ₹5,00,000" }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("option", { children: "₹5,00,000+" })
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Textarea, {
				required: true,
				name: "message",
				placeholder: "Tell us about your idea",
				"aria-label": "Message",
				className: "min-h-32"
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
				type: "file",
				name: "attachment",
				"aria-label": "Attachment"
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Button, {
				type: "submit",
				className: "h-12 rounded-full bg-primary text-primary-foreground",
				children: ["Send Enquiry ", /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Send, { "aria-hidden": "true" })]
			})
		]
	});
}
function MeetingForm() {
	const [meeting, setMeeting] = (0, import_react.useState)(null);
	const handleSubmit = (event) => {
		event.preventDefault();
		const formData = new FormData(event.currentTarget);
		const service = String(formData.get("service") || "Project discussion");
		const date = String(formData.get("date") || "Selected date");
		const time = String(formData.get("time") || "Selected time");
		setMeeting({
			service,
			date,
			time
		});
	};
	if (meeting) {
		const calendarUrl = `https://calendar.google.com/calendar/render?action=TEMPLATE&text=${encodeURIComponent(`G.K Tech - ${meeting.service}`)}&details=${encodeURIComponent("Project meeting with G.K Tech")}`;
		return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "rounded-lg border border-primary bg-primary/10 p-7",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "text-xs font-semibold uppercase tracking-[0.2em] text-accent",
					children: "Meeting Confirmed"
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
					className: "mt-4 font-display text-3xl font-semibold text-foreground",
					children: meeting.service
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("dl", {
					className: "mt-5 grid gap-3 text-sm text-muted-foreground",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex justify-between gap-4",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("dt", { children: "Date:" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("dd", {
							className: "text-foreground",
							children: meeting.date
						})]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex justify-between gap-4",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("dt", { children: "Time:" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("dd", {
							className: "text-foreground",
							children: meeting.time
						})]
					})]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "mt-6 flex flex-wrap gap-3",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
						asChild: true,
						className: "rounded-full bg-primary text-primary-foreground",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("a", {
							href: company.googleMeetUrl,
							target: "_blank",
							rel: "noreferrer",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Video, { "aria-hidden": "true" }), " Join Meeting"]
						})
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
						asChild: true,
						variant: "secondary",
						className: "rounded-full",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("a", {
							href: calendarUrl,
							target: "_blank",
							rel: "noreferrer",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(CalendarPlus, { "aria-hidden": "true" }), " Add to Google Calendar"]
						})
					})]
				})
			]
		});
	}
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("form", {
		onSubmit: handleSubmit,
		className: "grid gap-4",
		"aria-label": "Book a meeting form",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("select", {
				required: true,
				name: "service",
				"aria-label": "Select service",
				className: "h-11 rounded-md border border-input bg-background px-3 text-sm text-foreground focus:outline-none focus:ring-1 focus:ring-ring",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("option", {
					value: "",
					children: "Select service"
				}), serviceOptions.map((service) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("option", {
					value: service,
					children: service
				}, service))]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "grid gap-4 sm:grid-cols-2",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
					required: true,
					type: "date",
					name: "date",
					"aria-label": "Preferred date"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
					required: true,
					type: "time",
					name: "time",
					"aria-label": "Preferred time"
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "grid gap-4 sm:grid-cols-2",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
					required: true,
					name: "name",
					placeholder: "Name",
					"aria-label": "Name"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
					required: true,
					type: "email",
					name: "email",
					placeholder: "Email",
					"aria-label": "Email"
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
				required: true,
				type: "tel",
				name: "phone",
				placeholder: "Phone",
				"aria-label": "Phone"
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Textarea, {
				name: "message",
				placeholder: "Message",
				"aria-label": "Message"
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Button, {
				type: "submit",
				className: "h-12 rounded-full bg-primary text-primary-foreground",
				children: ["Book a Meeting ", /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CalendarPlus, { "aria-hidden": "true" })]
			})
		]
	});
}
function ProcessStep({ step, active }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("article", {
		className: active ? "min-w-[18rem] rounded-lg border border-primary bg-primary p-6 text-primary-foreground transition-all duration-500 sm:min-w-[25rem]" : "min-w-[16rem] rounded-lg border border-border bg-card p-6 transition-all duration-500 sm:min-w-[20rem]",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
				className: active ? "font-display text-sm text-primary-foreground/70" : "font-display text-sm text-accent",
				children: step.number
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
				className: "mt-8 font-display text-3xl font-semibold",
				children: step.title
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
				className: active ? "mt-4 leading-7 text-primary-foreground/80" : "mt-4 leading-7 text-muted-foreground",
				children: step.description
			})
		]
	});
}
function ProductVisual() {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "relative aspect-[4/3] overflow-hidden rounded-lg border border-border bg-surface-strong p-5",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
			className: "absolute inset-0 bg-product-sheen",
			"aria-hidden": "true"
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "relative mx-auto flex h-full max-w-xs flex-col justify-between rounded-[2rem] border border-border bg-background/70 p-4 shadow-cinematic backdrop-blur-xl",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex items-center justify-between",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
						className: "text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground",
						children: "Moi Kanakku"
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(WalletCards, {
						className: "text-accent",
						"aria-hidden": "true"
					})]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "space-y-3",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "rounded-lg bg-secondary p-4",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "text-xs text-muted-foreground",
							children: "Wedding function"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "mt-2 font-display text-3xl font-semibold text-foreground",
							children: "₹84,500"
						})]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "grid grid-cols-2 gap-3",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "rounded-md border border-border bg-background/60 p-3",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(UsersRound, {
								className: "mb-3 text-primary",
								"aria-hidden": "true"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-xs text-muted-foreground",
								children: "126 entries"
							})]
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "rounded-md border border-border bg-background/60 p-3",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Smartphone, {
								className: "mb-3 text-accent",
								"aria-hidden": "true"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-xs text-muted-foreground",
								children: "Mobile ready"
							})]
						})]
					})]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "h-1.5 rounded-full bg-primary" })
			]
		})]
	});
}
function ProductCard({ product }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("article", {
		className: "group grid overflow-hidden rounded-lg border border-border bg-card lg:grid-cols-[1.05fr_0.95fr]",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "p-6 sm:p-8 lg:p-10",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "mb-8 flex flex-wrap items-center gap-3 text-xs uppercase tracking-[0.18em] text-muted-foreground",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: product.category }),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { className: "h-px w-8 bg-border" }),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: product.status })
					]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
					className: "font-display text-4xl font-semibold text-card-foreground sm:text-6xl",
					children: product.name
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "mt-5 max-w-xl text-base leading-8 text-muted-foreground",
					children: product.description
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "mt-8 flex flex-wrap gap-2",
					children: product.technologies.map((technology) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
						className: "rounded-full bg-secondary px-3 py-1 text-xs text-secondary-foreground",
						children: technology
					}, technology))
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Link, {
					to: "/products/$slug",
					params: { slug: product.slug },
					className: "mt-10 inline-flex items-center gap-2 text-sm font-semibold text-primary transition-colors hover:text-accent",
					children: [
						"Explore ",
						product.name,
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ArrowUpRight, {
							"aria-hidden": "true",
							className: "size-4 transition-transform group-hover:-translate-y-0.5 group-hover:translate-x-0.5"
						})
					]
				})
			]
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ProductVisual, {})]
	});
}
function ProjectCard({ project, featured = false }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("article", {
		className: "group overflow-hidden rounded-lg border border-border bg-card transition-transform duration-500 hover:-translate-y-1",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "relative aspect-[16/10] overflow-hidden bg-surface-strong",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "absolute inset-0 bg-project-grid",
				"aria-hidden": "true"
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "absolute inset-x-6 bottom-6 flex items-end justify-between gap-4",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "text-xs uppercase tracking-[0.2em] text-muted-foreground",
					children: project.category
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
					className: "mt-2 font-display text-3xl font-semibold text-foreground",
					children: project.title
				})] }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ArrowUpRight, {
					"aria-hidden": "true",
					className: "text-accent transition-transform group-hover:-translate-y-1 group-hover:translate-x-1"
				})]
			})]
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: featured ? "p-7 sm:p-8" : "p-6",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "leading-7 text-muted-foreground",
					children: project.description
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "mt-6 flex flex-wrap gap-2",
					children: project.technologies.map((technology) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
						className: "rounded-full border border-border px-3 py-1 text-xs text-muted-foreground",
						children: technology
					}, technology))
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "mt-6 flex justify-between border-t border-border pt-4 text-xs uppercase tracking-[0.18em] text-muted-foreground",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: project.client }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: project.year })]
				})
			]
		})]
	});
}
function ServiceCard({ service }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("article", {
		className: "group grid gap-6 border-t border-border py-10 transition-colors hover:border-primary lg:grid-cols-[0.8fr_1.6fr_1fr] lg:items-center",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-start gap-5",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
					className: "font-display text-sm text-accent",
					children: service.index
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
					className: "whitespace-pre-line font-display text-4xl font-semibold leading-none text-foreground sm:text-6xl lg:text-7xl",
					children: service.title
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
				className: "max-w-xl text-base leading-8 text-muted-foreground lg:text-lg",
				children: service.description
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "space-y-5 lg:justify-self-end",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "flex flex-wrap gap-2",
					children: service.technologies.map((technology) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
						className: "rounded-full border border-border bg-secondary px-3 py-1 text-xs text-muted-foreground",
						children: technology
					}, technology))
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("a", {
					href: getWhatsAppUrl(whatsappMessages[service.whatsappKey]),
					target: "_blank",
					rel: "noreferrer",
					className: "inline-flex items-center gap-2 text-sm font-semibold text-primary transition-colors hover:text-accent",
					children: [service.cta, /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ArrowUpRight, {
						"aria-hidden": "true",
						className: "size-4 transition-transform group-hover:-translate-y-0.5 group-hover:translate-x-0.5"
					})]
				})]
			})
		]
	});
}
function TechnologyCard({ name, group, icon }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("article", {
		className: "group relative overflow-hidden rounded-lg border border-border bg-card p-5 transition-transform duration-500 hover:-translate-y-1",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
			className: "absolute inset-0 bg-tech-shine opacity-0 transition-opacity duration-500 group-hover:opacity-100",
			"aria-hidden": "true"
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "relative flex items-center justify-between gap-4",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
				className: "font-display text-xl font-semibold text-card-foreground",
				children: name
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
				className: "mt-2 text-xs uppercase tracking-[0.18em] text-muted-foreground",
				children: group
			})] }), icon]
		})]
	});
}
function TestimonialCard({ testimonial }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("article", {
		className: "min-w-[20rem] rounded-lg border border-border bg-card p-6 sm:min-w-[28rem]",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center justify-between gap-4",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex items-center gap-4",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "flex size-12 items-center justify-center rounded-full bg-secondary font-display text-sm font-semibold text-secondary-foreground",
						children: testimonial.photoInitials
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
						className: "font-semibold text-card-foreground",
						children: testimonial.name
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
						className: "text-sm text-muted-foreground",
						children: [
							testimonial.designation,
							", ",
							testimonial.company
						]
					})] })]
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "flex",
					"aria-label": `${testimonial.rating} star rating`,
					children: Array.from({ length: testimonial.rating }).map((_, index) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Star, {
						className: "size-4 fill-accent text-accent",
						"aria-hidden": "true"
					}, index))
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
				className: "mt-8 text-lg leading-8 text-foreground",
				children: [
					"“",
					testimonial.review,
					"”"
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
				className: "mt-6 text-xs uppercase tracking-[0.18em] text-muted-foreground",
				children: testimonial.project
			})
		]
	});
}
var faqs = [
	{
		question: "What services does G.K Tech provide?",
		answer: "G.K Tech provides web development, mobile apps, custom software, UI/UX design, backend APIs, AI solutions, automation, cloud, database and support services."
	},
	{
		question: "Do you build mobile applications?",
		answer: "Yes. G.K Tech builds mobile applications for business, operations and digital products."
	},
	{
		question: "Do you build custom software?",
		answer: "Yes. We create custom software for workflows, reporting, operations, internal tools and product platforms."
	},
	{
		question: "Do you provide AI solutions?",
		answer: "Yes. We build AI assistants, AI automation flows and practical AI tools for business use cases."
	},
	{
		question: "How long does a project take?",
		answer: "Timeline depends on scope. A focused website can be planned quickly, while apps and software products require deeper discovery, design, build and testing phases."
	},
	{
		question: "Can you maintain an existing application?",
		answer: "Yes. G.K Tech can improve, maintain and support existing websites, apps and software systems."
	},
	{
		question: "Can I book a meeting?",
		answer: "Yes. Use the Book Meeting form or WhatsApp action to start a conversation with G.K Tech."
	},
	{
		question: "How can I contact G.K Tech?",
		answer: "You can call, email, send WhatsApp, submit the enquiry form or book a meeting through the website."
	},
	{
		question: "What is Moi Kanakku?",
		answer: "Moi Kanakku is a G.K Tech product for recording and managing money given and received during family functions."
	}
];
var processSteps = [
	{
		id: "discover",
		number: "01",
		title: "Discover",
		description: "Understand goals, users, workflows and success measures."
	},
	{
		id: "plan",
		number: "02",
		title: "Plan",
		description: "Define scope, architecture, delivery stages and priorities."
	},
	{
		id: "design",
		number: "03",
		title: "Design",
		description: "Shape the experience with clean flows and reusable systems."
	},
	{
		id: "build",
		number: "04",
		title: "Build",
		description: "Engineer reliable frontend, backend and integration layers."
	},
	{
		id: "test",
		number: "05",
		title: "Test",
		description: "Validate performance, usability, data flows and edge cases."
	},
	{
		id: "launch",
		number: "06",
		title: "Launch",
		description: "Release with care, monitoring and production readiness."
	},
	{
		id: "support",
		number: "07",
		title: "Support",
		description: "Improve, maintain and extend the product after launch."
	}
];
var projectFilters = [
	"All",
	"Web",
	"Mobile",
	"Software",
	"AI",
	"Business"
];
var projects = [
	{
		id: "retail-operations",
		title: "Retail Operations Portal",
		category: "Software",
		description: "A custom workflow system for inventory, approvals, reporting and day-to-day branch visibility.",
		technologies: [
			"React",
			"Node.js",
			"MySQL",
			"REST APIs"
		],
		client: "Regional Retail Business",
		year: "2026"
	},
	{
		id: "field-service-app",
		title: "Field Service Mobile App",
		category: "Mobile",
		description: "A mobile-first service app for task assignment, status tracking and customer updates.",
		technologies: [
			"Flutter",
			"API",
			"Cloud",
			"Maps"
		],
		client: "Service Operations Team",
		year: "2026"
	},
	{
		id: "ai-lead-assistant",
		title: "AI Lead Assistant",
		category: "AI",
		description: "An assistant flow that qualifies enquiries, answers service questions and routes leads faster.",
		technologies: [
			"AI",
			"Automation",
			"CRM",
			"Analytics"
		],
		client: "Growth Team",
		year: "2025"
	},
	{
		id: "brand-web-platform",
		title: "Brand Web Platform",
		category: "Web",
		description: "A fast, editorial web experience with product pages, enquiry forms and conversion analytics.",
		technologies: [
			"React",
			"SEO",
			"CMS-ready",
			"Performance"
		],
		client: "Product Company",
		year: "2025"
	},
	{
		id: "business-automation",
		title: "Business Automation Suite",
		category: "Business",
		description: "Integrated forms, approvals, notifications and reports for a growing operations team.",
		technologies: [
			"Workflows",
			"Database",
			"Dashboards",
			"APIs"
		],
		client: "Local Enterprise",
		year: "2025"
	}
];
var technologies = [
	{
		name: "Flutter",
		group: "Mobile"
	},
	{
		name: "React",
		group: "Frontend"
	},
	{
		name: "Next.js",
		group: "Web"
	},
	{
		name: "Angular",
		group: "Frontend"
	},
	{
		name: "Node.js",
		group: "Backend"
	},
	{
		name: "TypeScript",
		group: "Language"
	},
	{
		name: "JavaScript",
		group: "Language"
	},
	{
		name: "MySQL",
		group: "Database"
	},
	{
		name: "REST APIs",
		group: "Integration"
	},
	{
		name: "AI",
		group: "Intelligence"
	},
	{
		name: "Cloud",
		group: "Infrastructure"
	}
];
var testimonials = [
	{
		id: "anand",
		name: "Anand R.",
		company: "Retail Operations",
		designation: "Managing Partner",
		rating: 5,
		review: "G.K Tech understood our business process quickly and delivered software that our team could actually use every day.",
		project: "Operations Portal",
		photoInitials: "AR"
	},
	{
		id: "priya",
		name: "Priya S.",
		company: "Service Company",
		designation: "Operations Lead",
		rating: 5,
		review: "The mobile app made field coordination much easier. The experience was professional from planning to launch.",
		project: "Field Service App",
		photoInitials: "PS"
	},
	{
		id: "karthik",
		name: "Karthik M.",
		company: "Digital Product Team",
		designation: "Founder",
		rating: 5,
		review: "They balanced design quality with practical engineering. We got a polished product foundation and clear support.",
		project: "Product Platform",
		photoInitials: "KM"
	}
];
function Index() {
	const [activeFilter, setActiveFilter] = (0, import_react.useState)("All");
	const filteredProjects = activeFilter === "All" ? projects : projects.filter((project) => project.category === activeFilter);
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(SiteShell, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("main", { children: [
		/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
			className: "relative isolate overflow-hidden border-b border-border pt-32 sm:pt-40",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "absolute inset-0 -z-10 bg-hero-grid",
				"aria-hidden": "true"
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(PageContainer, {
				className: "grid min-h-[calc(100vh-5rem)] items-center gap-12 pb-20 lg:grid-cols-[1.05fr_0.95fr] lg:pb-28",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					"data-reveal": true,
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "mb-6 text-xs font-semibold uppercase tracking-[0.28em] text-accent",
							children: "G.K Tech presents"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
							className: "max-w-4xl font-display text-5xl font-semibold leading-[0.98] tracking-tight text-foreground sm:text-7xl lg:text-8xl",
							children: "We build digital products that move businesses forward."
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
							className: "mt-7 max-w-xl text-lg leading-8 text-muted-foreground sm:text-xl",
							children: [company.subline, " Practical technology, carefully designed for the way people actually work."]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "mt-9 flex flex-wrap gap-3",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("a", {
								href: "#contact",
								className: "inline-flex h-12 items-center gap-2 rounded-full bg-primary px-6 text-sm font-semibold text-primary-foreground transition-transform hover:-translate-y-0.5",
								children: ["Start a Project ", /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ArrowUpRight, {
									className: "size-4",
									"aria-hidden": "true"
								})]
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("a", {
								href: "#work",
								className: "inline-flex h-12 items-center gap-2 rounded-full border border-border px-6 text-sm font-semibold text-foreground transition-colors hover:bg-secondary",
								children: ["Explore Our Work ", /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ArrowDown, {
									className: "size-4",
									"aria-hidden": "true"
								})]
							})]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "mt-14 flex flex-wrap gap-x-8 gap-y-3 text-xs uppercase tracking-[0.18em] text-muted-foreground",
							children: [
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: "Web" }),
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: "Mobile" }),
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: "Software" }),
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: "AI" })
							]
						})
					]
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "relative mx-auto flex w-full max-w-lg items-center justify-center",
					"data-reveal": true,
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "absolute size-[70%] rounded-full bg-accent/10 blur-3xl",
						"aria-hidden": "true"
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "relative aspect-square w-[76%] rounded-[2.5rem] border border-border bg-card/75 p-8 shadow-cinematic backdrop-blur-xl sm:p-12",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
							className: "absolute inset-5 rounded-[2rem] border border-accent/30",
							"aria-hidden": "true"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "relative flex h-full flex-col items-center justify-center gap-7 text-center",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(AppLogo, {
								variant: "icon",
								className: "size-36 object-contain motion-safe:animate-float sm:size-48",
								priority: true
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "font-display text-2xl font-semibold text-foreground",
								children: "Ideas into useful software."
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "mt-2 text-sm leading-6 text-muted-foreground",
								children: "From first conversation to reliable launch."
							})] })]
						})]
					})]
				})]
			})]
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			id: "services",
			eyebrow: "What we do",
			title: "Technology with a job to do.",
			description: "We combine product thinking, dependable engineering and human-friendly design to make ambitious ideas usable.",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { children: services.map((service) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ServiceCard, { service }, service.id)) })
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			id: "products",
			className: "bg-surface",
			eyebrow: "Our products",
			title: "Technology products built around real life.",
			description: "G.K Tech develops its own products alongside client work. Moi Kanakku is our first product for keeping family-function money records clear.",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "grid gap-6",
				children: products.map((product) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ProductCard, { product }, product.id))
			})
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Section, {
			id: "work",
			eyebrow: "Selected work",
			title: "Built for the details that matter.",
			description: "A few representative directions across web, mobile, software, AI and business automation.",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "mb-8 flex flex-wrap gap-2",
				role: "group",
				"aria-label": "Filter selected work",
				children: projectFilters.map((filter) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
					type: "button",
					onClick: () => setActiveFilter(filter),
					className: `rounded-full border px-4 py-2 text-sm transition-colors ${activeFilter === filter ? "border-primary bg-primary text-primary-foreground" : "border-border text-muted-foreground hover:bg-secondary hover:text-foreground"}`,
					children: filter
				}, filter))
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "grid gap-5 md:grid-cols-2",
				children: filteredProjects.map((project, index) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ProjectCard, {
					project,
					featured: index === 0
				}, project.id))
			})]
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			eyebrow: "Technology ecosystem",
			title: "The right tools for the right problem.",
			description: "A flexible stack lets us choose clarity, speed and maintainability over fashion.",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4",
				children: technologies.map((technology) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TechnologyCard, { ...technology }, technology.name))
			})
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			eyebrow: "How we build",
			title: "A calm process for complex work.",
			description: "Clear steps keep decisions visible and progress measurable from discovery to support.",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "grid gap-3 md:grid-cols-2 lg:grid-cols-4",
				children: processSteps.map((step, index) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ProcessStep, {
					step,
					active: index === 0
				}, step.id))
			})
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)("section", {
			id: "about",
			className: "border-y border-border bg-primary py-20 text-primary-foreground sm:py-28",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(PageContainer, {
				className: "grid gap-10 lg:grid-cols-[0.8fr_1.2fr] lg:items-end",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "text-xs font-semibold uppercase tracking-[0.24em] text-accent",
					children: "About G.K Tech"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
					className: "max-w-4xl font-display text-4xl font-semibold leading-tight sm:text-6xl",
					children: "Technology should solve problems, not create them."
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "mt-7 max-w-2xl text-base leading-8 text-primary-foreground/70 sm:text-lg",
					children: "We build business applications, mobile apps, websites, software products, AI solutions and digital experiences with care for both the system and the people using it."
				})] })]
			})
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			id: "testimonials",
			eyebrow: "Client perspective",
			title: "What our clients say.",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "grid gap-5 lg:grid-cols-3",
				children: testimonials.map((testimonial) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TestimonialCard, { testimonial }, testimonial.id))
			})
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			eyebrow: "Common questions",
			title: "A little clarity before we start.",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "mx-auto max-w-4xl divide-y divide-border border-y border-border",
				children: faqs.map((faq) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("details", {
					className: "group py-5",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("summary", {
						className: "flex cursor-pointer list-none items-center justify-between gap-6 font-display text-xl font-semibold text-foreground",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: faq.question }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "text-accent transition-transform group-open:rotate-45",
							children: "+"
						})]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "max-w-3xl pt-4 leading-7 text-muted-foreground",
						children: faq.answer
					})]
				}, faq.question))
			})
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)("section", {
			id: "contact",
			className: "bg-surface py-20 sm:py-28",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(PageContainer, {
				className: "grid gap-14 lg:grid-cols-[0.8fr_1.2fr]",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-xs font-semibold uppercase tracking-[0.24em] text-accent",
						children: "Start a conversation"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
						className: "mt-4 font-display text-5xl font-semibold leading-tight text-foreground sm:text-7xl",
						children: "Have an idea? Let's build it."
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "mt-6 max-w-md leading-7 text-muted-foreground",
						children: "Tell us what you are trying to make, improve or automate. We will help shape the next practical step."
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "mt-8 space-y-3 text-sm text-muted-foreground",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
								className: "block hover:text-foreground",
								href: `mailto:${company.email}`,
								children: company.email
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
								className: "block hover:text-foreground",
								href: `tel:${company.phone.replace(/\s/g, "")}`,
								children: company.phone
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { children: company.shortAddress })
						]
					})
				] }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "grid gap-8",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "rounded-lg border border-border bg-background p-6 sm:p-8",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
								className: "font-display text-2xl font-semibold text-foreground",
								children: "Send an enquiry"
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "mt-2 mb-6 text-sm text-muted-foreground",
								children: "A few details are enough to begin."
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ContactForm, {})
						]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						id: "meeting",
						className: "rounded-lg border border-border bg-background p-6 sm:p-8",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
								className: "font-display text-2xl font-semibold text-foreground",
								children: "Book a meeting"
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "mt-2 mb-6 text-sm text-muted-foreground",
								children: "Choose a convenient time for a first conversation."
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)(MeetingForm, {})
						]
					})]
				})]
			})
		})
	] }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(FloatingActions, {})] });
}
//#endregion
export { Index as component };
