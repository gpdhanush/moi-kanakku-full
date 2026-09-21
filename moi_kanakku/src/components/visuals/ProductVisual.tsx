import { Smartphone, WalletCards, UsersRound } from "lucide-react";

export function ProductVisual() {
  return (
    <div className="relative aspect-[4/3] overflow-hidden rounded-lg border border-border bg-surface-strong p-5">
      <div className="absolute inset-0 bg-product-sheen" aria-hidden="true" />
      <div className="relative mx-auto flex h-full max-w-xs flex-col justify-between rounded-[2rem] border border-border bg-background/70 p-4 shadow-cinematic backdrop-blur-xl">
        <div className="flex items-center justify-between">
          <span className="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground">Moi Kanakku</span>
          <WalletCards className="text-accent" aria-hidden="true" />
        </div>
        <div className="space-y-3">
          <div className="rounded-lg bg-secondary p-4">
            <p className="text-xs text-muted-foreground">Wedding function</p>
            <p className="mt-2 font-display text-3xl font-semibold text-foreground">₹84,500</p>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="rounded-md border border-border bg-background/60 p-3">
              <UsersRound className="mb-3 text-primary" aria-hidden="true" />
              <p className="text-xs text-muted-foreground">126 entries</p>
            </div>
            <div className="rounded-md border border-border bg-background/60 p-3">
              <Smartphone className="mb-3 text-accent" aria-hidden="true" />
              <p className="text-xs text-muted-foreground">Mobile ready</p>
            </div>
          </div>
        </div>
        <div className="h-1.5 rounded-full bg-primary" />
      </div>
    </div>
  );
}
