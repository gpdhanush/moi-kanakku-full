import { X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { company, navigationItems, whatsappMessages } from "@/data/company";
import { getWhatsAppUrl } from "@/utils/whatsapp";
import { AppLogo } from "@/components/branding/AppLogo";

type MobileMenuProps = {
  open: boolean;
  onClose: () => void;
};

export function MobileMenu({ open, onClose }: MobileMenuProps) {
  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 bg-background/95 backdrop-blur-2xl lg:hidden"
      role="dialog"
      aria-modal="true"
      aria-label="Mobile navigation"
    >
      <div className="flex h-20 items-center justify-between px-5">
        <a href="/" onClick={onClose} aria-label={`${company.name} home`}>
          <AppLogo variant="wordmark" className="h-7 w-auto max-w-[9rem] object-contain" priority />
        </a>
        <Button type="button" variant="ghost" size="icon" onClick={onClose} aria-label="Close menu">
          <X aria-hidden="true" />
        </Button>
      </div>
      <nav className="grid px-5 pt-10">
        {navigationItems.map((item) => (
          <a
            key={item.label}
            href={item.href}
            onClick={onClose}
            className="border-t border-border py-6 font-display text-4xl font-semibold text-foreground"
          >
            {item.label}
          </a>
        ))}
      </nav>
      <div className="absolute inset-x-5 bottom-8 grid gap-3">
        <Button asChild className="h-12 rounded-full bg-primary text-primary-foreground">
          <a href="#contact" onClick={onClose}>
            Start a Project
          </a>
        </Button>
        <Button asChild variant="secondary" className="h-12 rounded-full">
          <a
            href={getWhatsAppUrl(whatsappMessages.general)}
            target="_blank"
            rel="noreferrer"
            onClick={onClose}
          >
            WhatsApp G.K Tech
          </a>
        </Button>
      </div>
    </div>
  );
}
