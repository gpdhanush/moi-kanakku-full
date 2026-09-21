import { useState, type FormEvent } from "react";
import { Send } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

export function AIInput({ onSend }: { onSend: (message: string) => void }) {
  const [value, setValue] = useState("");

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const message = value.trim();
    if (!message) return;
    onSend(message);
    setValue("");
  };

  return (
    <form onSubmit={submit} className="flex gap-2">
      <Input value={value} onChange={(event) => setValue(event.target.value)} placeholder="Ask G.K Tech AI" aria-label="Ask G.K Tech AI" />
      <Button type="submit" size="icon" className="shrink-0" aria-label="Send message">
        <Send aria-hidden="true" />
      </Button>
    </form>
  );
}
