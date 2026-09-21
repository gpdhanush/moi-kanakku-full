export type Product = {
  id: string;
  slug: string;
  name: string;
  description: string;
  longDescription: string;
  category: string;
  status: "Live" | "In development" | "Concept";
  features: string[];
  technologies: string[];
  url?: string;
};

export const products: Product[] = [
  {
    id: "moi-kanakku",
    slug: "moi-kanakku",
    name: "Moi Kanakku",
    description:
      "A simple and powerful way to record, manage and track function gifts and money given or received.",
    longDescription:
      "Moi Kanakku helps families keep a clear personal record of money given and received during weddings, birthdays, housewarming ceremonies, festivals and other family functions. It is designed for quick entry, clean tracking and confident follow-up.",
    category: "Personal Finance / Family Functions",
    status: "In development",
    features: [
      "Record money given and received",
      "Organize entries by family function",
      "Track people, dates and amounts",
      "Review balances with simple summaries",
      "Designed for Tamil Nadu family occasions",
    ],
    technologies: ["Mobile App", "Secure Data", "Reports", "Family Workflows"],
  },
];

export function getProductBySlug(slug: string) {
  return products.find((product) => product.slug === slug);
}
