export type Service = {
  id: string;
  index: string;
  title: string;
  label: string;
  description: string;
  technologies: string[];
  cta: string;
  whatsappKey: "website" | "mobile" | "software" | "ai" | "general";
};

export const services: Service[] = [
  {
    id: "web-development",
    index: "01",
    title: "WEB\nEXPERIENCES",
    label: "Web Development",
    description:
      "Performance-led websites, portals, dashboards and commerce experiences designed for conversion and trust.",
    technologies: ["React", "Next.js", "TypeScript", "APIs"],
    cta: "Discuss a website",
    whatsappKey: "website",
  },
  {
    id: "mobile-apps",
    index: "02",
    title: "MOBILE\nAPPLICATIONS",
    label: "Mobile Application Development",
    description:
      "Cross-platform mobile apps with practical workflows, polished interfaces and reliable backend integration.",
    technologies: ["Flutter", "Android", "iOS", "Cloud"],
    cta: "Plan an app",
    whatsappKey: "mobile",
  },
  {
    id: "custom-software",
    index: "03",
    title: "CUSTOM\nSOFTWARE",
    label: "Custom Software Development",
    description:
      "Business software, internal tools, automations and product platforms built around real operational needs.",
    technologies: ["Node.js", "MySQL", "REST APIs", "Security"],
    cta: "Build software",
    whatsappKey: "software",
  },
  {
    id: "ai-automation",
    index: "04",
    title: "AI &\nAUTOMATION",
    label: "AI Solutions & Automation",
    description:
      "AI assistants, workflow automation and intelligent tools that reduce repetitive work and speed up decisions.",
    technologies: ["AI", "Automation", "Integrations", "Data"],
    cta: "Explore AI",
    whatsappKey: "ai",
  },
  {
    id: "ui-ux-design",
    index: "05",
    title: "UI / UX\nDESIGN",
    label: "UI/UX Design",
    description:
      "Human-friendly product design systems, prototypes and interfaces that make complex software feel simple.",
    technologies: ["UX Strategy", "Design Systems", "Prototypes", "Testing"],
    cta: "Design with us",
    whatsappKey: "general",
  },
];

export const serviceOptions = [
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
  "Digital Product Development",
];
