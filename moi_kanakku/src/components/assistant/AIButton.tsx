import { Bot } from "lucide-react";
import { Button } from "@/components/ui/button";

export function AIButton({ onClick }: { onClick: () => void }) {
  return (
    <Button type="button" size="icon" className="size-12 rounded-full bg-primary text-primary-foreground shadow-cinematic" onClick={onClick} aria-label="Open G.K Tech AI assistant">
      <Bot aria-hidden="true" />
    </Button>
  );
}
