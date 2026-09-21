export type Testimonial = {
  id: string;
  name: string;
  company: string;
  designation: string;
  rating: number;
  review: string;
  project: string;
  photoInitials: string;
};

export const testimonials: Testimonial[] = [
  {
    id: "anand",
    name: "Anand R.",
    company: "Retail Operations",
    designation: "Managing Partner",
    rating: 5,
    review:
      "G.K Tech understood our business process quickly and delivered software that our team could actually use every day.",
    project: "Operations Portal",
    photoInitials: "AR",
  },
  {
    id: "priya",
    name: "Priya S.",
    company: "Service Company",
    designation: "Operations Lead",
    rating: 5,
    review:
      "The mobile app made field coordination much easier. The experience was professional from planning to launch.",
    project: "Field Service App",
    photoInitials: "PS",
  },
  {
    id: "karthik",
    name: "Karthik M.",
    company: "Digital Product Team",
    designation: "Founder",
    rating: 5,
    review:
      "They balanced design quality with practical engineering. We got a polished product foundation and clear support.",
    project: "Product Platform",
    photoInitials: "KM",
  },
];
