export type ProcessStep = {
  id: string;
  number: string;
  title: string;
  description: string;
};

export const processSteps: ProcessStep[] = [
  { id: "discover", number: "01", title: "Discover", description: "Understand goals, users, workflows and success measures." },
  { id: "plan", number: "02", title: "Plan", description: "Define scope, architecture, delivery stages and priorities." },
  { id: "design", number: "03", title: "Design", description: "Shape the experience with clean flows and reusable systems." },
  { id: "build", number: "04", title: "Build", description: "Engineer reliable frontend, backend and integration layers." },
  { id: "test", number: "05", title: "Test", description: "Validate performance, usability, data flows and edge cases." },
  { id: "launch", number: "06", title: "Launch", description: "Release with care, monitoring and production readiness." },
  { id: "support", number: "07", title: "Support", description: "Improve, maintain and extend the product after launch." },
];
