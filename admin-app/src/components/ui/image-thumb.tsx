import { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { cn } from "@/lib/utils";

interface ImageThumbProps {
  src?: string | null;
  alt?: string;
  className?: string;
  emptyLabel?: string;
}

export function ImageThumb({
  src,
  alt = "Image",
  className,
  emptyLabel = "—",
}: ImageThumbProps) {
  const [open, setOpen] = useState(false);
  const [failed, setFailed] = useState(false);

  if (!src || failed) {
    return (
      <span className="text-muted-foreground" title={failed ? src || undefined : undefined}>
        {failed ? "!" : emptyLabel}
      </span>
    );
  }

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className={cn(
          "block h-10 w-10 overflow-hidden rounded-md border border-border/60 bg-muted/30 transition hover:opacity-90",
          className
        )}
        title="View image"
        aria-label={`View ${alt}`}
      >
        <img
          src={src}
          alt={alt}
          className="h-full w-full object-cover"
          loading="lazy"
          referrerPolicy="no-referrer"
          onError={() => setFailed(true)}
        />
      </button>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className="max-h-[92vh] w-[95vw] max-w-3xl overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{alt}</DialogTitle>
          </DialogHeader>
          <div className="overflow-hidden rounded-xl border border-border/60 bg-muted/20">
            <img
              src={src}
              alt={alt}
              className="mx-auto max-h-[75vh] w-full object-contain"
              referrerPolicy="no-referrer"
              onError={() => setFailed(true)}
            />
          </div>
        </DialogContent>
      </Dialog>
    </>
  );
}
