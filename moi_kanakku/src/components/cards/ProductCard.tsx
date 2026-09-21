import { Link } from "@tanstack/react-router";
import { ArrowUpRight } from "lucide-react";
import type { Product } from "@/data/products";
import { ProductVisual } from "@/components/visuals/ProductVisual";

export function ProductCard({ product }: { product: Product }) {
  return (
    <article className="group grid overflow-hidden rounded-lg border border-border bg-card lg:grid-cols-[1.05fr_0.95fr]">
      <div className="p-6 sm:p-8 lg:p-10">
        <div className="mb-8 flex flex-wrap items-center gap-3 text-xs uppercase tracking-[0.18em] text-muted-foreground">
          <span>{product.category}</span>
          <span className="h-px w-8 bg-border" />
          <span>{product.status}</span>
        </div>
        <h3 className="font-display text-4xl font-semibold text-card-foreground sm:text-6xl">{product.name}</h3>
        <p className="mt-5 max-w-xl text-base leading-8 text-muted-foreground">{product.description}</p>
        <div className="mt-8 flex flex-wrap gap-2">
          {product.technologies.map((technology) => (
            <span key={technology} className="rounded-full bg-secondary px-3 py-1 text-xs text-secondary-foreground">
              {technology}
            </span>
          ))}
        </div>
        <Link
          to="/products/$slug"
          params={{ slug: product.slug }}
          className="mt-10 inline-flex items-center gap-2 text-sm font-semibold text-primary transition-colors hover:text-accent"
        >
          Explore {product.name}
          <ArrowUpRight aria-hidden="true" className="size-4 transition-transform group-hover:-translate-y-0.5 group-hover:translate-x-0.5" />
        </Link>
      </div>
      <ProductVisual />
    </article>
  );
}
