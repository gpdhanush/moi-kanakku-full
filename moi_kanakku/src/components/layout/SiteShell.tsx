import type { ReactNode } from "react";
import { Footer } from "./Footer";
import { Navbar } from "@/components/navigation/Navbar";
import { useSmoothScroll } from "@/hooks/useSmoothScroll";

export function SiteShell({ children }: { children: ReactNode }) {
  useSmoothScroll();

  return (
    <div className="min-h-screen bg-background text-foreground selection:bg-primary selection:text-primary-foreground">
      <Navbar />
      {children}
      <Footer />
    </div>
  );
}
