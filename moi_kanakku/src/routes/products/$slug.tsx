import { Link, createFileRoute } from "@tanstack/react-router";
import { ArrowLeft, ArrowUpRight, Check } from "lucide-react";
import { AppLogo } from "@/components/branding/AppLogo";
import { FloatingActions } from "@/components/floating/FloatingActions";
import { Section } from "@/components/layout/Section";
import { SiteShell } from "@/components/layout/SiteShell";
import { getProductBySlug } from "@/data/products";

export const Route = createFileRoute("/products/$slug")({
  loader: ({ params }) => getProductBySlug(params.slug),
  head: ({ loaderData }) => ({
    meta: [
      { title: loaderData ? `${loaderData.name} | G.K Tech` : "Product | G.K Tech" },
      {
        name: "description",
        content: loaderData?.longDescription ?? "Explore products built by G.K Tech.",
      },
    ],
  }),
  component: ProductPage,
  notFoundComponent: () => (
    <div className="flex min-h-screen items-center justify-center bg-background px-6 text-center">
      <div>
        <p className="text-sm uppercase tracking-[0.2em] text-accent">Product not found</p>
        <h1 className="mt-4 font-display text-5xl font-semibold text-foreground">
          That product is not available.
        </h1>
        <Link
          to="/"
          className="mt-8 inline-flex items-center gap-2 rounded-full bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground"
        >
          Back home <ArrowLeft className="size-4" />
        </Link>
      </div>
    </div>
  ),
});

function ProductPage() {
  const product = Route.useLoaderData();

  if (!product) return null;

  return (
    <SiteShell>
      <main>
        <section className="relative overflow-hidden border-b border-border pt-36 pb-20 sm:pt-44 sm:pb-28">
          <div className="absolute inset-0 -z-10 bg-hero-grid" aria-hidden="true" />
          <div className="mx-auto grid max-w-7xl gap-12 px-5 sm:px-6 lg:grid-cols-[1fr_0.8fr] lg:items-center lg:px-8">
            <div>
              <Link
                to="/"
                className="inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground"
              >
                <ArrowLeft className="size-4" /> Back to G.K Tech
              </Link>
              <p className="mt-12 text-xs font-semibold uppercase tracking-[0.24em] text-accent">
                {product.category} / {product.status}
              </p>
              <h1 className="mt-5 font-display text-6xl font-semibold leading-none text-foreground sm:text-8xl">
                {product.name}
              </h1>
              <p className="mt-7 max-w-2xl text-lg leading-8 text-muted-foreground">
                {product.longDescription}
              </p>
              <div className="mt-9 flex flex-wrap gap-3">
                <a
                  href="#contact"
                  className="inline-flex h-12 items-center gap-2 rounded-full bg-primary px-6 text-sm font-semibold text-primary-foreground"
                >
                  Talk about the product <ArrowUpRight className="size-4" />
                </a>
                <a
                  href="https://wa.me/919597883290?text=Hi%20G.K%20Tech%2C%20I%20would%20like%20to%20know%20more%20about%20Moi%20Kanakku."
                  target="_blank"
                  rel="noreferrer"
                  className="inline-flex h-12 items-center rounded-full border border-border px-6 text-sm font-semibold text-foreground"
                >
                  WhatsApp G.K Tech
                </a>
              </div>
            </div>
            <div className="flex aspect-square items-center justify-center rounded-[2.5rem] border border-border bg-card p-10 shadow-cinematic">
              <AppLogo
                variant="icon"
                className="size-64 max-w-full object-contain motion-safe:animate-float"
                priority
              />
            </div>
          </div>
        </section>

        <Section
          eyebrow="What it helps with"
          title="A clearer record for important occasions."
          description="Moi Kanakku is designed for the moments where remembering who gave what, when and why matters."
        >
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {product.features.map((feature) => (
              <div
                key={feature}
                className="flex gap-3 border-t border-border pt-5 text-base text-muted-foreground"
              >
                <Check className="mt-0.5 size-5 shrink-0 text-accent" />
                {feature}
              </div>
            ))}
          </div>
        </Section>

        <section id="contact" className="border-t border-border bg-surface py-20 sm:py-28">
          <div className="mx-auto max-w-7xl px-5 sm:px-6 lg:px-8">
            <div className="max-w-2xl">
              <p className="text-xs font-semibold uppercase tracking-[0.24em] text-accent">
                Built by G.K Tech
              </p>
              <h2 className="mt-4 font-display text-5xl font-semibold text-foreground sm:text-7xl">
                Useful software starts with a real problem.
              </h2>
              <p className="mt-6 leading-8 text-muted-foreground">
                Want to learn more about Moi Kanakku or discuss a product of your own? Start a
                conversation with the team.
              </p>
              <a
                href="mailto:jkirena@gmail.com"
                className="mt-8 inline-flex items-center gap-2 rounded-full bg-primary px-6 py-3 text-sm font-semibold text-primary-foreground"
              >
                Contact G.K Tech <ArrowUpRight className="size-4" />
              </a>
            </div>
          </div>
        </section>
      </main>
      <FloatingActions />
    </SiteShell>
  );
}
