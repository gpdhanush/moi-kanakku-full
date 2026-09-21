import { createFileRoute } from "@tanstack/react-router";
import { ArrowDown, ArrowUpRight } from "lucide-react";
import { useState } from "react";
import { AppLogo } from "@/components/branding/AppLogo";
import { ContactForm } from "@/components/forms/ContactForm";
import { MeetingForm } from "@/components/forms/MeetingForm";
import { FloatingActions } from "@/components/floating/FloatingActions";
import { PageContainer } from "@/components/layout/PageContainer";
import { Section } from "@/components/layout/Section";
import { SiteShell } from "@/components/layout/SiteShell";
import { ProcessStep } from "@/components/cards/ProcessStep";
import { ProductCard } from "@/components/cards/ProductCard";
import { ProjectCard } from "@/components/cards/ProjectCard";
import { ServiceCard } from "@/components/cards/ServiceCard";
import { TechnologyCard } from "@/components/cards/TechnologyCard";
import { TestimonialCard } from "@/components/cards/TestimonialCard";
import { company } from "@/data/company";
import { faqs } from "@/data/faq";
import { processSteps } from "@/data/process";
import { products } from "@/data/products";
import { projectFilters, projects, type ProjectCategory } from "@/data/projects";
import { services } from "@/data/services";
import { technologies } from "@/data/technologies";
import { testimonials } from "@/data/testimonials";

export const Route = createFileRoute("/")({
  component: Index,
});

function Index() {
  const [activeFilter, setActiveFilter] = useState<"All" | ProjectCategory>("All");
  const filteredProjects =
    activeFilter === "All"
      ? projects
      : projects.filter((project) => project.category === activeFilter);

  return (
    <SiteShell>
      <main>
        <section className="relative isolate overflow-hidden border-b border-border pt-32 sm:pt-40">
          <div className="absolute inset-0 -z-10 bg-hero-grid" aria-hidden="true" />
          <PageContainer className="grid min-h-[calc(100vh-5rem)] items-center gap-12 pb-20 lg:grid-cols-[1.05fr_0.95fr] lg:pb-28">
            <div data-reveal>
              <p className="mb-6 text-xs font-semibold uppercase tracking-[0.28em] text-accent">
                G.K Tech presents
              </p>
              <h1 className="max-w-4xl font-display text-5xl font-semibold leading-[0.98] tracking-tight text-foreground sm:text-7xl lg:text-8xl">
                We build digital products that move businesses forward.
              </h1>
              <p className="mt-7 max-w-xl text-lg leading-8 text-muted-foreground sm:text-xl">
                {company.subline} Practical technology, carefully designed for the way people
                actually work.
              </p>
              <div className="mt-9 flex flex-wrap gap-3">
                <a
                  href="#contact"
                  className="inline-flex h-12 items-center gap-2 rounded-full bg-primary px-6 text-sm font-semibold text-primary-foreground transition-transform hover:-translate-y-0.5"
                >
                  Start a Project <ArrowUpRight className="size-4" aria-hidden="true" />
                </a>
                <a
                  href="#work"
                  className="inline-flex h-12 items-center gap-2 rounded-full border border-border px-6 text-sm font-semibold text-foreground transition-colors hover:bg-secondary"
                >
                  Explore Our Work <ArrowDown className="size-4" aria-hidden="true" />
                </a>
              </div>
              <div className="mt-14 flex flex-wrap gap-x-8 gap-y-3 text-xs uppercase tracking-[0.18em] text-muted-foreground">
                <span>Web</span>
                <span>Mobile</span>
                <span>Software</span>
                <span>AI</span>
              </div>
            </div>
            <div
              className="relative mx-auto flex w-full max-w-lg items-center justify-center"
              data-reveal
            >
              <div
                className="absolute size-[70%] rounded-full bg-accent/10 blur-3xl"
                aria-hidden="true"
              />
              <div className="relative aspect-square w-[76%] rounded-[2.5rem] border border-border bg-card/75 p-8 shadow-cinematic backdrop-blur-xl sm:p-12">
                <div
                  className="absolute inset-5 rounded-[2rem] border border-accent/30"
                  aria-hidden="true"
                />
                <div className="relative flex h-full flex-col items-center justify-center gap-7 text-center">
                  <AppLogo
                    variant="icon"
                    className="size-36 object-contain motion-safe:animate-float sm:size-48"
                    priority
                  />
                  <div>
                    <p className="font-display text-2xl font-semibold text-foreground">
                      Ideas into useful software.
                    </p>
                    <p className="mt-2 text-sm leading-6 text-muted-foreground">
                      From first conversation to reliable launch.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </PageContainer>
        </section>

        <Section
          id="services"
          eyebrow="What we do"
          title="Technology with a job to do."
          description="We combine product thinking, dependable engineering and human-friendly design to make ambitious ideas usable."
        >
          <div>
            {services.map((service) => (
              <ServiceCard key={service.id} service={service} />
            ))}
          </div>
        </Section>

        <Section
          id="products"
          className="bg-surface"
          eyebrow="Our products"
          title="Technology products built around real life."
          description="G.K Tech develops its own products alongside client work. Moi Kanakku is our first product for keeping family-function money records clear."
        >
          <div className="grid gap-6">
            {products.map((product) => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>
        </Section>

        <Section
          id="work"
          eyebrow="Selected work"
          title="Built for the details that matter."
          description="A few representative directions across web, mobile, software, AI and business automation."
        >
          <div className="mb-8 flex flex-wrap gap-2" role="group" aria-label="Filter selected work">
            {projectFilters.map((filter) => (
              <button
                key={filter}
                type="button"
                onClick={() => setActiveFilter(filter)}
                className={`rounded-full border px-4 py-2 text-sm transition-colors ${activeFilter === filter ? "border-primary bg-primary text-primary-foreground" : "border-border text-muted-foreground hover:bg-secondary hover:text-foreground"}`}
              >
                {filter}
              </button>
            ))}
          </div>
          <div className="grid gap-5 md:grid-cols-2">
            {filteredProjects.map((project, index) => (
              <ProjectCard key={project.id} project={project} featured={index === 0} />
            ))}
          </div>
        </Section>

        <Section
          eyebrow="Technology ecosystem"
          title="The right tools for the right problem."
          description="A flexible stack lets us choose clarity, speed and maintainability over fashion."
        >
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
            {technologies.map((technology) => (
              <TechnologyCard key={technology.name} {...technology} />
            ))}
          </div>
        </Section>

        <Section
          eyebrow="How we build"
          title="A calm process for complex work."
          description="Clear steps keep decisions visible and progress measurable from discovery to support."
        >
          <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-4">
            {processSteps.map((step, index) => (
              <ProcessStep key={step.id} step={step} active={index === 0} />
            ))}
          </div>
        </Section>

        <section
          id="about"
          className="border-y border-border bg-primary py-20 text-primary-foreground sm:py-28"
        >
          <PageContainer className="grid gap-10 lg:grid-cols-[0.8fr_1.2fr] lg:items-end">
            <p className="text-xs font-semibold uppercase tracking-[0.24em] text-accent">
              About G.K Tech
            </p>
            <div>
              <h2 className="max-w-4xl font-display text-4xl font-semibold leading-tight sm:text-6xl">
                Technology should solve problems, not create them.
              </h2>
              <p className="mt-7 max-w-2xl text-base leading-8 text-primary-foreground/70 sm:text-lg">
                We build business applications, mobile apps, websites, software products, AI
                solutions and digital experiences with care for both the system and the people using
                it.
              </p>
            </div>
          </PageContainer>
        </section>

        <Section id="testimonials" eyebrow="Client perspective" title="What our clients say.">
          <div className="grid gap-5 lg:grid-cols-3">
            {testimonials.map((testimonial) => (
              <TestimonialCard key={testimonial.id} testimonial={testimonial} />
            ))}
          </div>
        </Section>

        <Section eyebrow="Common questions" title="A little clarity before we start.">
          <div className="mx-auto max-w-4xl divide-y divide-border border-y border-border">
            {faqs.map((faq) => (
              <details key={faq.question} className="group py-5">
                <summary className="flex cursor-pointer list-none items-center justify-between gap-6 font-display text-xl font-semibold text-foreground">
                  <span>{faq.question}</span>
                  <span className="text-accent transition-transform group-open:rotate-45">+</span>
                </summary>
                <p className="max-w-3xl pt-4 leading-7 text-muted-foreground">{faq.answer}</p>
              </details>
            ))}
          </div>
        </Section>

        <section id="contact" className="bg-surface py-20 sm:py-28">
          <PageContainer className="grid gap-14 lg:grid-cols-[0.8fr_1.2fr]">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.24em] text-accent">
                Start a conversation
              </p>
              <h2 className="mt-4 font-display text-5xl font-semibold leading-tight text-foreground sm:text-7xl">
                Have an idea? Let&apos;s build it.
              </h2>
              <p className="mt-6 max-w-md leading-7 text-muted-foreground">
                Tell us what you are trying to make, improve or automate. We will help shape the
                next practical step.
              </p>
              <div className="mt-8 space-y-3 text-sm text-muted-foreground">
                <a className="block hover:text-foreground" href={`mailto:${company.email}`}>
                  {company.email}
                </a>
                <a
                  className="block hover:text-foreground"
                  href={`tel:${company.phone.replace(/\s/g, "")}`}
                >
                  {company.phone}
                </a>
                <p>{company.shortAddress}</p>
              </div>
            </div>
            <div className="grid gap-8">
              <div className="rounded-lg border border-border bg-background p-6 sm:p-8">
                <h3 className="font-display text-2xl font-semibold text-foreground">
                  Send an enquiry
                </h3>
                <p className="mt-2 mb-6 text-sm text-muted-foreground">
                  A few details are enough to begin.
                </p>
                <ContactForm />
              </div>
              <div
                id="meeting"
                className="rounded-lg border border-border bg-background p-6 sm:p-8"
              >
                <h3 className="font-display text-2xl font-semibold text-foreground">
                  Book a meeting
                </h3>
                <p className="mt-2 mb-6 text-sm text-muted-foreground">
                  Choose a convenient time for a first conversation.
                </p>
                <MeetingForm />
              </div>
            </div>
          </PageContainer>
        </section>
      </main>
      <FloatingActions />
    </SiteShell>
  );
}
