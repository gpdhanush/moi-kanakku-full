export type ProjectCategory = "Web" | "Mobile" | "Software" | "AI" | "Business";

export type Project = {
  id: string;
  title: string;
  category: ProjectCategory;
  description: string;
  technologies: string[];
  client: string;
  year: string;
  url?: string;
};

export const projectFilters: Array<"All" | ProjectCategory> = [
  "All",
  "Web",
  "Mobile",
  "Software",
  "AI",
  "Business",
];

export const projects: Project[] = [
  {
    id: "retail-operations",
    title: "Retail Operations Portal",
    category: "Software",
    description: "A custom workflow system for inventory, approvals, reporting and day-to-day branch visibility.",
    technologies: ["React", "Node.js", "MySQL", "REST APIs"],
    client: "Regional Retail Business",
    year: "2026",
  },
  {
    id: "field-service-app",
    title: "Field Service Mobile App",
    category: "Mobile",
    description: "A mobile-first service app for task assignment, status tracking and customer updates.",
    technologies: ["Flutter", "API", "Cloud", "Maps"],
    client: "Service Operations Team",
    year: "2026",
  },
  {
    id: "ai-lead-assistant",
    title: "AI Lead Assistant",
    category: "AI",
    description: "An assistant flow that qualifies enquiries, answers service questions and routes leads faster.",
    technologies: ["AI", "Automation", "CRM", "Analytics"],
    client: "Growth Team",
    year: "2025",
  },
  {
    id: "brand-web-platform",
    title: "Brand Web Platform",
    category: "Web",
    description: "A fast, editorial web experience with product pages, enquiry forms and conversion analytics.",
    technologies: ["React", "SEO", "CMS-ready", "Performance"],
    client: "Product Company",
    year: "2025",
  },
  {
    id: "business-automation",
    title: "Business Automation Suite",
    category: "Business",
    description: "Integrated forms, approvals, notifications and reports for a growing operations team.",
    technologies: ["Workflows", "Database", "Dashboards", "APIs"],
    client: "Local Enterprise",
    year: "2025",
  },
];
