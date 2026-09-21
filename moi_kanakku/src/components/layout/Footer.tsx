import { Mail, MapPin, Phone, MessageCircle } from "lucide-react";
import { company, navigationItems, whatsappMessages } from "@/data/company";
import { services } from "@/data/services";
import { products } from "@/data/products";
import { getWhatsAppUrl } from "@/utils/whatsapp";
import { PageContainer } from "./PageContainer";
import { AppLogo } from "@/components/branding/AppLogo";

export function Footer() {
  return (
    <footer className="border-t border-border bg-surface py-14">
      <PageContainer>
        <div className="grid gap-10 lg:grid-cols-[1.3fr_0.7fr_0.7fr_0.8fr]">
          <div>
            <a href="/" aria-label={`${company.name} home`}>
              <AppLogo variant="wordmark" className="h-8 w-auto max-w-[11rem] object-contain" />
            </a>
            <p className="mt-5 max-w-sm font-display text-3xl font-semibold leading-tight text-foreground">
              We build digital products that move businesses forward.
            </p>
          </div>
          <div>
            <h2 className="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground">
              Services
            </h2>
            <ul className="mt-5 space-y-3 text-sm text-muted-foreground">
              {services.slice(0, 5).map((service) => (
                <li key={service.id}>
                  <a href={`/#services`} className="hover:text-foreground">
                    {service.label}
                  </a>
                </li>
              ))}
            </ul>
          </div>
          <div>
            <h2 className="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground">
              Explore
            </h2>
            <ul className="mt-5 space-y-3 text-sm text-muted-foreground">
              {navigationItems.map((item) => (
                <li key={item.label}>
                  <a href={item.href} className="hover:text-foreground">
                    {item.label}
                  </a>
                </li>
              ))}
              {products.map((product) => (
                <li key={product.id}>
                  <a href={`/products/${product.slug}`} className="hover:text-foreground">
                    {product.name}
                  </a>
                </li>
              ))}
            </ul>
          </div>
          <address className="not-italic">
            <h2 className="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground">
              Contact
            </h2>
            <div className="mt-5 space-y-4 text-sm text-muted-foreground">
              <a
                className="flex items-center gap-3 hover:text-foreground"
                href={getWhatsAppUrl(whatsappMessages.general)}
                target="_blank"
                rel="noreferrer"
              >
                <MessageCircle className="size-4 text-accent" aria-hidden="true" /> WhatsApp
              </a>
              <a
                className="flex items-center gap-3 hover:text-foreground"
                href={`mailto:${company.email}`}
              >
                <Mail className="size-4 text-accent" aria-hidden="true" /> {company.email}
              </a>
              <a
                className="flex items-center gap-3 hover:text-foreground"
                href={`tel:${company.phone.replace(/\s/g, "")}`}
              >
                <Phone className="size-4 text-accent" aria-hidden="true" /> {company.phone}
              </a>
              <p className="flex items-start gap-3">
                <MapPin className="mt-0.5 size-4 text-accent" aria-hidden="true" /> Velachery,
                <br />
                Chennai - 600042
              </p>
            </div>
          </address>
        </div>
        <div className="mt-12 flex flex-col justify-between gap-3 border-t border-border pt-6 text-sm text-muted-foreground sm:flex-row">
          <p>© G.K Tech. All rights reserved.</p>
          <p>Premium digital products, software and AI solutions.</p>
        </div>
      </PageContainer>
    </footer>
  );
}
