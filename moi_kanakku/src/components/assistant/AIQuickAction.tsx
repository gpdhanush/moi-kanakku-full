import { Button } from "@/components/ui/button";

export function AIQuickAction({ label, onSelect }: { label: string; onSelect: (label: string) => void }) {
  return (
    <Button type="button" variant="secondary" size="sm" className="rounded-full" onClick={() => onSelect(label)}>
      {label}
    </Button>
  );
}
