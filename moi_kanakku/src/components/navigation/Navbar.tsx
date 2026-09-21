import { useEffect, useState } from "react";
import { Menu } from "lucide-react";
import { Button } from "@/components/ui/button";
import { company, navigationItems } from "@/data/company";
import { MobileMenu } from "./MobileMenu";
import { AppLogo } from "@/components/branding/AppLogo";
import { ThemeToggle } from "@/components/theme/ThemeToggle";

export function Navbar() {
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 40);
    handleScroll();
    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <>
      <header
        className={
          scrolled
            ? "fixed inset-x-0 top-0 z-40 border-b border-border bg-background/78 backdrop-blur-2xl transition-all duration-500"
            : "fixed inset-x-0 top-0 z-40 bg-transparent transition-all duration-500"
        }
      >
        <div
          className={
            scrolled
              ? "mx-auto flex h-16 max-w-7xl items-center justify-between px-5 transition-all sm:px-6 lg:px-8"
              : "mx-auto flex h-20 max-w-7xl items-center justify-between px-5 transition-all sm:px-6 lg:px-8"
          }
        >
          <a href="/" aria-label={`${company.name} home`}>
            <AppLogo
              variant="wordmark"
              className="h-7 w-auto max-w-[9rem] object-contain"
              priority
            />
          </a>
          <nav className="hidden items-center gap-7 lg:flex" aria-label="Main navigation">
            {navigationItems.map((item) => (
              <a
                key={item.label}
                href={item.href}
                className="text-sm text-muted-foreground transition-colors hover:text-foreground"
              >
                {item.label}
              </a>
            ))}
          </nav>
          <div className="flex items-center gap-2">
            <ThemeToggle />
            <div className="hidden lg:block">
              <Button
                asChild
                className="h-10 rounded-full bg-primary px-5 text-primary-foreground hover:bg-primary/90"
              >
                <a href="#contact">Start a Project</a>
              </Button>
            </div>
          </div>
          <Button
            type="button"
            variant="ghost"
            size="icon"
            className="lg:hidden"
            onClick={() => setOpen(true)}
            aria-label="Open menu"
          >
            <Menu aria-hidden="true" />
          </Button>
        </div>
      </header>
      <MobileMenu open={open} onClose={() => setOpen(false)} />
    </>
  );
}
