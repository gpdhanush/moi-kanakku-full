import { cn } from "@/lib/utils";

type RevealTextProps = {
  text: string;
  className?: string;
};

export function RevealText({ text, className }: RevealTextProps) {
  return (
    <span className={cn("block overflow-hidden", className)}>
      <span data-reveal className="block motion-safe:opacity-0">
        {text}
      </span>
    </span>
  );
}
